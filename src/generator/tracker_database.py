import concurrent.futures
import datetime
import uuid
import traceback

import pyodbc
from faker import Faker


# Database initialization parameters.
_company_count = 10
_useraccount_count = 10#00   # Per company.
_facility_count = 10         # Per company.
_item_count = 50#00          # Per facility.
_device_count = 50           # Per facility.

_company_threads = 10

# Database connection information.
_sql_connection_string = ''


def _create_companies():

    fake = Faker()
    company_names = [fake.unique.company() for _ in range(_company_count)]

    with concurrent.futures.ThreadPoolExecutor(max_workers=_company_threads) as executor:
        executor.map(_create_company, company_names)


def _create_company(company_names):
    
    try:
        with pyodbc.connect(_sql_connection_string, autocommit=True) as connection:

            with connection.cursor() as cursor:

                company_key = uuid.uuid4()
                company = (company_key, company_names, datetime.datetime.now())

                sql = 'INSERT INTO dbo.Company (CompanyKey, CompanyName, CreatedAt) VALUES (?, ?, ?);'
                cursor.execute(sql, company)

                _create_useraccounts(company_key, company_names, cursor)
                _create_facilities(company_key, cursor)
    except:
        print('Unexpected error.')
        traceback.print_exc()
        raise


def _create_useraccounts(company_key, company_name, cursor):

    fake = Faker()

    email_domain = _create_useraccount_email_domain(company_name)

    for _ in range(_useraccount_count):
        _create_useraccount(company_key, email_domain, fake.unique.name(), cursor)


def _create_useraccount(company_key, email_domain, display_name, cursor):

        email_username = _create_useraccount_email_username(display_name)
        email = f'{email_username}@{email_domain}'

        useraccount = (company_key, uuid.uuid4(), email, display_name, datetime.datetime.now())

        sql = 'INSERT INTO dbo.UserAccount (CompanyKey, UserAccountKey, Email, DisplayName, CreatedAt) VALUES (?, ?, ?, ?, ?);'
        cursor.execute(sql, useraccount)


def _create_useraccount_email_domain(company_name):

        # Replacements based on known separators in Faker company provider.
        # https://github.com/joke2k/faker/blob/master/faker/providers/company/__init__.py
        return (company_name.lower()
            .replace(' ', '')
            .replace('-', '')
            .replace(',', '')
            + '.com')


def _create_useraccount_email_username(display_name):

        # Replacement includes period to cover titles (e.g. "Dr.").
        return (display_name
            .lower()
            .replace('.', '')
            .replace(' ', '.'))


def _create_facilities(company_key, cursor):

    fake = Faker()

    for _ in range(_facility_count):
        _create_facility(company_key, fake.unique.city(), cursor)


def _create_facility(company_key, facility_name, cursor):

    facility_key = uuid.uuid4()
    facility = (company_key, facility_key, facility_name, datetime.datetime.now())

    sql = 'INSERT INTO dbo.Facility (CompanyKey, FacilityKey, FacilityName, CreatedAt) VALUES (?, ?, ?, ?);'
    cursor.execute(sql, facility)

    _create_items(company_key, facility_key, cursor)
    _create_devices(company_key, facility_key, cursor)


def _create_items(company_key, facility_key, cursor):

    fake = Faker()

    for _ in range(_item_count):
        _create_item(company_key, fake.unique.text(max_nb_chars=100), facility_key, cursor)


def _create_item(company_key, item_name, facility_key, cursor):

    item_key = uuid.uuid4()
    item = (company_key, item_key, item_name, facility_key, datetime.datetime.now())

    sql = 'INSERT INTO dbo.Item (CompanyKey, ItemKey, ItemName, FacilityKey, CreatedAt) VALUES (?, ?, ?, ?, ?);'
    cursor.execute(sql, item)


def _create_devices(company_key, facility_key, cursor):

    fake = Faker()

    for _ in range(_device_count):
        _create_device(company_key, _create_device_name(fake), facility_key, cursor)


def _create_device(company_key, device_name, facility_key, cursor):

    device_key = uuid.uuid4()
    device = (company_key, device_key, device_name, facility_key, datetime.datetime.now())

    sql = 'INSERT INTO dbo.Device (CompanyKey, DeviceKey, DeviceName, FacilityKey, CreatedAt) VALUES (?, ?, ?, ?, ?);'
    cursor.execute(sql, device)


def _create_device_name(fake):

    device_zone = fake.random_element(elements=('North', 'East', 'South', 'West', 'Central'))
    device_label = fake.unique.word().capitalize()

    return f'{device_zone} {device_label}'


def initialize(sql_connection_string):

    global _sql_connection_string
    _sql_connection_string = sql_connection_string

    _create_companies()


def is_initialized(sql_connection_string):

    with pyodbc.connect(sql_connection_string, autocommit=True) as connection:

        with connection.cursor() as cursor:

            sql = 'IF EXISTS (SELECT * FROM dbo.Company) SELECT CAST(1 AS bit) ELSE SELECT CAST(0 AS bit);'
            cursor.execute(sql)

            row = cursor.fetchone()

            return row[0]
