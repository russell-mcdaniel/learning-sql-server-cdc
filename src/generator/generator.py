import tracker_cache
import tracker_database


# Database connection information.
sql_driver = 'ODBC Driver 17 for SQL Server'
sql_server = '(local)'
sql_database = 'MedicationTracker'
sql_login = 'sa'
sql_password = 'sqlserver1!'

sql_connection_string = f'Driver={sql_driver};Server={sql_server};Database={sql_database};UID={sql_login};PWD={sql_password}'


def main():

    # Initialize the database.
    if not tracker_database.is_initialized(sql_connection_string):
        tracker_database.initialize(sql_connection_string)

    # Initialize the cache.
    tracker_cache.initialize(sql_connection_string)


if __name__ == "__main__":
    main()
