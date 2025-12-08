# Shipping/Receiving

## Table of Contents
* [Page Load](./01_pageload.md)
* [Dashboard](./02_dashboard.md)
* [Create ShipRec Job](./03_new_job.md)
* [Perform Shipping Job](./04_perform_shipping.md)
* [Perform Receiving Job](./05_perform_receiving.md)

#### The good

There are existing patterns for everything involved in Shipping/Receiving which allows the new module to be implemented consistently.
There is a database migration framework which allows for required changes to the database to be consistently applied.

#### The ok but notable

One of the existing patterns is the Tray/Non-Tray split.
This pattern permeates everywhere even down to the database.
It makes it easy to have a similarly "optional" tote piece for shipping/receiving.
But it also means that Shipping/Receiving has to know and care about trays.

#### Areas of improvement

There is a lot that has to be added even though it is similar to patterns that already exist.
Abstraction can definitely allow more quickly adding functionality if it is similar to existing.

