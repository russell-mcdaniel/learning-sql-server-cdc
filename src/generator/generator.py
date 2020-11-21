import datetime
import random
import uuid

import pyodbc
from faker import Faker

# Data generation parameters.
company_count = 10
company_cache = []

facility_maximum = 20
facility_cache = []

item_count = 100
item_cache = {}

# Database connection information.
sql_driver = 'ODBC Driver 17 for SQL Server'
sql_server = '(local)'
sql_database = 'MedicationTracker'
sql_login = 'sa'
sql_password = 'sqlserver1!'

sql_connection_string = f'Driver={sql_driver};Server={sql_server};Database={sql_database};UID={sql_login};PWD={sql_password}'


def create_companies():

    with pyodbc.connect(sql_connection_string) as connection:
        connection.autocommit = True

        with connection.cursor() as cursor:

            fake = Faker()

            for _ in range(company_count):

                company = create_company(fake.unique.company())
                company_cache.append(company[0])

                cursor.execute('INSERT INTO dbo.Company (CompanyKey, CompanyName, CreatedAt) VALUES (?, ?, ?);', company)


def create_company(name):

    return (uuid.uuid4(), name, datetime.datetime.now())


def create_facilities():

    with pyodbc.connect(sql_connection_string) as connection:
        connection.autocommit = True

        with connection.cursor() as cursor:

            for company_key in company_cache:

                fake = Faker()

                facility_count = int(random.random() * facility_maximum) + 1
        
                for _ in range(facility_count):

                    facility = create_facility(company_key, fake.unique.city())
                    facility_cache.append(facility[0])

                    cursor.execute('INSERT INTO dbo.Facility (CompanyKey, FacilityKey, FacilityName, CreatedAt) VALUES (?, ?, ?, ?);', facility)


def create_facility(company_key, name):

    return (company_key, uuid.uuid4(), name, datetime.datetime.now())


def create_items():
    pass


def create_item():
    pass


def initialize_database():
    
    # Create reference entities.
    create_companies()
    create_facilities()
    create_items()


def main():

    # Initialize the database, if necessary. Otherwise, simply populate caches.
    #if not initialized_database():
    #    initialize_database()
    #else:
    #    populate_caches()
    initialize_database()


if __name__ == "__main__":
    main()
