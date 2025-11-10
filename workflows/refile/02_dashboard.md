# Refile Dashboard

Loading the Refile Dashboarg is very similar to the Accession Dashboard.
Many of the same notes apply here.

#### The good

The patterns used here are consistent with Accession Jobs.

The pattern used for refile jobs and refile queue items is consistent.

#### The ok but notable

Options to filter the Refile Queue are not limited to just the values used by items in the Refile queue.

The toggle button explictly calls to load table items rather than keying on a change in value of refileDisplayType.

I don't understand why the filter options are loaded on main page rather than in this component where they are used.

Loading SelectList options is a bit magic and took me awhile to figure out how it was loading.
This is different than how the options were loaded for the filter.

#### Areas of improvement

Because this table displays both the refile jobs and refile queue there is a lot of duplication and ternary operators to determine which to display.
The Essetial Table does a great job at not caring what it is displaying and that should be taken more advantage of.



### Diagram

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant rp as /pages/RefilePage.vue
    participant et as /components/EssentialTable.vue
    participant gs as /stores/global-store.js
    participant rd as /components/Refile/RefileDashboard.vue
    participant rs as /stores/refile-store.js
    participant ax as /boot/axios.js
    participant isjs as /http/InventoryService.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant fp as /filter_params.py
    participant rj as /routers/refile_jobs.py
    participant /models/*.py@{ "type": "collections" }
    participant bs as /routers/sorting.py
    participant db as /app/database/session.py
end
participant fap as fastapi-pagination

User->>+rp: navigate to /refile
rp->>+rd: Render
rd->>rs: resetRefileStore
rd->>rd: loadRefileJobs


rd->>rp: Render
rp->>-User:
rd->>gs: appIsLoadingData = true
gs-->et: :loading = appIsLoading
et->rp: Render Loading Spinner
rp->>User:

rd->>rs: getRefileQueueList
note over rs: See below query workflow
rd->>+rs: getRefileJobList
rs->+ax: $api.get $VITE_INV_SERVCE_API/refile-jobs
ax->isjs:
isjs->>+rj: 
fp->>rj: FilterParams
fp->>rj: SortParams 

rj<<->>bs: sort Query[RefileJob]
rj->>+fap: paginate Query[RefileJob]
fap<<->>db: SELECT FROM RefileJob WHERE params
fap->-/models/*.py: Page[RefileJob]
/models/*.py->>rj:
rj->-/schemas/*.py: Page[RefileJob]
/schemas/*.py->ax:
ax->>-rs:

rs->>rs: refileJobList = Page.items<br/>refileJobListTotal = Page.total
rd->>-gs: appIsLoadingData = false

gs-->et: :loading = appIsLoading
et<<->>rs: refileJobList
et->rp: Render Data
rp->>User:

User->>+et: Sort/Filter/Page
et->>rd: loadRefileJobs params
note over rd: See above query workflow
gs-->et: :loading = appIsLoading
et<<->>rs: refileJobList
et->-rp: Render Data
rp->>User:

User->>+rd: Click "Refile Queue" Toggle
rd->>rd: loadRefileJobs params
note over rd: See above query workflow
deactivate rd
gs-->+et: :loading = appIsLoading
et<<->>rs: refileQueueList
et->-rp: Render Data
rp->>User:
```
