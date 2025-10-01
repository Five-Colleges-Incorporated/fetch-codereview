# Routing

Initial navigations to the FETCH website, and subsequent internal navigations are implemented by [Vue Router](https://router.vuejs.org/), the official router for vue.js.

The router, as currently implemented performs two checks before routing the user.
1. Is there offline information that is waiting to be synced?
1. Does the user have permissions to view the page.

These checks happen on every single navigation, the full workflow is documented in the below diagram.

### Code Review

The router workflow looks ok from a best practices and maintainability standpoint.
There are minor inconsistencies and improvements but nothing structural.

#### The good

The global [navigation guard pattern](https://router.vuejs.org/guide/advanced/navigation-guards) appears to be idiomatic to Vue Router.
Additionally, it is not using the `next` parameter which is slated to be removed.

#### The ok but notable
There is an inconsistency in how the appSyncGuard and appRouteGuard are handled. One uses `v-if` and the other uses vue's `watch` method.
I believe this inconsistency is due to the different between displaying a modal and displaying a toast. This is minor and does not impact maintainability.

On route, it is hardcoded that the screen position resets back to the top left.
This isn't bad but would be surprising to a developer working on new pages because it is tucked in a place that otherwise does not deal with layouts.

There's mention of a link between router/index.js and quasar.conf.js.
The quasar.config.js does not have reciprocal note linking back to index.js

The useGlobalStore does not have jsdoc for the properties leaving the developer to guess by name and usage the purpose and type of the properties.

#### Areas of Improvement
Using an [In-Component guard's beforeRouteLeave option](https://router.vuejs.org/guide/advanced/navigation-guards#In-Component-Guards) may be more appropriate for guarding against leaving a page with an offline sync.

Using [`inject` for pinia stores](https://router.vuejs.org/guide/advanced/navigation-guards#Global-injections-within-guards) is mentioned in the docs but the global store is directly resolved in the router.
This warrants further investigation.

The user permissions are grabbed straight out of localStorage. A store backed by localStorage using pinia native features would be more appropriate.

While the Navigation Bar is a very global component it might not be the best home for displaying global banners/confirmations/notifications which are unrelated to the layout of the navigation bar.

### Further investigations

* How does appPendingSync get set?
* How are user permissions set in localStorage
* Double check that permission are also enforced server-side
* Best practices around provide/inject and pinia stores

### Diagram

```mermaid
sequenceDiagram
actor User
box fetch-vue repository /src
    participant /pages/*.vue@{ "type": "collections" }
    participant nav as /components/NavigationBar.vue
    participant gs as /stores/global-store.js
    participant sync as /composables/useBackgroundSyncHandler.js
    participant router as /router/index.js
    participant routes as /router/routes.js
end

User->>+router: navigate to {route}
router<<->>gs: appPendingSync?
rect rgba(250, 200, 50, .1)
alt Is Offline Syncing
    router->>-gs: appSyncGuard = {route}
    gs-->+nav: v-if: appSyncGuard
    nav<<->>User: Modal: "Leave w/ Pending Requests?"
    rect rgba(0, 150, 150, .2)
    alt Cancel
        nav->>gs: appSyncGuard = null
        nav-x-User:stop navigation
    else Yes, Ignore Requests
        activate nav
        nav<<->>gs: {route} = appSyncGuard
        nav->>gs: appSyncGuard = null<br/>appPendingSync = false
        nav->>sync: deleteDataInBackgroundSyncDb
        nav->>+router: navigate to {route}
        deactivate nav
    end
    end
else Not Offline Syncing
    router<<->>routes: meta.requiresAuth<br/>meta.requiresPerm
    rect rgba(0, 150, 150, .2)
    alt Not Logged In / Not Permitted
        router->>gs: appRouteGuard = {route}
        rect rgba(150, 0, 150, .1)
        alt Has Current Page
            router-xUser:stop navigation
        else No Current Page
            router->>-/pages/*.vue: render /home
            /pages/*.vue->>User:
        end
        end
        gs-->+nav: watch(appRouteGuard)
        nav<<->>gs: {route} = appRouteGuard
        nav->>User: Toast: "Sorry, you do not have permission to view the {route} page!"
        nav->>-gs: appRouteGuard = null
    else Logged In/ Has Permission
        activate router
        router->>/pages/*.vue: render {route}
        /pages/*.vue->>User:
        deactivate router
    end
    end
end
end
```
