#### The good


#### The ok but notable

Container type is a database object, are there really more than 2?
Why not an enum?

#### Areas of improvement

Opening and closing the modal does not follow the same paradigm.
It starts "open" but hidden.
Then showAccessionModal unhides it.
Then on close it actually closes using quasar properly.
The popup emits a reset event which also resets the showAccessionModal property.

The PopUp Component has default content for the Header slot including the ability to display a dynamic title.
This is almost never used and instances of the popup all implement their own almost identical version of the header slot.
Same with the footer.
The component emits a confirm event which doesn't appear to be handled.
Instead the users of the component override the whole footer content with very similar content.

There are multiple calls to session.commit() when creating an accession job.
First an empty workflow is created, then a new accession job is associated with it.
This can lead to partially constructed data in the database, especially if there's a validation error creating the accession job.
These should probably use flush() instead of commit.
Autoflush is doubly disabled during session_creation, why is this?
Autoflush seems like it would avoid manually managing the persistence?

There's a lot of weird handling around audit_info.
Rather than failing if not present it defaults to SYSTEM which might lead to audit trail misses.
We get the audit_info from the session.
Then after committing we add the audit_info back to the session.
This is all caused by the behavior around manual commits?


#### Red Flags

Decoding the jwt apparently uses a hardcoded secret key 'your-secret-key'!
This key is checked into source control!
This means anyone can change their permissions and sign a key to be accepted by the server.
This is in a file called middlware which is a mispelling of middleware.

### Diagram

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant router as router/index.js
    participant acd as /components/Accession/AccessionContainerDisplay.vue
    participant ad as /components/Accession/AccessionDashboard.vue
    participant as as /stores/accession-store.js
    participant isjs as /http/InventoryService.js
    participant ax as /boot/axios.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant aj as /routers/accession_jobs.py
    participant /models/*.py@{ "type": "collections" }
    participant db as /app/database/session.py
end

User->>+ad: Start Accession
User->>ad: Trayed?, Media Type, Size Class, Owner
ad->>+as: postAccessionJob
as->>+ax: $api.get {jobId}
isjs->>ax: accession-jobs
ax->>+aj: POST $VITE_INV_SERVCE_API/accession-jobs

aj->>db: SELECT 1 ContainerType
db->>/models/*.py: ContainerType
/models/*.py->>aj: ContainerType
aj->>db: INSERT Workflow
aj->>db: COMMIT
aj->>db: INSERT AccessionJob
aj->>db: COMMIT

aj->>-/schemas/*.py: AccessionJob
/schemas/*.py->>ax: AccessionJob
ax->>-as: AccessionJob
as->>as: accessionJob = {AccessionJob}<br/>originalAccessionJob = {AccessionJob}

ad<<-->>as: accessionJob
ad->>-router: Navigate to /accession/{accessionJob.workflow_id}
router->>acd: render
acd->>User:
```
