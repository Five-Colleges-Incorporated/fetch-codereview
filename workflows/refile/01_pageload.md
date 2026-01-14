# Refile Page Load

Loading the Refile page is very similar to the Accession Page.
Many of the same notes apply here.

#### The good

The patterns used here are consisent with Accession Jobs.

#### The ok but notable

I still don't understand what a Workflow is or why Accession has one but Refile doesn't.

Sorting of items in a Refile Job is done in python in the web server instead of the database.

Getting the options to filter the Refile queue in this way is too clever.
Instead of having dedicated endpoints it re-uses the existing list endpoints.
Doing it this way doesn't work when there is more than 50 options and it also fetches way more data than is necessary.

#### Areas of improvement

There doesn't appear to be any error handling on page load.
Navigating to a non-existent Refile job hangs indefinitely with no error message.

### Diagram

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant rd as /components/Accession/RefileDashboard.vue
    participant rjd as /components/Accession/RefileJobDetails.vue
    participant gs as /stores/global-store.js
    participant rp as /pages/RefilePage.vue
    participant rs as /stores/refile-store.js
    participant os as /stores/option-store.js
    participant ax as /boot/axios.js
    participant isjs as /http/InventoryService.js
end
box fetch-inventory_service /app
    participant /schemas/*.py@{ "type": "collections" }
    participant rj as /routers/refile_jobs.py
    participant /routers/*.py@{ "type": "collections" }
    participant /models/*.py@{ "type": "collections" }
    participant db as /app/database/session.py
end

User->>+rp: navigate to /refile/{jobId}
rp->>gs: pageInitLoading = true

rect rgba(250, 200, 50, .1)
alt {jobId} != null
    rp->>+rs: getRefileJob({jobId})
    rs->+ax: $api.get $VITE_INV_SERVCE_API/refile-jobs/{jobId}
    ax->isjs: 
    isjs->>+rj: 

    rj->>db: SELECT 1 RefileJob
    db->/models/*.py: RefileJob
    /models/*.py->>rj:
    rj->>rj: sort items
    rj->-/schemas/*.py: RefileJob
    /schemas/*.py->ax: 
    ax->>-rs: 
    rs->>-rs: refileJob = {RefileJob}<br/>originalRefileJob = {RefileJob}
else {jobId} == null
    rect rgba(0, 150, 150, .2)
    loop for optionType in ['mediaTypes', 'users', 'owners', 'sizeClass']
        rp->>+os: getOptions(optionType)
        os->+ax: $api.get $VITE_INV_SERVCE_API/{optionType}
        ax->isjs: 
        isjs->>+/routers/*.py:
        /routers/*.py->>db: SELECT OptionType
        db->/models/*.py: Options
        /models/*.py->>/routers/*.py:
        /routers/*.py->-/schemas/*.py: Page[Options]
        /schemas/*.py->ax: 

        ax->>-os: 
        os->>-os: [{optionType}] = Page[Options]
    end
    end
end
end
rp->>-gs: pageInitLoading = false

gs-->+rp: v-if: !pageInitLoading
rect rgba(250, 200, 50, .1)
alt {jobId} == null
    rp->rd: Render
    rd->>User:
else {jobId} != null
    rp->rjd: Render
    rjd->>User:
    deactivate rp
end
end
```
