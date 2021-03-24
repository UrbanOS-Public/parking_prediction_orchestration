from datetime import datetime, timedelta
import csv

def generate_timetable(file_name, months=1):
    start_date = datetime.now() - timedelta(days=(months * 30) + 30)
    start_date = start_date.replace(hour=0, minute=0, second=0, microsecond=0)

    target_date = datetime.now() + timedelta(days=30)
    target_date = target_date.replace(hour=23, minute=29, second=0, microsecond=0)

    with open(file_name, 'w') as csvfile:
        data_writer = csv.writer(csvfile, delimiter='\t')
        date_cursor = start_date
        index = 1
        while date_cursor < target_date:
            data_writer.writerow([index, date_cursor])
            date_cursor = date_cursor + timedelta(minutes=30)
            index += 1