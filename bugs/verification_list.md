# Slow loading of Verification Jobs list


## Investigation

The User object eagerly loads every object type they're associated with,
with some of those object types eagarly loading additional data,
generating 16 additional sql queries.
This happens on every request to FETCH and is not unique to Verification Jobs.
It also happens a second/third/fourth/etc... time for each different user/created_by among verification jobs which is also not unique to Verification Jobs.

The mapping between the database VerificationJob and VerificationJobListOutput triggers the lazy loading of the Trays/Items/NonTrayItems.
Because the lazy loading behavior is not specified this is an N+1 query which is well-known to cause performance issues.

All dashboard pages (minus shelving) have this problem, it isn't clear why Verification is the only one having performance issues.
It is unclear to me why these list models return all the item information.
It isn't used in the frontend to the best of my knowledge.

## Hypothesis and possible fixes

SQLAlchemy is not being used appropriately in FETCH which is causing extreme load on the database.

The number of sql queries made loading the Verification Job List is `19 + 11V + 32` where V is the count of Verification Jobs.

As an example, with 5 Verification Jobs a single request to the API generates 106 SQL Queries:

* 1 SQL Query loading the current User
* 16 SQL Queries loading the current Users jobs
* 1 SQL Query counting the Verification Jobs for pagination
* 1 SQL Query getting the 5 Verification Jobs
* 5 SQL Query getting the Users for the Verification Jobs
* 16 SQL Queries loading the Users's jobs
* 5 SQL Query getting the CreatedBy's for the Verification Jobs
* 16 SQL Queries loading the CreatedBy's jobs
* 5 SQL Queries loading Trays by the 5 Verification Job Ids
* 5 SQL Queries loading MoveDiscrepencies by the Tray Ids
* 5 SQL Queries loading ShelvingJobDiscrepencies by the Tray Ids
* 5 SQL Queries loading Items by the 5 Verification Job Ids
* 5 SQL Queries loading MoveDiscrepencies by the Item Ids
* 5 SQL Queries loading ShelvingJobDiscrepencies by the Item Ids
* 5 SQL Queries loading NonTrayItems by the 5 Verification Job Ids
* 5 SQL Queries loading MoveDiscrepencies by the NonTrayItems Ids
* 5 SQL Queries loading ShelvingJobDiscrepencies by the NonTrayItem Ids

Even outside of the Dashboard pages, an excessive number of SQL queries are being run on every page of the application.

The only real fix for this is to sit down with the [extensive SqlModel docs](https://sqlmodel.tiangolo.com/learn/) as well as the [extensive SQLAlchemy Docs](https://docs.sqlalchemy.org/en/14/orm/loading_relationships.html#lazy-loading) and re-implement the best practices.
A fix can be band-aided here utilizing a different lazy load strategy for the verification jobs list.
