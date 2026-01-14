# Accession Page Load

#### The good

There is a consistent file layout and calls to get data from database.
Multiple backend services are composed together into a single logical store.

SQLAlchemy is using back_populates which is more readable than backref.

#### The ok but notable

What happens when there's a ContainerId with no JobId.

Barcodes should probably be using something like `polymorphic_identity` to have different python classes for barcode types.
This would allow getting back to the barcoded object from the barcode itself.

Http error messages are directly toasted to the user with no context.

In the store, errors are caught but then immediately rethrown.
In the store, state isn't reset upon navigating to the page.
It isn't clear why `store.resetAccessionStore()` and `store.resetAccessionContainer()` are used vs the native `$reset()`.

Data is duplicated with the originalXYZ paradigm in order to cancel edits.
There are libraries or patterns out there that enable this in a more standard way.

datetime fields are not using server_default and instead doing their own thing
https://docs.sqlalchemy.org/en/20/core/compiler.html#utc-timestamp-function

pageInitLoading = false isn't set in a finally block

#### Areas of improvement

Very inconsistent naming between frontend and backend.
jobId param -> /accession-jobs/workflow/{id} route
Docs in py call it the "accession job workflow" but it returns accession details.
The AccessionJob.workflow_id is the filter

The environment variable VITE_INV_SERVCE_API is mispelled.

The stores are Options stores and explictly have calls to load/save state.
Using Setup stores can automate a lot of the state management.

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
