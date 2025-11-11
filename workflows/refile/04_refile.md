# Refile

#### The good

#### The ok but notable

It's weird that the caller to the IndexDB is doing the serialization.

The screen size is only checked on page load which means it doesn't show the appropriate table columns if the screen is resized.

The data saved in the indexeddb doesn't actually have anything to do with the offline sync functionality.

Interesting how the refile store is explicitly queuing network requests.

`manage_transition` isn't used for accession or verification jobs but looks to be used for shelving, picklist, and refile jobs.

This is the first instance I've seen of using a method on a store to run some js instead of make a network request.
getRefileJobItem just looks up items in the existing refileJob by barcode.

There's also inconsistency with Accession Jobs because there's no background tasks to complete it.

Again, the Tray/NonTray item codepaths are almost identical.

#### Areas of improvement

The data saved in the indexeddb for the refile job isn't saved per id.

Patching a job takes the client side run_timestamp. This allows manipulation of the start/end/transition time of jobs by an untrusted source.
There's also again not checking for referential integrity here. The API can refile any item in any state.
Additionally, the edit item endpoints really allows overposting and you can edit almost any value on the Item.

### Diagram
```mermaid
sequenceDiagram
actor User
participant sw as /src-pwa/custom-service-worker.js
participant swc as serviceWorker.controller
box fetch-vue repository /src
    participant et as /components/EssentialTable.vue
    participant rid as components/Refile/RefileItemDetailModal.vue
    participant idb as composables/useIndexDbHandler.js
    participant rjd as components/Refile/RefileJobDetails.vue
    participant rs as stores/refile-store.js
    participant gs as stores/global-store.js
end
box fetch-inventory_service /app
    participant rj as /routers/refile_jobs.py
    participant db as /app/database/session.py
end

User->>+rjd: Navigate to /refile/{id}
rjd<<->>gs: appIsOffline
alt not appIsOffline
    rjd->>idb: addDataToIndexDb
else
    rjd<<->>idb: getDataInIndexDb
end
deactivate rjd

User->>+rjd: Execute Refile Job
rjd->>+rs: patchRefileJob
alt appIsOffline
    rs->>swc: postMessage 'queueIncomingApiCall'
    swc-->>sw: clientApiCallUrl = 'refile-jobs/{id}'
end
rs->>rj: PATCH $VITE_INV_SERVCE_API/refile-jobs/{id}
swc-->>sw: 'fetch' event
note over sw: Request Queue Workflow<br/>not documented here

rj->>db: UPDATE RefileJobDetails
rj->>db: COMMIT
rj->>rs: RefileJob
deactivate rs
rjd->>-idb: addDataToIndexDb

loop
    User->>+rjd: Scan Item Barcode
    rjd->>rjd: Item Validation
    rjd<<->>rs: getRefileJobItem
    note over rs: No network request
    rjd->>+rid: Render

    User->>rid: Shelf/Tray Barcode
    rid->>rid: Shelf Validation
    rid->>rs: patchRefileJob[Non]TrayItemScanned
    alt appIsOffline
        rs->>swc: postMessage 'queueIncomingApiCall'
        swc-->>sw: clientApiCallUrl = 'refile-jobs/{id}/update_[non_tray_]item[s]/{itemId}'
    end
    rs->>rj: PATCH $VITE_INV_SERVCE_API/refile-jobs/{id}/update_[non_tray_]item[s]/{itemId}
    swc-->>sw: 'fetch' event
    note over sw: Request Queue Workflow<br/>not documented here
    rj->>db: UPDATE [NonTray]Item
    rj->>db: COMMIT

    rid->>rs: Update refile_job_items
    rid->>idb: addDataToIndexDb
    rid->>rs: resetRefileItem
    rid-->>-rjd: emit 'hide'
    deactivate rjd
    rs-->et: :table-data=refile_job_items
end

User->>+rjd: Complete Job
rjd->>rs: patchRefileJob
note over rs: See above for patch workflow
rjd-->>idb:deleteDatainIndexDb
deactivate rjd
```
