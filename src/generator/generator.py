import concurrent.futures
import datetime
import random
import uuid
import traceback

import pyodbc
from faker import Faker

# Data generation parameters.
company_count = 1
useraccount_count = 1000    # User accounts per company.
facility_count = 10         # Facilities per company.
device_count = 50           # Devices per facility.
item_count = 5000           # Items per facility.

company_cache = []          # List of company keys.
useraccount_cache = {}      # Lists of user account keys for each company key.
facility_cache = {}         # Lists of facility keys for each company key.
device_cache = {}           # Lists of device keys for each facility key.
item_cache = {}             # Lists of item keys for each facility key.

# Database connection information.
sql_driver = 'ODBC Driver 17 for SQL Server'
sql_server = '(local)'
sql_database = 'MedicationTracker'
sql_login = 'sa'
sql_password = 'sqlserver1!'

sql_connection_string = f'Driver={sql_driver};Server={sql_server};Database={sql_database};UID={sql_login};PWD={sql_password}'


def create_company(name):
    
    try:
        with pyodbc.connect(sql_connection_string) as connection:
            connection.autocommit = True

            with connection.cursor() as cursor:

                company = (uuid.uuid4(), name, datetime.datetime.now())
                company_cache.append(company[0])

                company_sql = 'INSERT INTO dbo.Company (CompanyKey, CompanyName, CreatedAt) VALUES (?, ?, ?);'
                cursor.execute(company_sql, company)

                create_useraccounts(cursor, company[0], company[1])
                create_facilities(cursor, company[0])
    except:
        print('Unexpected error.')
        traceback.print_exc()
        raise


def create_useraccounts(cursor, company_key, company_name):

    fake = Faker()
    useraccount_cache[company_key] = []

    for _ in range(useraccount_count):

        display_name = fake.unique.name()
        email = create_email(display_name, company_name)

        useraccount = create_useraccount(company_key, email, display_name)
        useraccount_cache[company_key].append(useraccount[1])

        useraccount_sql = 'INSERT INTO dbo.UserAccount (CompanyKey, UserAccountKey, Email, DisplayName, CreatedAt) VALUES (?, ?, ?, ?, ?);'
        cursor.execute(useraccount_sql, useraccount)


def create_useraccount(company_key, email, display_name):

    return (company_key, uuid.uuid4(), email, display_name, datetime.datetime.now())


def create_facilities(cursor, company_key):

    fake = Faker()
    facility_cache[company_key] = []

    for _ in range(facility_count):

        facility = create_facility(company_key, fake.unique.city())
        facility_cache[company_key].append(facility[1])

        facility_sql = 'INSERT INTO dbo.Facility (CompanyKey, FacilityKey, FacilityName, CreatedAt) VALUES (?, ?, ?, ?);'
        cursor.execute(facility_sql, facility)


def create_facility(company_key, name):

    return (company_key, uuid.uuid4(), name, datetime.datetime.now())


def create_email(display_name, company_name):

        email_username = (display_name
            .lower()
            .replace('.', '')
            .replace(' ', '.'))

        # Replacements based on known separators in Faker company provider:
        # https://github.com/joke2k/faker/blob/master/faker/providers/company/__init__.py
        email_domain = (company_name.lower()
            .replace(' ', '')
            .replace('-', '')
            .replace(',', '')
            + '.com')

        return f'{email_username}@{email_domain}'


def initialize_database():

    company_fake = Faker()
    company_names = [company_fake.unique.company() for _ in range(company_count)]

    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(create_company, company_names)


def is_initialized():
    return False


def populate_caches():
    pass


def main():

    # Initialize the database, if necessary. Otherwise, populate caches.
    if is_initialized():
       populate_caches()
    else:
       initialize_database()


if __name__ == "__main__":
    main()
