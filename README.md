# parking_predictor_orchestration

The project handles the etl process needed to transform source data from Discovery into the data needed to train the parking prediction model.

Source data is in the form of Parking Transactions, while the model requires occupancy data. The etl process does this by inferring occupancy of a parking spot or zone by the number and duration of transactions in it.

This data is specific to the needs of Columbus, Ohio, and uses data from the vendors IPS and Parkmobile. The needs of your city and project might vary, and this repo is intended to serve as an example.

## How to run

```bash
pipenv install
pipenv shell
python app/conductor.py
```

```diff
- Warning: The entire etl flow takes 2-3 hours to run.
```

## Local development

Running changes to the etl flow against a remote environment is slow and painful. Fortunately, it's not necessary. The process can be run against a local SQL Server image using a subset of the data for much faster turn-around times.

```bash
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=yourStrong(!)Password' -p 1433:1433 -d mcr.microsoft.com/mssql/server:2017-latest
```

The conductor requires some environment variables to be set to talk to a local SQL Server database:

```bash
export SQL_SERVER_URL=127.0.0.1
export SQL_SERVER_DATABASE=master
export SQL_SERVER_USERNAME=sa
export SQL_SERVER_PASSWORD='yourStrong(!)Password'
export DISCOVERY_DATA_LIMIT=500
export SQL_SERVER_DATA_LIMIT_MONTHS=3
```
