# NPM Dependencies

## Dependency Audit

##### Appropriateness
:heavy_check_mark: Well suited for the purpose it is being used for

:heavy_multiplication_x: Not used, not a production dependency, or not well suited, or has a better alternative

##### Support
:heavy_check_mark: Industry Standard with regular releases and a large community

:heavy_check_mark:\* Dependency is supported but pinned version is out of date

:heavy_multiplication_x: No recent release or no community of users/maintainers

### Production Dependencies

Dependency | Version | Appropriateness | Support |
--- | --- | --- | --- |
@quasar/extras | ^1.16.12 | :heavy_check_mark: | :heavy_check_mark: |
axios | ^1.7.7 | :heavy_check_mark: | :heavy_check_mark: |
dotenv | ^16.4.5 | :heavy_check_mark: | :heavy_check_mark:\* |
jwt-decode | ^4.0.0 | :heavy_check_mark: | :heavy_check_mark: |
moment | ^2.30.1 | :heavy_multiplication_x: | :heavy_multiplication_x: |
node | ^22.10.0 |:heavy_multiplication_x: | | 
npm | ^9.8.1 | :heavy_multiplication_x: | |
pinia | ^2.2.4 | :heavy_check_mark: | :heavy_check_mark:\* |
quasar | ^2.17.1 | :heavy_check_mark: | :heavy_check_mark: |
vue | ^3.5.12 | :heavy_check_mark: | :heavy_check_mark: |
vue-json-excel3 | ^1.0.29 | :heavy_check_mark: | :heavy_check_mark: |
vue-router | ^4.4.5 | :heavy_check_mark: | :heavy_check_mark: | 


## Dependencies Summary

#### The good
Vue + Quasar + Pinia is both a modern and mature stack for building a PWA in 2025.
I have a lot of confidence in these choices.

There are a small number of production dependencies.

#### The ok but notable

@quasar/extras is a package with a lot of useful fonts/icons (and some animations too).
No harm to keeping it but only roboto, material-icons, and mdi is being used.

Dependency versions have been specified using the caret (^) operator.
This [pins the leftmost version number](https://github.com/npm/node-semver?tab=readme-ov-file#caret-ranges-123-025-004) which prevents breaking changes from being installed while still taking security fixes.
For the most part, this is the desired behavior but dependencies _do need_ to be explicitly upgraded at regular intervals to stay up to date.

#### Areas of improvement

The [status of momentjs](https://momentjs.com/docs/#/-project-status/) has been clear for years now.
It should not be used for new projects and should be replaced here.

### Development Dependencies

Dependency | Version | Appropriateness | Support |
--- | --- | --- | --- |
@pinia/testing | "^0.1.6" | :heavy_check_mark: | :heavy_check_mark:\* |
@quasar/app-vite | "^1.10.2" | :heavy_check_mark: | :heavy_check_mark:\* |
@quasar/quasar-app-extension-testing | "^2.1.1" | :heavy_multiplication_x: | |
@quasar/quasar-app-extension-testing-unit-vitest | "^1.1.0" | :heavy_check_mark: | :heavy_check_mark: |
@vue/test-utils | "^2.4.6" | :heavy_check_mark: | :heavy_check_mark: |
autoprefixer | "^10.4.20" | :heavy_check_mark: | :heavy_check_mark: |
eslint | "^8.57.1" | :heavy_check_mark: | :heavy_check_mark:\* |
eslint-plugin-vue | "^9.29.1" | :heavy_check_mark: | :heavy_check_mark:\* |
fake-indexeddb | "^6.0.0" | :heavy_check_mark: | :heavy_check_mark: |
postcss | "^8.4.47" | :heavy_check_mark: | :heavy_check_mark: |
vitest | "^2.1.3" | :heavy_check_mark: | :heavy_check_mark:\* |
workbox-build | "^7.0.0" | :heavy_check_mark: | :heavy_check_mark: |
workbox-cacheable-response | "^7.1.0" | :heavy_check_mark: | :heavy_check_mark: |
workbox-core | "^7.1.0" | :heavy_check_mark: | :heavy_check_mark: |
workbox-expiration | "^7.1.0" | :heavy_check_mark: | :heavy_check_mark: |
workbox-precaching | "^7.1.0" | :heavy_check_mark: | :heavy_check_mark: |
workbox-routing | "^7.1.0" | :heavy_check_mark: | :heavy_check_mark: |
workbox-strategies | "^7.1.0 | :heavy_check_mark: | :heavy_check_mark: |

@quasar/app-vite has a breaking changes at version 2.

#### The good
The standard method for scaffolding a new quasar project was likely used here.
This project has all the standard dev dependencies for working with quasar/vue/vite/pinia/etc...

#### The ok but notable
It's not clear what the steps are to automatically keep a quasar project up to date over time.

#### Areas of improvement
Quaser App Extension Testing has a deprecation notice and should be removed.
