# Accession

#### The good

The patterns used here are consistent with elsewhere.

#### The ok but notable

AccessionDashboard and AccessionContainerDisplay are "components" instead of individual routes.
This leads to "Routing" happening both in vue-router and the Accession page itself.

Most of the calls to verifyBarcode are autoAdding the barcode.
Adding a barcode as part of the verifyBarcode method is somewhat surprising but has to be explicitly asked for.
The pattern of GET, check for 404, POST could be simplified to a PUT operation.

It's unclear to me why the barcode state is stored in a Pinia store.
I think this again relates back to not using Pinia properly.

Detecting duplication is done in python even though it is already enforced in the database.

Background tasks are hardcoded to run on the web server with no easy way to send them to background worker.

#### Areas of improvement

POSTing the AccessionJob returns the accession job.
Then all jobs are fetched after going back to the list page.
Then the current job is fetched after being selected in the list.
Then the current job is fetched again when navigating to the job page.
Using Pinia and Vue Router better can eliminate this redundant loading.

The AccessionTrayInfo and AccessionNonTrayInfo components are 85% the same.
There's about 500 lines of duplicated code.
There's already subtle formatting and logic differences between them which will grow over time.
Even without AccessionContainerDisplay there are branches for tray/non-tray that are 85% the same.
This duplication continues into the backend as well with the item and non_tray_item routes being 85% the same.

#### Red Flags

The server does not do enough to enforce data integrity
Some of it has been offloaded to the frontend but the design and implementation of the backend make it difficult.
This will make it harder to extend FETCH in the future.

An example is there is nothing server-side preventing an Accession Job from being completed multiple times.
Each time it is completed a new Verification Job is created.
Using the following snippet leads to multiple jobs being created.
```js
const complete = Array.from(document.getElementsByTagName('button')).filter(b => b.textContent === 'Complete')[0]
[complete, complete, complete, complete, complete].forEach(b => b.click());
```

Withdrawn barcode functionality does not work unless I'm misunderstanding it.
I withdrew a barcode then re-used it for a new Accession Job.
FETCH gave me the option to re-accession it but then immediately errors because it is a duplicate.

Completing an accession job is supposed to "unwithdraw" all the withdrawn barcodes but it is missing a database commit so it does not.

### Diagram
```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant acd as components/Accession/AccessionContainerDisplay.js
    participant bs as stores/barcode-store.js
    participant as as stores/accession-store.js
end
box fetch-inventory_service /app
    participant b as /routers/barcodes.py
    participant aj as /routers/accession_jobs.py
    participant i as /routers/[non_tray_]items.py
    participant db as /app/database/session.py
    participant e as /events.py
    participant t as /tasks.py
end


rect rgba(250, 200, 50, .1)
loop
User->>+acd: triggerItemScan
acd->>+bs: verifyBarcode
bs->>+b: GET $VITE_INV_SERVCE_API/barcodes/{barcode}
b<<->>db: SELECT 1 Barcode
b->>bs: Barcode

rect rgba(0, 150, 150, .2)
alt barcode.type != 'Item'
    bs->>User: Toast: "The scanned barcode exists but is not an Item barcode! Please try again."
else barcode == null
    bs->>+b: POST $VITE_INV_SERVCE_API/barcodes
    Note right of b: Validation
    b<<->>db: SELECT 1 BarcodeType
    b<<->>db: SELECT 1 SizeClass
    b<<->>db: SELECT 1 Barcode
    b->>db: INSERT Barcode
    b<<->>db: SELECT 1 Barcode
    b->>db: COMMIT
    b->>-bs: Barcode
    bs->>-acd: barcodeDetails
end
end
end

acd->>as: postAccession[Non]TrayItem
as->>+i: POST $VITE_INV_SERVCE_API/[non_tray_items]items
Note right of i: Validation
i<<->>db: SELECT 1 [NonTray]Item
i->>db: COMMIT
i-->>+e: queue: update_shelf_available_space_on_non_tray_item_mutation
i<<->>db: SELECT 1 [NonTray]Item
i->>-as: [NonTray]Item
e->>db: UPDATE Shelf
e->>db: UPDATE ShelfPosition
e->>-db: COMMIT
end
deactivate acd

User->>+acd:Complete Job
acd->>as: patchAccession[Job/Tray]
as->>+i: PATCH $VITE_INV_SERVCE_API/accession-jobs/{id}
Note right of i: Validation
i<<->>db: SELECT 1 AccessionJob
i<<->>db: SELECT 1 ContainerType
i->>db: UPDATE AccessionJob
i->>db: COMMIT
i->>db: UPDATE Barcodes
i-xdb: Does not call COMMIT!
i-->>+t: queue: complete_accession_job
i<<->>db: SELECT 1 [NonTray]Item
i->>-as: [NonTray]Item
acd->>User: Toast: The Job has been completed and moved for verification.
acd->>-User: Navigate to /accession

t->>db: UPDATE AccessionJob
t->>db: COMMIT
t->>db: INSERT VerificationJob
t->>db: COMMIT
t<<->>db: SELECT Items, Trays, NonTray Items
loop
    t->>db: UPDATE Item/Tray/NonTray Item
end
t->>-db: COMMIT
```
