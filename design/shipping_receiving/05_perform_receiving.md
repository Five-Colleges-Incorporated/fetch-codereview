# Receiving Job

### Prerequisites

A new receiving_events table like the [non_tray_]items_retrieval_events table will have to be created.

A new background task to add the receiving jobs will have to be added.

### Diagram

This is closest to working an Accession job with an additional Tote piece.
The items already exist so the backend will know if they're trayed or non-trayed.

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant et as /components/EssentialTable.vue
    participant rjd as components/ShipRec/ReceivingJobDetails.vue
    participant rs as stores/shiprec-store.js
    participant gs as stores/global-store.js
end
box fetch-inventory_service /app
    participant rj as /routers/receiving_jobs.py
    participant db as /database/session.py
    participant t as /app/tasks.py
end

User->>+rjd: Navigate to /shiprec/receiving/{id}

User->>+rjd: Execute Receiving Job
rjd->>+rs: patchReceivingJob
rs->>rj: PATCH $VITE_INV_SERVCE_API/receiving-jobs/{id}

rj->>db: UPDATE ReceivingJobDetails
rj->>db: COMMIT
rj->>rs: ReceivingJob
deactivate rs

loop
    User->>+rjd: (Optional) Scan Tote Barcode

    loop
        User->>rjd: Scan Item Barcode
        rjd->>rs: postReceivingJob[Non]TrayItemScanned
        rs->>rj: POST $VITE_INV_SERVCE_API/receiving-jobs/{id}/receive_item
        rj->>db: INSERT [NonTray]ItemReceivingEvent
        rj->>db: COMMIT
        rj->>rs: [NonTray]Item

        rs->>rs: Update receiving_job_items
        rs-->et: :table-data=refile_job_items
    end
end
deactivate rjd
```
