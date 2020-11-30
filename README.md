# Learning SQL Server CDC

A learning project for SQL Server CDC.

## Overview

Roughly approximate a medication tracking scenario.

## Components

Storage

* **Database.** Transactional data.
* **Message broker.** Published message data.

Programs

* **Generator.** Transactional workload.
* **Purger.** Purge workload.
* **Reader.** Query workload.
* **Publisher.** Publishing workload (from CDC to broker).

## Data Generation

The list of items is static because pharmacy catalogs are relatively stable. Reference entities are periodically generated to simulate ongoing entry. Transactions are generated with randomly selected entities from a sliding window cache. This way transactions reference entities within a window of recency approximating actual usage.

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
| Encounter   | Cycled      |      6 x p |      1,200 |     28,800 |
| Order       | Cycled      |      2 x e |      2,400 |     57,600 |
| Transaction | Continuous  |     12 x d |      6,000 |    144,000 |

### Notes

General Information

* Static entities have a fixed number of instances generated.
* Cycled entities regularly have new instances generated that have a fixed lifespan of 24 hours. Records for expired instances are removed from the selection pool, but remain in the database.

Transaction Creation

* Patient lifespan enables selection for encounters.
* Encounter lifespan enables selection for orders.
* Order lifespan enables selection for transactions.
* Transactions do not directly select patients or encounters - only orders. The patient and encounter is determined from the order.

Observed daily peak, average, and ratio per patient record:

| Entity       | Peak      | Average   | Ratio  |
|--------------|----------:|----------:|-------:|
| Patients     |     5,000 |     2,600 |      - |
| Encounters   |    31,000 |    15,800 |    6.4 |
| Orders       |    57,000 |    30,400 |   12.1 |
| Transactions |   174,000 |    93,100 |   35.2 |

File System Performance

In its default configuration, SQL Server on Linux in Docker will saturate the file I/O capacity under modest workloads. This will manifest itself with `PREEMPTIVE_OS_FLUSHFILEBUFFERS` waits and spinlock yield messages on the service console. In order to resolve this, set trace flag 3979 to disable the **forced flush** behavior on Linux.

* [GitHub Issue](https://github.com/Microsoft/mssql-docker/issues/355) | [MS KB4131496](https://support.microsoft.com/en-us/help/4131496/kb4131496-enable-forced-flush-mechanism-in-sql-server-2017-on-linux)
* [PREEMPTIVE_OS_FLUSHFILEBUFFERS waits on Linux](https://www.sqlskills.com/blogs/paul/preemptive_os_flushfilebuffers-waits-on-linux/) (Paul Randal)

To resolve:

* Log in to the SQL Server container as `root`:

> docker exec -u root -it sql-server_sql-server_1 /bin/bash

Other instructions show using `sudo` instead of logging in as `root`, but it does not appear to be available by default on the SQL Server on Linux image from Microsoft.

* Change to the directory with `mssql-conf`:

> cd /opt/mssql/bin

* Run `mssql-conf` to configure the trace flag:

> ./mssql-conf traceflag 3979 on

* Restart the SQL Server service by restarting the container.

Other instructions show using `systemctl` to restart the service, but it does not appear to be available by default in the SQL Server on Linux image from Microsoft.

Note that using `DBCC TRACEON (3979, -1)` from a SQLCMD session has the same effect, but only lasts for the session. Using `mssql-conf` configures the server to use this trace flag for the lifetime of your container (i.e. it will survive restarts until the container is removed altogether and recreated).

Benchmarks showing the result and duration of creating 100 company records:

| File System | Flush | Threads | Result  | Time     |
|-------------|-------|--------:|---------|---------:|
| Docker      | On    |       1 | Success | 1,102 ms |
| Docker      | On    |       2 | Failure |        - |
| Host        | On    |       1 | Success |   847 ms |
| Host        | On    |       2 | Failure |        - |
| Docker      | Off   |       1 | Success |   699 ms |
| Docker      | Off   |       2 | Success |   366 ms |
| Docker      | Off   |      10 | Success |   166 ms |
| Host        | Off   |      10 | Success |   142 ms |

## Data Reader

TODO: Define queries and query rates.

## Data Publisher

TODO: Describe.

## Data Purger

TODO: Describe.

## Experiments

Potential experiments for understanding performance and other behaviors of various designs.

**How does index design and resulting index fragmentation affect various use cases?**

* Entity insertion rate.
* Entity requests (individual).
* Entity requests (group e.g. patients by facility).

Potential indexing schemes (not exhaustive):

* Cluster on transaction key.
* Cluster on company and transaction key.
* Cluster on company, facility, and transaction key.
* Cluster on sequence number.
* Cluster on company and sequence number.

## Issues

**Unique keys that cross partitions.** Should globally unique entity keys be enforced? For example, facility key uniqueness is only enforced at the company scope, but a facility key should be globally unique as well. What is good design in this case? Should the partitioning be considered? Is it a first class member of the key composition? Or just an implementation detail to be ignored?

* Consider use cases. What if a facility were tranferred to another company? Are facilities immutable? Transfer using the existing facility key or copy with a new key?

**Key order of unique keys.** Consider reversing the key order of the unique keys to increase their selectivity. It may or may not be better based on the query workload.

**Support for SQL Server `datetimeoffset`.** SQL Server `datetimeoffset` is not supported by all ODBC drivers. This can cause a problem when querying a table with this type using pyodbc. The project will use `datetime2` instead.

* https://github.com/mkleehammer/pyodbc/issues/134
