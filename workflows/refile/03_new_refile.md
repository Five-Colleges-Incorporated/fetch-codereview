# New Refile Job

Creating a refile job is less consistent with Accession jobs.
This makes some sense as they have different requirements.

#### The good

The patterns for loading and saving data are the same as other workflows.

There is backend validation for adding an item to the Refile queue.

#### The ok but notable

There are some modals used for Refile which get their own component file.
I haven't seen this elsewhere in FETCH but I think I actually prefer it as a pattern.

When a barcode is scanned the details for it are explicitly gotten.
Then some checks happen in the frontend. The checks sometimes happen in verify but sometimes outside the store.
This all happens before the barcode can be used.

Done and Cancel do the same thing when adding an item. This is maybe a limitation of the modal framework?

Is this the first time that a toast has a link in it?
Is this accessible?

Adding an item to the refile queue is called "post" in the store but uses the patch verb.

#### Areas of improvement

When creating a refile job, first the request is checked for a list of barcodes.
It creates the job before checking to see whether the barcodes are for items or not.
After creation, the passed barcodes are checked to see if they're items.
If they're not they're considered "errored" and tracked in a list.
That list is not used for anything and there's no indication what happens with it.

When creating the refile job, because it re-uses the existing table after filtering by building you can mess with the filters and create a cross-building refile job.
There is no backend validation preventing this.

### Diagram

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant router as router/index.js
    participant et as /components/EssentialTable.vue
    participant raqi as /components/Refile/RefileAddQueueItem.vue
    participant rd as /components/Refile/RefileDashboard.vue
    participant si as /components/SelectInput.js
    participant rs as /stores/refile-store.js
    participant bs as /stores/barcode-store.js
    participant os as /stores/option-store.js
    participant ax as /boot/axios.js
    participant isjs as /http/InventoryService.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant rq as /routers/refile_queue.py
    participant rj as /routers/refile_jobs.py
    participant /models/*.py@{ "type": "collections" }
    participant db as /app/database/session.py
end

User->>+rd: Create > Add Item to Queue
rd->>-rd: showAddItemToQueue = true
rd-->+raqi: showAddItemToQueue
loop
    User->>+raqi: Barcode
    raqi->>bs:getBarcodeDetails
    note over bs: Normal Query Workflow
    raqi->>rs:postRefileQueueItem
    rs->+ax: $api.patch $VITE_INV_SERVCE_API/refile-queue
    ax->isjs:
    isjs->>+rq:
    rq<<->>db: SELECT Barcode
    rq<<->>db: SELECT [NonTray]Item
    rq<<->>db: SELECT RefileJob
    rq<<->>db: SELECT PickList
    rq->>db: UPDATE [NonTray]Item
    rq->>db: Commit
    db->/models/*.py: [NonTray]Item
    /models/*.py->>rq:
    rq->-/schemas/*.py: [NonTray]Item
    /schemas/*.py->ax:
    ax->>-rs:
    User->>raqi: Done
    deactivate raqi
end

User->>+rd: Create > Create Refile job
rd->>si: Render
si<<->>os: getOptions {building}
note over os: Normal Query Workflow
User->>si: Building
User->>rd: Submit
rd<<->>rs: getRefileQueueList building
note over rs: Normal Query Workflow
rd->>-rd: showCreateRefileJob = true

rd-->et: enable-selection: showCreateRefileJob
User->>et: Select Item
User->>+rd: Create Refile Job
rd->>rs: postRefileJob
rs->+ax: $api.post $VITE_INV_SERVCE_API/refile-jobs
ax->isjs:
isjs->>+rj:
rj->>db: INSERT RefileJob
rj->>db: Commit
loop
    rj->>db: UPDATE Item
end
rj->>db: Commit
rj->>db: SELECT RefileJob
db->/models/*.py: RefileJob
/models/*.py->>rj:
rj->>rj: sort items
rj->-/schemas/*.py: RefileJob
/schemas/*.py->ax:
ax->>-rs:
rd->>-rs: getRefileQueueList
note over rs: Normal Query Workflow
```
