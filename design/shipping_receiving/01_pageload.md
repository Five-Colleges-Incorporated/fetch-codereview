# Shipping/Receiving Page Load

### Prerequisites

Permissions must be added to the database in a migration.
A new tab with permission toggles has to be added to the Admin section.
The NavigationBar has to have a new link for Shipping/Receiving.

A database migration has to create appropriate tables (modeled of existing jobs).

A new Page for Shipping/Receiving + Vue Route must be created.
We'll also need Components for the Dashboard and Job Details and a new store.
A new route in the Inventory Service for Shipping/Receiving jobs.
The route has to be registered in the frontend in the InventoryService.js

### Diagram

Loading Shipping/Receiving jobs is very similar to loading other jobs.

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant srd as /components/ShipRec/ShipRecDashboard.vue
    participant srjd as /components/ShipRec/ShipRecJobDetails.vue
    participant gs as /stores/global-store.js
    participant srp as /pages/ShipRecPage.vue
    participant srs as /stores/shiprec-store.js
    participant os as /stores/option-store.js
    participant ax as /boot/axios.js
    participant isjs as /http/InventoryService.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant srj as /routers/shiprec_jobs.py
    participant /routers/*.py@{ "type": "collections" }
    participant /models/*.py@{ "type": "collections" }
    participant db as /app/database/session.py
end

User->>+srp: navigate to /shiprec/{jobId}
srp->>gs: pageInitLoading = true

rect rgba(250, 200, 50, .1)
alt {jobId} != null
    srp->>+srs: getShipRecJob({jobId})
    srs->+ax: $api.get $VITE_INV_SERVCE_API/shiprec-jobs/{jobId}
    ax->isjs: 
    isjs->>+srj: 

    srj->>db: SELECT 1 ShipRecJob
    db->/models/*.py: ShipRecJob
    /models/*.py->>srj:
    srj->>srj: sort items
    srj->-/schemas/*.py: ShipRecJob
    /schemas/*.py->ax: 
    ax->>-srs: 
    srs->>-srs: shipRecJob = {ShipRecJob}<br/>originalShipRecJob = {ShipRecJob}
end
end
srp->>-gs: pageInitLoading = false

gs-->+srp: v-if: !pageInitLoading
rect rgba(250, 200, 50, .1)
alt {jobId} == null
    srp->srd: Render
    srd->>User:
else {jobId} != null
    srp->srjd: Render
    srjd->>User:
    deactivate srp
end
end
```
