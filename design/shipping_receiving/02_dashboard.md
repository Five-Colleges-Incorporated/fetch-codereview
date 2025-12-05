# Shipping/Receiving Dashboard

### Prerequisites

When a PicklistJob is completed, the items are added to the Shipping/Receiving queue.
This can happen in a similar way to how Verification jobs are created after completing an Accession Job.

The Shipping/Receiving route in the Inventory Service will have to handle getting a list of Jobs.
There will also need to be a shiprec_queue route for managing the picked and waiting items.

### Diagram

The dashboard page is very similar to the Refile Dashboard with two tabs of jobs/queue.

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant rp as /pages/ShipRecPage.vue
    participant et as /components/EssentialTable.vue
    participant gs as /stores/global-store.js
    participant rd as /components/ShipRec/ShipRecDashboard.vue
    participant rs as /stores/shiprec-store.js
    participant ax as /boot/axios.js
    participant isjs as /http/InventoryService.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant fp as /filter_params.py
    participant rj as /routers/shiprec_jobs.py
    participant /models/*.py@{ "type": "collections" }
    participant bs as /routers/sorting.py
    participant db as /app/database/session.py
end
participant fap as fastapi-pagination

User->>+rp: navigate to /shiprec
rp->>+rd: Render
rd->>rs: resetShipRecStore
rd->>rd: loadShipRecJobs


rd->>rp: Render
rp->>-User:
rd->>gs: appIsLoadingData = true
gs-->et: :loading = appIsLoading
et->rp: Render Loading Spinner
rp->>User:

rd->>rs: getShipRecQueueList
note over rs: See below query workflow
rd->>+rs: getShipRecJobList
rs->+ax: $api.get $VITE_INV_SERVCE_API/shiprec-jobs
ax->isjs:
isjs->>+rj: 
fp->>rj: FilterParams
fp->>rj: SortParams 

rj<<->>bs: sort Query[ShipRecJob]
rj->>+fap: paginate Query[ShipRecJob]
fap<<->>db: SELECT FROM ShipRecJob WHERE params
fap->-/models/*.py: Page[ShipRecJob]
/models/*.py->>rj:
rj->-/schemas/*.py: Page[ShipRecJob]
/schemas/*.py->ax:
ax->>-rs:

rs->>rs: shiprecJobList = Page.items<br/>shiprecJobListTotal = Page.total
rd->>-gs: appIsLoadingData = false

gs-->et: :loading = appIsLoading
et<<->>rs: shiprecJobList
et->rp: Render Data
rp->>User:

User->>+et: Sort/Filter/Page
et->>rd: loadShipRecJobs params
note over rd: See above query workflow
gs-->et: :loading = appIsLoading
et<<->>rs: shiprecJobList
et->-rp: Render Data
rp->>User:

User->>+rd: Click "ShipRec Queue" Toggle
rd->>rd: loadShipRecJobs params
note over rd: See above query workflow
deactivate rd
gs-->+et: :loading = appIsLoading
et<<->>rs: shiprecQueueList
et->-rp: Render Data
rp->>User:
```

