# Learning SQL Server CDC

A learning project for SQL Server CDC.

## Overview

Roughly approximate a medication tracking scenario.

## Components

* **Database.** Data storage container.
* **Generator.** Data creation workload.
* **Purger.** Data purging workload.
* **Reader.** Query workload.
* **Publisher.** Consume CDC feed and publish to message broker.

## Data Generation

The list of items is static because the pharmacy catalog is relatively static. Reference entities are periodically generated to simulate ongoing entry. Transactions are generated with randomly selected entities from a sliding window cache. This way transactions reference entities within a window of recency like real life.

### Entities

Rates are specified per company.

| Entity      | Disposition | Ratio      | Rate (Hr)  | Rate (Day) |
|-------------|-------------|-----------:|-----------:|-----------:|
| Company     | Static      |          c |          - |          - |
| User        | Static      |  1,000 x c |          - |          - |
| Facility    | Static      |     10 x c |          - |          - |
| Device      | Static      |     50 x f |          - |          - |
| Item        | Static      |  5,000 x f |          - |          - |
| Patient     | Cycled      |     20 x f |        200 |      4,800 |
| Encounter   | Cycled      |    120 x f |      1,200 |     28,800 |
| Order       | Cycled      |    240 x f |      2,400 |     57,600 |
| Transaction | Continuous  |     12 x d |      6,000 |    144,000 |

### Notes

General Information

* Static entities have a fixed number of instances generated.
* Cycled entities regularly have new instances generated that have a fixed lifespan of 24 hours. Records for expired instances are removed from the selection pool, but remain in the database.
* Active static entities are the total number generated.
* Active cycled entities are the maximum number of instances that can be selected for reference by another entity at any given time.

Transaction Creation

* Patient lifespan enables selection for encounters.
* Encounter lifespan enables selection for orders.
* Order lifespan enables selection for transactions.
* Transactions do not directly select patients or encounters, only orders. The patient and encoutner is determined from the order.

Observed daily peak, average, and ratio per patient record:

| Entity       | Peak      | Average   | Ratio  |
|--------------|----------:|----------:|-------:|
| Patients     |     5,000 |     2,600 |      - |
| Encounters   |    31,000 |    15,800 |    6.4 |
| Orders       |    57,000 |    30,400 |   12.1 |
| Transactions |   174,000 |    93,100 |   35.2 |

## Data Reader

TODO: Define queries and query rates.

## Data Publisher

TODO: Describe.

## Data Purger

TODO: Describe.

## Experiments

Potential experiments for understanding performance and other behaviors of various designs.

**How does index design affect transaction insertion rate?**

* Cluster on transaction key.
* Cluster on company and transaction key.
* Cluster on company, facility, and transaction key.
* Cluster on sequence number.
* Cluster on company and sequence number.

Consider query patterns. How often are individual transactions requested?

## Issues

SQL Server `datetimeoffset` is not supported by all ODBC drivers. This can cause a problem when querying a table with this type using pyodbc. The project will use `datetime2` instead.

* https://github.com/mkleehammer/pyodbc/issues/134
