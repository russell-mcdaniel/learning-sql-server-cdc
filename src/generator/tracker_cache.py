import concurrent.futures
import random
import traceback

import cachetools
import pyodbc


# Static entity caches.
_company_cache = []                     # List of company keys.
_useraccount_cache = {}                 # Lists of user account keys for each company.
_facility_cache = {}                    # Lists of facility keys for each company.
_item_cache = {}                        # Lists of item keys for each facility.
_device_cache = {}                      # Lists of device keys for each facility.

# Cycled entity caches.
_patient_cache = {}                     # Lists of patient keys for each facility.
_patient_cache_size = 480               # Patients generated per day per facility.

_encounter_cache = {}                   # Lists of encounter keys for each patient.
_encounter_cache_size = 144             # Encounters generated per day per patient.

_pharmacy_order_cache = {}              # Lists of order keys for each encounter.
_pharmacy_order_cache_size = 48         # Orders generated per day per encounter.

# Cache initialization parameters.
_worker_threads = 10

# Database connection information.
_sql_connection_string = ''


def _cache_companies():
    
    with pyodbc.connect(_sql_connection_string, autocommit=True) as connection:

        with connection.cursor() as cursor:

            sql = 'SELECT CompanyKey FROM dbo.Company;'

            global _company_cache
            _company_cache = [row[0] for row in cursor.execute(sql)]

    with concurrent.futures.ThreadPoolExecutor(max_workers=_worker_threads) as executor:
        executor.map(_cache_company, _company_cache)


def _cache_company(company_key):

    with pyodbc.connect(_sql_connection_string, autocommit=True) as connection:

        with connection.cursor() as cursor:

            _cache_useraccounts(company_key, cursor)
            _cache_facilities(company_key, cursor)


def _cache_useraccounts(company_key, cursor):

    sql = 'SELECT UserAccountKey FROM dbo.UserAccount WHERE CompanyKey = ?;'

    global _useraccount_cache
    _useraccount_cache[company_key] = [row[0] for row in cursor.execute(sql, company_key)]


def _cache_facilities(company_key, cursor):

    sql = 'SELECT FacilityKey FROM dbo.Facility WHERE CompanyKey = ?;'

    global _facility_cache
    _facility_cache[company_key] = [row[0] for row in cursor.execute(sql, company_key)]

    for facility_key in _facility_cache[company_key]:
        _cache_items(company_key, facility_key, cursor)
        _cache_devices(company_key, facility_key, cursor)
        _cache_patients(company_key, facility_key, cursor)


def _cache_items(company_key, facility_key, cursor):

    sql = 'SELECT ItemKey FROM dbo.Item WHERE CompanyKey = ? AND FacilityKey = ?;'

    global _item_cache
    _item_cache[facility_key] = [row[0] for row in cursor.execute(sql, company_key, facility_key)]


def _cache_devices(company_key, facility_key, cursor):

    sql = 'SELECT DeviceKey FROM dbo.Device WHERE CompanyKey = ? AND FacilityKey = ?;'

    global _device_cache
    _device_cache[facility_key] = [row[0] for row in cursor.execute(sql, company_key, facility_key)]


def _cache_patients(company_key, facility_key, cursor):

    sql = 'SELECT PatientKey FROM dbo.Patient WHERE CompanyKey = ? AND FacilityKey = ?;'

    global _patient_cache
    _patient_cache[facility_key] = cachetools.TTLCache(maxsize=_patient_cache_size, ttl=86400)

    for row in cursor.execute(sql, company_key, facility_key):
        _patient_cache[facility_key][row[0]] = b''


def _cache_encounters(company_key, patient_key, cursor):

    sql = 'SELECT EncounterKey FROM dbo.Encounter WHERE CompanyKey = ? AND PatientKey = ?;'


def _cache_pharmacy_orders(company_key, encounter_key, cursor):

    sql = 'SELECT PharmacyOrderKey FROM dbo.PharmacyOrder WHERE CompanyKey = ? AND EncounterKey = ?;'


def get_company():
    return random.choice(_company_cache)


def get_useraccount(company_key):
    return random.choice(_useraccount_cache[company_key])


def get_facility(company_key):
    return random.choice(_facility_cache[company_key])


def get_item(facility_key):
    return random.choice(_item_cache[facility_key])


def get_device(facility_key):
    return random.choice(_device_cache[facility_key])


def get_patient(facility_key):
    return random.choice(list(_patient_cache[facility_key].keys()))


def get_encounter(patient_key):
    pass


def get_pharmacy_order(encounter_key):
    pass


def initialize(sql_connection_string):

    global _sql_connection_string
    _sql_connection_string = sql_connection_string

    _cache_companies()
