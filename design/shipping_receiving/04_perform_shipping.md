# Shipping Job

### Prerequisites

[NonTray]Items table will get a new column for tracking the shipping job.

### Diagram

This is very close to refiling, where there's a queue of items and the individually get updated as they're scanned.

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant et as /components/EssentialTable.vue
    participant rjd as components/ShipRec/ShippingJobDetails.vue
    participant rs as stores/shiprec-store.js
end
box fetch-inventory_service /app
    participant rj as /routers/shipping_jobs.py
    participant db as /app/database/session.py
end

User->>+rjd: Navigate to /shiprec/shipping/{id}

User->>+rjd: Execute Shipping Job
rjd->>+rs: patchShippingJob
rs->>rj: PATCH $VITE_INV_SERVCE_API/shipping-jobs/{id}

rj->>db: UPDATE ShippingJobDetails
rj->>db: COMMIT
rj->>rs: ShippingJob
deactivate rs

loop
    User->>+rjd: (Optional) Scan Tote Barcode

    loop
        User->>+rjd: Scan Item Barcode
        rjd->>rjd: Item Validation
        rjd->>rs: patchRefileJob[Non]TrayItemScanned

        rs->>rj: PATCH $VITE_INV_SERVCE_API/shipping-jobs/{id}/update_[non_tray_]item[s]/{itemId}
        rj->>db: UPDATE [NonTray]Item
        rj->>db: COMMIT

        rjd->>rs: Update shipping_job_items
        deactivate rjd
        rs-->et: :table-data=shipping_job_items
    end
end

User->>+rjd: Complete Job
rjd->>rs: patchShippingJob
note over rs: See above for patch workflow
deactivate rjd
```
