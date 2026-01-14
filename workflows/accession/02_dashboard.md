# Accession Dashboard

#### The good

Using a python library for paging results.

Using the quasar table library inside an EssentialTable component enforcing consistency.
Pagination filtering is implemented according to Quasar docs.

#### The ok but notable

Not awaiting async method in onBeforeMount.
This is fine but surprising.

Imported names are similar but come from different sources. For example:
* resetAccessionStore (method on store)
* loadAccessionJobs (method in dashboard)

The filter -> sql conversion is done by hand rather than some sort of libary.
RSQL or OData are two standards.

Confusing naming with 'update-pagination' being emitted from the @request handler.
This is the appropriate usage of @request but it isn't immediately clear why the event is 'update-pagination'.
Same confusion with 'pagination-is-loading' meaning just fetching data.

Using an apparent private? property __thClass of Quasar.
I don't know if there's a better way to make it accessible like it's doing without it though?
I would like to see a comment here explaining what is going on.

#### Areas of improvement

:enable-table-reorder defaults to false, is passed as false in a lot of places.
Is never passed as true. What does it do and why is it here adding complication?

:heading-row-class is subtly different in some places but the same in many others.
Why is this configurable and required to be passed?

:heading-filter-class is the same everywhere (but not passed in).

### Diagram

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant ap as /pages/AccessionPage.vue
    participant et as /components/EssentialTable.vue
    participant gs as /stores/global-store.js
    participant ad as /components/Accession/AccessionDashboard.vue
    participant as as /stores/accession-store.js
    participant isjs as /http/InventoryService.js
    participant ax as /boot/axios.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant fp as /filter_params.py
    participant aj as /routers/accession_jobs.py
    participant /models/*.py@{ "type": "collections" }
    participant bs as /routers/sorting.py
    participant db as /app/database/session.py
end
participant fap as fastapi-pagination

User->>+ap: navigate to /accession
ap->>+ad: Render
ad->>as: resetAccessionStore
ad->>ad: loadAccessionJobs
ad->>et: Render
et->>ap: Render Loading Spinner
ad->>ap:
ap->>-User:
ad->>gs: appIsLoadingData = true

ad->>as: getAccessionJobList
as->>+ax: $api.get params
isjs->>ax: accession-jobs
ax->>+aj: $VITE_INV_SERVCE_API/accession-jobs?params
fp->>aj: FilterParams
fp->>aj: SortParams 

aj<<->>bs: sort Query[AccessionJob]
aj->>+fap: paginate Query[AccessionJob]
fap<<->>db: SELECT FROM AccessionJob WHERE params
fap->>-/models/*.py: Page[AccessionJob]
/models/*.py->>aj: Page[AccessionJob]
aj->>-/schemas/*.py: Page[AccessionJob]
/schemas/*.py->>ax: Page[AccessionJobListOutput]
ax->>-as: Page[AccessionJobListOutput]

as->>as: accessionJobList = Page.items<br/>accessionJobListTotal = Page.total
ad->>-gs: appIsLoadingData = false

gs-->et: :loading = appIsLoading
et<<->>as: accessionJobList
et->>ap: Render Data
ap->>User:

User->>+et: Sort/Filter/Page
et->>ad: loadAccessionJobs params
note over ad: See above query workflow
gs-->et: :loading = appIsLoading
et<<->>as: accessionJobList
et->>-ap: Render Data
ap->>User:
```
