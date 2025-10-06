# Accession Page Load

#### The good

Consistent layout and calls to get data from database.
Multiple backend services composed together into a single store.

SQLAlchemy back_populates vs backref

#### The ok but notable

ContainerId with no JobId.

Idk about how barcodes are handled.
No way to get back to the root object from the barcode.
Maybe use polymorphic_identity for the barcode switched on Type?
Then you can get barcode by id -> barcoded object by navigational property

Http error message is directly toasted to the user with no context.

In the store, errors are caught but then immediately rethrown.
In the store, state isn't reset upon navigating to the page.
store.resetAccessionStore() vs $reset() vs store.resetAccessionContainer()

duplicating data with originalXYZ to support "cancel edits" functionality

datetime fields not using server_default and instead doing their own thing
https://docs.sqlalchemy.org/en/20/core/compiler.html#utc-timestamp-function

#### Areas of improvement

Very inconsistent naming between frontend and backend.
jobId param -> /accession-jobs/workflow/{id} route
Docs in py call it the "accession job workflow" but it returns accession details.
The AccessionJob.workflow_id is the filter

Mispelled environment variable.

Why is the list of Accession Jobs not loaded in the same way?

Using setup stores to load store properties rather than explicit loads.
Potentially with an inner store functionality?

### Further investigations
* What happens if an error is thrown while loading the job?
* Backend auth/init code

### Diagram

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant ad as /components/Accession/AccessionDashboard.vue
    participant acd as /components/Accession/AccessionContainerDisplay.vue
    participant gs as /stores/global-store.js
    participant ap as /pages/AccessionPage.vue
    participant as as /stores/accession-store.js
    participant isjs as /http/InventoryService.js
    participant ax as /boot/axios.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant aj as /routers/accession_jobs.py
    participant t as /routers/trays.py
    participant nti as /routers/non_tray_items.py
    participant /models/*.py@{ "type": "collections" }
    participant db as /app/database/session.py
end

User->>+ap: navigate to /accession?jobId={jobId}&containerId={containerId}
ap->>gs: pageInitLoading = true


rect rgba(250, 200, 50, .1)
alt {jobId} != null
    ap->>+as: getAccessionJob
    as->>+ax: $api.get {jobId}
    isjs->>ax: accession-jobs/workflow/
    ax->>+aj: $VITE_INV_SERVCE_API/accession-jobs/workflow/{jobId}

    aj->>db: SELECT 1 AccessionJob
    db->>/models/*.py: AccessionJob
    /models/*.py->>aj: AccessionJob
    aj->>-/schemas/*.py: AccessionJob
    /schemas/*.py->>ax: AccessionJob
    ax->>-as: AccessionJob
    as->>as: accessionJob = {AccessionJob}<br/>originalAccessionJob = {AccessionJob}
end
end

rect rgba(250, 200, 50, .1)
alt {containerId} != null 
    ap<<->>as: accessionJob
    rect rgba(0, 150, 150, .2)
    alt accessionJob.trayed
        ap->>+as: getAccessionTray
        as->>+ax: $api.get {containerId}
        isjs->>ax: trays/barcode/
        ax->>+t: $VITE_INV_SERVCE_API/trays/barcode/{containerId}

        t->>db: SELECT 1 Tray JOIN Barcode
        db->>/models/*.py: Tray
        /models/*.py->>t: Tray
        t->>-/schemas/*.py: Tray
        /schemas/*.py->>ax: Tray
        ax->>-as: Tray
        as->>as: accessionContainer = {Tray}<br/>originalAccessionContainer = {Tray}
    else !accessionJob.trayed
        ap->>+as: getAccessionNonTrayItem
        as->>+ax: $api.get {containerId}
        isjs->>ax: /non_tray_items/barcode/
        ax->>+nti: $VITE_INV_SERVCE_API/non_tray_items/barcode/{containerId}

        nti->>db: SELECT 1 NonTrayItem JOIN Barcode
        db->>/models/*.py: NonTrayItem
        /models/*.py->>nti: NonTrayItem
        nti->>-/schemas/*.py: NonTrayItem
        /schemas/*.py->>ax: NonTrayItem
        ax->>-as: NonTrayItem
        as->>as: accessionContainer = {NonTrayItem}<br/>originalAccessionContainer = {NonTrayItem}
    end
    end
    rect rgba(255, 0, 0, .3)
    break Error
        ap->>User: Toast: {error}
        ap->>ap: Navigate to /accession?jobId={jobId}
    end
    end
end
end

ap->>-gs: pageInitLoading = false

gs-->ap: v-if: !pageInitLoading
rect rgba(250, 200, 50, .1)
alt {jobId} == null
    ap->>ad: Render
    ad->User:
else {jobId} != null
    ap->>acd: Render
    acd->User:
end
end
```
