import concurrent.futures
import datetime
import uuid
import random
import traceback

import pyodbc
from faker import Faker


# Database initialization parameters.
_company_count = 1
_useraccount_count = 100        # Per company.
_facility_count = 10            # Per company.
_item_count = 50                # Per facility.
_device_count = 50              # Per facility.

_patient_count = 20             # Per facility, per hour.
_encounter_count = 6            # Per patient.
_pharmacy_order_count = 2       # Per encounter.

_hour_count = 24                # Hours of records to create.
_worker_threads = 10

_item_cache = {}                # Item cache for orders.

# Database connection information.
_sql_connection_string = ''


def _create_companies():
    """Creates companies and all subordinate entities."""

    fake = Faker()
    company_names = [fake.unique.company() for _ in range(_company_count)]

    with concurrent.futures.ThreadPoolExecutor(max_workers=_worker_threads) as executor:
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
        print(f'Unexpected error creating company "{company[1]}" ({company[0]}).')
        traceback.print_exc()
        raise


def _create_useraccounts(company_key, company_name, cursor):
    """Creates user accounts for the specified company."""

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
    """Creates facilities for the specified company."""

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

    _create_patients(company_key, facility_key, cursor)


def _create_items(company_key, facility_key, cursor):
    """Creates items for the specified facility."""
    
    _item_cache[facility_key] = []

    fake = Faker()

    for _ in range(_item_count):
        _create_item(company_key, fake.unique.text(max_nb_chars=100), facility_key, cursor)


def _create_item(company_key, item_name, facility_key, cursor):

    item_key = uuid.uuid4()
    item = (company_key, item_key, item_name, facility_key, datetime.datetime.now())

    sql = 'INSERT INTO dbo.Item (CompanyKey, ItemKey, ItemName, FacilityKey, CreatedAt) VALUES (?, ?, ?, ?, ?);'
    cursor.execute(sql, item)

    _item_cache[facility_key].append(item[1])


def _create_devices(company_key, facility_key, cursor):
    """Create devices for the specified facility."""

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


def _create_patients(company_key, facility_key, cursor):
    """Create patients for the specified facility."""

    # TODO: Consider providing the facility-level fake from the facility creation
    #       function. This approach is equivalent, but may not be intuitive.
    fake = Faker()

    for _ in range(_patient_count * _hour_count):
        _create_patient(company_key, fake.unique.name(), fake.unique.date_of_birth(), facility_key, fake, cursor)


def _create_patient(company_key, patient_name, birthdate, facility_key, facility_fake, cursor):

    patient_key = uuid.uuid4()
    patient = (company_key, patient_key, patient_name, birthdate, facility_key, datetime.datetime.now())

    sql = 'INSERT INTO dbo.Patient (CompanyKey, PatientKey, PatientName, Birthdate, FacilityKey, CreatedAt) VALUES (?, ?, ?, ?, ?, ?);'
    cursor.execute(sql, patient)

    _create_encounters(company_key, patient_key, facility_key, facility_fake, cursor)


def _create_encounters(company_key, patient_key, facility_key, facility_fake, cursor):
    """Creates encounters for the specified patient."""

    for _ in range(_encounter_count):
        _create_encounter(company_key, facility_fake.unique.bothify(text='ENC-?????-##########'), patient_key, facility_key, facility_fake, cursor)


def _create_encounter(company_key, encounter_id, patient_key, facility_key, facility_fake, cursor):

    encounter_key = uuid.uuid4()
    encounter = (company_key, encounter_key, encounter_id, patient_key, facility_key, datetime.datetime.now())

    sql = 'INSERT INTO dbo.Encounter (CompanyKey, EncounterKey, EncounterId, PatientKey, FacilityKey, CreatedAt) VALUES (?, ?, ?, ?, ?, ?);'
    cursor.execute(sql, encounter)

    _create_pharmacy_orders(company_key, encounter_key, patient_key, facility_key, facility_fake, cursor)


def _create_pharmacy_orders(company_key, encounter_key, patient_key, facility_key, facility_fake, cursor):
    """Creates orders for the specified encounter."""

    for _ in range(_pharmacy_order_count):
        _create_pharmacy_order(company_key, facility_fake.unique.bothify(text='ORD-?????-##########'), encounter_key, patient_key, facility_key, cursor)


def _create_pharmacy_order(company_key, pharmarcy_order_id, encounter_key, patient_key, facility_key, cursor):

    pharmarcy_order_key = uuid.uuid4()
    item_key = random.choice(_item_cache[facility_key])
    order = (company_key, pharmarcy_order_key, pharmarcy_order_id, item_key, encounter_key, patient_key, facility_key, datetime.datetime.now())

    sql = 'INSERT INTO dbo.PharmacyOrder (CompanyKey, PharmacyOrderKey, PharmacyOrderId, ItemKey, EncounterKey, PatientKey, FacilityKey, CreatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?);'
    cursor.execute(sql, order)


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
