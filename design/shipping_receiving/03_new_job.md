# New Shipping/Receiving Job

### Prerequisites

Shipping/Receiving is one module but needs to have multiple routes to handle the two different jobs.

We can already get the Destination from the Pick List -> Request relationship.

The Request object/table needs to be updated to contain a relationship to the Shipping Job.

### Diagram

This is very similar to creating either refile job (shipping) or creating an accession job (receiving)

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant router as router/index.js
    participant et as /components/EssentialTable.vue
    participant rd as /components/ShipRec/ShipRecDashboard.vue
    participant si as /components/SelectInput.js
    participant rs as /stores/shiprec-store.js
    participant bs as /stores/barcode-store.js
    participant os as /stores/option-store.js
    participant ax as /boot/axios.js
    participant isjs as /http/InventoryService.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant rq as /routers/shiprec_queue.py
    participant rj as /routers/shiprec_jobs.py
    participant /models/*.py@{ "type": "collections" }
    participant db as /app/database/session.py
end

User->>+rd: Create > Create Shipping job
rd->>si: Render
si<<->>os: getOptions {destination}
note over os: Normal Query Workflow
User->>si: Destination
User->>rd: Submit
rd<<->>rs: getShippingQueueList Destination
note over rs: Normal Query Workflow
rd->>-rd: showCreateShipRecJob = true

rd-->et: enable-selection: showCreateShipJob
loop
    User->>et: Select Item
end
User->>+rd: Create Shipping Job
rd->>rs: postShippingJob
rs->+ax: $api.post $VITE_INV_SERVCE_API/shipping-jobs
ax->isjs:
isjs->>+rj:
rj->>db: INSERT ShippingJob
rj->>db: Commit
loop
    rj->>db: UPDATE Request
end
rj->>db: Commit
rj->>db: SELECT ShippingJob
db->/models/*.py: ShippingJob
/models/*.py->>rj:
rj->>rj: sort items
rj->-/schemas/*.py: ShippingJob
/schemas/*.py->ax:
ax->>-rs:
rd->>-rs: getShippingQueueList
note over rs: Normal Query Workflow


User->>+rd: Create > Create Receiving job
rd->>si: Render
si<<->>os: getOptions {destination}
note over os: Normal Query Workflow
User->>si: Destination
User->>rd: Submit

rd->>rs: postReceivingJob
rs->+ax: $api.post $VITE_INV_SERVCE_API/receiving-jobs
ax->isjs:
isjs->>+rj:
rj->>db: INSERT ReceivingJob
rj->>db: Commit
rj->>db: SELECT ReceivingJob
db->/models/*.py: ReceivingJob
/models/*.py->>rj:
rj->-/schemas/*.py: ReceivingJob
/schemas/*.py->ax:
ax->>-rs:
deactivate rd
```
