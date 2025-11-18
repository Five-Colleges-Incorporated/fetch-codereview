# Offline Refile

> Older sections of the repository do not have wifi, airplane mode gets activated
> The device shows refiling was succesful but syncing would fail back on wifi.
> This is catastrophic because that data is lost and the job has to be redone.
> This only happens with refile even though shelving also goes offline.

## Investigation

registerIndexDb is called whenever the useIndexDbHandler is used.
This relies upon an internal `indexDb` variable that doesn't appear to be saved anywhere?
An indexedDB is opened **without a version** and then `createObjectStore` is called for each of the stores (ownerTiers, shelving, picklist, refile).
It defaults to version 1 and so the 'global-data' will in theory be created only once.

After messing with Refile jobs offline the indexDb doesn't seem to have anything to do with the offline syncing.
It all comes down to workbox-background-sync.

I thought I made a breakthrough!
In MainLayout, every 8 hours the background worker is refreshed and the indexedDB databases are cleared.
This explicitly skips clearing out the request queue which I missed...
