from os import path, environ, walk
import subprocess
import requests
import sys
from tempfile import NamedTemporaryFile
import pyodbc
import logging
import backoff

import semihour

logging.basicConfig(level=logging.INFO)

CONDUCTOR_PWD = path.dirname(path.abspath(__file__))
SQL_SERVER_URL = environ.get('SQL_SERVER_URL', None)
SQL_SERVER_DATABASE = environ.get('SQL_SERVER_DATABASE', 'parking_prediction')
SQL_SERVER_USERNAME = environ.get('SQL_SERVER_USERNAME', 'padmin')
SQL_SERVER_PASSWORD = environ.get('SQL_SERVER_PASSWORD', None)
SQL_SERVER_DATA_LIMIT_MONTHS = int(environ.get('SQL_SERVER_DATA_LIMIT_MONTHS', "18"))
DISCOVERY_URL = environ.get('DISCOVERY_URL', 'https://data.smartcolumbusos.com/api/v1')
DISCOVERY_DATA_LIMIT = int(environ.get('DISCOVERY_DATA_LIMIT', False))

def _log_exception(details):
  print("Backing off {wait:0.1f} seconds afters {tries} tries "
          "calling function {target} with args {args} and kwargs "
          "{kwargs}".format(**details))
  print(f"Backing off due to exception {sys.exc_info()}")

def _bcp_shell_command(table, file_path, extra_arguments=[]):
    command_args = [
        'bcp',
        table, 'in', file_path,
        '-S', SQL_SERVER_URL,
        '-c',
        '-U', SQL_SERVER_USERNAME,
        '-d', SQL_SERVER_DATABASE,
        '-P', SQL_SERVER_PASSWORD
        ] + extra_arguments

    logging.debug(f"running bcp command: {' '.join(command_args)}")
    _process = subprocess.run(command_args)


def _bulk_copy_ref_file(table):
    logging.info(f"uploading ref file: {table}")
    _bcp_shell_command(table, f"{CONDUCTOR_PWD}/../ref_data/{table}.dat")


def _bulk_copy_csv_file(table, file_path):
    logging.info(f"uploading source data file: {table}")
    _bcp_shell_command(table, file_path, ['-F', '2', '-t', ','])
    return _get_record_count_for_table(table)


def _get_record_count_for_table(table):
    conn = pyodbc.connect(_conn_string(), autocommit=True)
    [(count, )] = _run_statement(conn, f"select count(1) from {table}").fetchall()

    return count

@backoff.on_exception(backoff.constant,
                    Exception,
                    on_backoff=_log_exception,
                    max_tries=5,
                    interval=60)
def _download_file(url):
    logging.debug(f"Downloading source data from: {url}")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with NamedTemporaryFile(delete=False) as f:
            for chunk in r.iter_content(chunk_size=8192): 
                f.write(chunk)
                f.flush()

    return f.name

@backoff.on_exception(backoff.constant,
                    Exception,
                    on_backoff=_log_exception,
                    max_tries=5,
                    interval=60)
def _query_dataset(url, query):
    logging.debug(f"Downloading source data from: {url} using ({query})")
    with requests.post(url, stream=True, data=query) as r:
        r.raise_for_status()
        with NamedTemporaryFile(delete=False) as f:
            for chunk in r.iter_content(chunk_size=8192): 
                f.write(chunk)
                f.flush()

    return f.name


def _get_record_count(organization, dataset):
    url = f"{DISCOVERY_URL}/organization/{organization}/dataset/{dataset}/query?columns=count(1)%20as%20count&_format=json"
    with requests.get(url) as r:
        r.raise_for_status()
        count = r.json()[0]["count"]

    return count


def _get_query_record_count(query):
    url = f"{DISCOVERY_URL}/query?_format=json"
    count_query = f"select count(1) as count from ({query})"
    with requests.post(url, data=count_query) as r:
        r.raise_for_status()
        count = r.json()[0]["count"]
    
    return count


def _load_dataset(organization, dataset, table, query=None):
    logging.info(f"Loading dataset {dataset} into {table}")
    
    if query:
        record_count = _get_query_record_count(query)
        limit = f"limit {DISCOVERY_DATA_LIMIT}" if DISCOVERY_DATA_LIMIT else ''
        file_path = _query_dataset(f"{DISCOVERY_URL}/query?_format=csv", f"select * from ({query}) {limit}")
    else:
        record_count = _get_record_count(organization, dataset)
        limit = f"?limit={DISCOVERY_DATA_LIMIT}" if DISCOVERY_DATA_LIMIT else ''
        file_path = _download_file(f"{DISCOVERY_URL}/organization/{organization}/dataset/{dataset}/query{limit}")

    loaded_count = _bulk_copy_csv_file(table, file_path)

    logging.debug(f"Loaded {loaded_count}/{record_count} records into {table}")
    if not limit:
        assert loaded_count == record_count, f"load dataset did not copy all records: {loaded_count} != {record_count}"


def _conn_string():
    return 'Driver={ODBC Driver 17 for SQL Server};Server=' \
        + SQL_SERVER_URL + ';Database=' + SQL_SERVER_DATABASE \
        + ';UID=' + SQL_SERVER_USERNAME + ';PWD=' + SQL_SERVER_PASSWORD \
        + ';MARS_Connection=Yes;'


def _run_statement(conn, statement):
    logging.debug(f"running statement {statement}")
    with conn.cursor() as cur:
        try:
            return cur.execute(statement)
        except pyodbc.ProgrammingError as e:
            (code, _message) = e.args
            if code != '42S02': # object not found (typically thrown by DROP on a missing table)
                logging.error(e)
                raise e
            else:
                logging.warn(f"a table was not found: {e}")
                return e


def _run_sql_file(file_name):
    logging.info(f"running sql file {file_name}")
    conn = pyodbc.connect(_conn_string(), autocommit=True)

    with open(file_name, 'r') as script:
        sqlScript = script.read().strip()
        statements = sqlScript.split(';')

        legit_statements = filter(lambda s: s.strip() != '', statements)
        _results = list(map(lambda s: _run_statement(conn, s), legit_statements))

    conn.close()


def load_data():
    _run_sql_file(f"{CONDUCTOR_PWD}/../sql/00_ref_tables.sql")

    query = f"""
        with metered_zones as (SELECT case "meter id" when '' then '-1' else "meter id" end as meter, "PM Zone Number" as zone_name FROM city_of_columbus__columbus_parking_meters)
        select distinct meter, zone_name from metered_zones where meter != '-1'
    """
    _load_dataset('city_of_columbus', 'columbus_parking_meters', 'ref_meter', query)

    query = f"""
        with pm_or_not as (select case when cast("PM Zone Number" as int) < 10000 then 1 else 0 end as pm_zone, case "meter id" when '' then 1 else 0 end as pm_only, * from city_of_columbus__columbus_parking_meters)
        select "PM Zone Number" as zone_name, pm_only, count(1) as total_cnt, 1 as zone_eff_flg, 1 as pred_eff_flg from pm_or_not where pm_zone = 0 group by "PM Zone Number", pm_only
    """
    _load_dataset('city_of_columbus', 'columbus_parking_meters', 'ref_zone', query)

    semihour.generate_timetable(f"{CONDUCTOR_PWD}/../ref_data/ref_semihourly_timetable.dat", SQL_SERVER_DATA_LIMIT_MONTHS)
    _bulk_copy_ref_file('ref_semihourly_timetable')
    _bulk_copy_ref_file('ref_calendar_parking')

    _run_sql_file(f"{CONDUCTOR_PWD}/../sql/01_staging_tables.sql")

    _load_dataset('ips_group', 'parking_meter_inventory_2020', 'stg_ips_group_parking_meter_inventory_2020')

    query = f"""
        with max_date as (select max(EndTime) as maximum from ips_group__columbus_parking_meter_transactions)
        SELECT starttime, endtime, meterid from ips_group__columbus_parking_meter_transactions where EndTime > date_add('month', -{SQL_SERVER_DATA_LIMIT_MONTHS}, (select * from max_date))
    """
    _load_dataset('ips_group', 'columbus_parking_meter_transactions', 'stg_parking_tranxn_source', query)

    parkmobile_query = f"""
        with max_date as (select max(parking_action_stop_at_local) as maximum from parkmobile__park_columbus_parking_meter_sessions_data)
        SELECT  parking_action_stop_at_local as parking_end_date,
                parking_action_start_at_local as parking_start_date,
                zone_code as zone
        from parkmobile__park_columbus_parking_meter_sessions_data
        where parking_action_stop_at_local > date_add('month', -{SQL_SERVER_DATA_LIMIT_MONTHS}, (select * from max_date))
    """
    _load_dataset('parkmobile', 'park_columbus_parking_meter_sessions_data', 'stg_parkmobile', parkmobile_query)


def _run_etl_for_ips():
    for root, _dirs, files in walk(f"{CONDUCTOR_PWD}/../sql/ips", topdown=True):
        files.sort()
        for name in files:
            _run_sql_file(path.join(root, name))


def _run_etl_for_park_mobile():
    for root, _dirs, files in walk(f"{CONDUCTOR_PWD}/../sql/park_mobile", topdown=True):
        files.sort()
        for name in files:
            _run_sql_file(path.join(root, name))


def _run_aggregation():
    _run_sql_file(f"{CONDUCTOR_PWD}/../sql/16_aggregate_occupancy.sql")


def run_etl():
    _run_etl_for_ips()
    _run_etl_for_park_mobile()
    _run_aggregation()


load_data()
run_etl()