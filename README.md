# Learning SQL Server CDC

A learning project for SQL Server CDC.

## Overview

Roughly approximate a Pyxis ES Server scenario.

## Components

* **Database.** Data storage container.
* **Generator.** Data creation workload.
* **Reader.** Simulate query workload.
* **Publisher.** Consume CDC feed and publish to message broker.

## Data Generation

The list of items is static because the pharmacy catalog is relatively static. Reference entities are periodically generated to simulate ongoing entry. Transactions are generated with randomly selected entities from a sliding window cache. This way transactions reference entities within a window of recency like real life.

### Entities

| Entity      | Type        | Disposition | Rate (Hr) | Life (Mn) | Ratio     | Peak      |
|-------------|-------------|-------------|-----------|-----------|-----------|-----------|
| Company     | Reference   | Static      | <div style="text-align: center">       -</div> | <div style="text-align: center"> -</div> | <div style="text-align: right">        c</div> | <div style="text-align: right">     1,000</div> |
| Facility    | Reference   | Static      | <div style="text-align: center">       -</div> | <div style="text-align: center"> -</div> | <div style="text-align: right">   10 x c</div> | <div style="text-align: right">    10,000</div> |
| User        | Reference   | Static      | <div style="text-align: center">       -</div> | <div style="text-align: center"> -</div> | <div style="text-align: right">  100 x f</div> | <div style="text-align: right"> 1,000,000</div> |
| Item        | Reference   | Static      | <div style="text-align: center">       -</div> | <div style="text-align: center"> -</div> | <div style="text-align: right">6,000 x f</div> | <div style="text-align: right">60,000,000</div> |
| Patient     | Reference   | Cycled      | <div style="text-align: right">  200 x c</div> | <div style="text-align: right">480</div> | <div style="text-align: right">         </div> | <div style="text-align: right">          </div> |
| Encounter   | Reference   | Cycled      | <div style="text-align: right">  400 x c</div> | <div style="text-align: right">240</div> | <div style="text-align: right">         </div> | <div style="text-align: right">          </div> |
| Order       | Reference   | Cycled      | <div style="text-align: right">  800 x c</div> | <div style="text-align: right">120</div> | <div style="text-align: right">         </div> | <div style="text-align: right">          </div> |
| Transaction | Transaction | Continuous  | <div style="text-align: right">4,000 x c</div> | <div style="text-align: center"> -</div> | <div style="text-align: right">         </div> | <div style="text-align: right">         -</div> |

### Notes

Some details regarding the nature of the data generation include:

* Facilities are generated randomly from 1-20 per company for an average of ~10.
* Static entities have a fixed number of instances generated.
* Cycled entities regularly have new instances generated that have a fixed lifespan. Records for expired instances are removed from the transaction selection pool, but remain in the database.
* Peak for static entities is the total number generated.
* Peak for cycled entities is the maximum number of active instances that can be selected for reference by a transaction at any given time.
* Patient lifespan enables selection for encounters.
* Encounter lifespan enables selection for transactions.
* Order lifespan enables selection for transactions.
  * OPEN: Should orders be linked to encounters and/or patients?
* Transactions do not directly select patients, only encounters. The patient is determined from the encounter. Since patients and encounters are related, but their lifespans are not linked in the program, this prevents problems during transaction generation.

### References

Peak observed rates in customer samples:

* Patient - 
* Encounter - 
* Order - 
* Transaction - 167,000/day

## Data Reader

TODO: Define queries and query rates.

## Data Publisher

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
