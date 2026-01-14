# Background Worker

#### The good

The documentation for making quasar pwa seems to have been followed.

#### The ok but notable

The quasar.conf.js specifies a lot of options for the pwa that are the same as the default.

Instead of using versioning for the indexedDBs the service worker deletes the database on upgrade.

Pre-caching doesn't seem to cache the whole site. (only icons??)
For example, if I've never visited the Accession Page I can't view it when offline.
This is an issue even after going back online until the pwa is refreshed.
Obviously the data can't be displayed but there is no indication to the user that the page can't be navigated to.
Once, I visit it the data and page are cached.

It is strange how the workbox-routing caching interacts with the data in indexedDB.
On some pages the data is entirely provided by the workbox-routing cache.
But refile and shelving both seem to implement their own indexedDB cache.

There's test code in the service workers that is shipped to production.

#### Areas of improvement

Navigating between refile jobs without internet doesn't load up the new job (obviously).
But it appears like it has and just displays the items from the previous job.
Turning back on internet after navigation completed the wrong job.

The register-service-worker package is an implicit dependency despite being used directly.

### Queueable Calls

* Pause/Resume shelving job
* Reassign (proposed) container location during shelving job
* Pause/Resume picklist job
* Return picklist item to queue
* Scanning a Item during picklist job
* Pause/Resume refile job
* Return refile item to queue
* Scanning a Item during refile job

### Diagram
```mermaid
sequenceDiagram
participant is as Inventory Service
box browser
    participant cache as Cache
    participant idb as IndexedDb
    participant offlineQueue@{ "type" : "queue" }
end
box ServiceWorker
    participant wbs as workbox-strategies
    participant wbbg as workbox-background-sync
    participant csw as custom-service-worker.js
end
box Application
    participant nav as /components/NavigationBar.vue
    participant gs as /stores/global-store.js
    participant ax as /boot/axios.js
    participant *.js@{ "type": "collections" }
    participant rswlib as register-service-worker<br/>package
    participant rsw as register-service-worker.js
end


rect rgba(250, 200, 50, .1)
    rsw->rswlib: Register Service worker
    rswlib->>+csw:
    csw->wbbg: Create Queue offlineQueue
    wbbg->>offlineQueue: 
end

rect rgba(250, 200, 50, .1)
    rswlib->>+rsw: 'updated'
    rsw->>idb: Delete workbox-background-sync db
    rect rgba(0, 150, 150, .2)
    par
        rsw--)csw: 'forceRefreshServiceWorker'
        note over csw: Activate new worker
    and
        note over rsw: Refresh Page 
    end
    end
end

rect rgba(250, 200, 50, .1)
    note over *.js: User takes an action on a Job
    activate *.js
    *.js-->>csw: 'queueIncomingApiCall' {toQueue}
    *.js->>+ax: $api.{method} {route}
    ax-->>+csw:
    rect rgba(0, 150, 150, .2)
    alt offline and {toQueue} == {route}
        csw->>offlineQueue: queue {method} {route}
        offlineQueue->>idb: Store in<br/>workbox-background-sync db
        csw-->>nav: 'refreshWhenOnline'
    else online or {toQueue} != {route}
        rect rgba(150, 0, 150, .1)
        alt {method} == GET
            csw->>+wbs: NetworkFirst {route}
            wbs<<->>is: Try GET {route}
            wbs<<->>cache: Store/Retrieve {route}
            wbs->>-csw:
        else {method} != GET
            csw<<->>is: {method} {route}
        end
        end
    end
    end
    csw->-ax: Response
    ax->>-*.js:
    deactivate *.js
end

rect rgba(250, 200, 50, .1)
    note over nav: User Clicks "Send Requests"
    nav-->>+csw: 'triggerBackgroundSync'
    csw<<->>offlineQueue: requests
    rect rgba(0, 150, 150, .2)
    loop for req in requests
        csw<<->>is: {method} {route}
        rect rgba(150, 0, 150, .1)
        alt 500 Internal Server Error:
            csw->>offlineQueue: queue {method} {route} for retry
        else ok
            note over csw: Send {route} to "Test" page
        end
        end
    end
    end
    csw-->>-nav: 'sync complete'
end

deactivate csw
```
