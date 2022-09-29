from collections import namedtuple

import tracker_activity
import tracker_cache
import tracker_database


# Database connection information.
SqlConfiguration = namedtuple('SqlConfiguration', ['driver', 'server', 'database', 'login', 'password'])
sql_config = SqlConfiguration('ODBC Driver 17 for SQL Server', '(local)', 'MedicationTracker', 'sa', 'sqlserver1!')

sql_connection_string = f'Driver={sql_config.driver};Server={sql_config.server};Database={sql_config.database};UID={sql_config.login};PWD={sql_config.password}'


def main():

    # Initialize the database.
    if not tracker_database.is_initialized(sql_connection_string):
        tracker_database.initialize(sql_connection_string)

    # Initialize the cache.
    tracker_cache.initialize(sql_connection_string)

    # Simulate activity.
    tracker_activity.start(sql_connection_string, tracker_cache)


if __name__ == "__main__":
    main()
