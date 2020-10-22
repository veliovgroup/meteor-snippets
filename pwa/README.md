# PWA

This is set of snippets related to implementing PWA coupled with Meteor.js front-end runtime.

## Files

- [`sw-v1.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa/sw-v1.js) — Basic Service Worker for Meteor.js and static files;
- [`setup-service-worker.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa/setup-service-worker.js) — Client/Browser Service Worker registration and control;
- [`reload.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa/reload.js) — Catch when Meteor's client ready to upgrade to the next version.

## Why `sw-v1.js`?

Sadly there are some disadvantages using Service Worker as a static file. After changing code of Service Worker next items got to get updated:

- Increment cache name version inside Service Worker;
- Increment version in the file name;
- Update link to the static file inside `navigator.serviceWorker.register`;
- Manually minify Service Worker file, *if necessary*.

While it looks like a lot of extra-things to do, in fact once you got it stable serving its purpose this file won't have much of the changes. We decided that 4 manual actions doesn't match possible efforts to automate this process. Perhaps 3-5 lines `.sh`ell script can automate at least 2 steps from above :)

## Create static sw.js

Please refer to well documented and annotated [`sw-v1.js` source](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa/sw-v1.js).

### `sw-v1.js` highlights

- `CACHE_NAME` — Increment version to force cache purge on all clients
- `PAGES` — Array with routes and static files which would get pre-cached
- `RE` — Regular expressions:
  - `html` - Used to check if request is for HTML content
  - `method` - Used to check if this is GET request
  - `static` - Static *cacheble* files extensions
  - `staticVendors` - Domain names which serves static content
  - `sockjs` - Path to sockjs endpoint

### Caching logic and strategy

Main caching logic is located in `fetch` event. Caching strategy:

1. Check if request is *cacheble*
2. Check for cached request
2.1. __If request is in the cache__: return cached request and re-validate resource in parallel to updating cache
2.2. __If request isn't found in the cache__: request resource and cache for future use
2.3. __If request is failed__: return "service unavailable" response

### Register ServiceWorker

[This little snippet](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa/setup-service-worker.js) will provide `setUpServiceWorker()` function, example:

```js
import { setUpServiceWorker } from './setup-service-worker.js';

setUpServiceWorker();

// THATS IT! FROM THIS POINT SERVICE WORKER IS REGISTERED
// AND WILL PROXY-CACHE HTTP REQUESTS
```

### Hook with Reload

When Meteor delivers "incremented" upgrade it would reload open window without user's permission. Use `meteor/reload` to intercept this behavior like:

```js
Reload._onMigrate(function (func, opts) {
  if (!opts.immediateMigration) {
    // Returning [false] would prevent window from refreshing
    return [false];
  }
  return [true];
});
```

Use [full `reload.js` snippet](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa/reload.js), here's short example clearing up ServiceWorkers:

```js
import { Reload } from 'meteor/reload';

const onReload = async () => {
  // UNREGISTER ALL ServiceWorkerRegistration(s)
  const swRegistrations = await navigator.serviceWorker.getRegistrations();
  for (let registration of swRegistrations) {
    await registration.unregister();
  }

  // GIVE IT A LITTLE TIME AND RELOAD THE PAGE
  setTimeout(() => {
    if (window.location.hash || window.location.href.endsWith('#')) {
      window.location.reload();
    } else {
      window.location.replace(window.location.href);
    }
  }, 256);
};


// CALL `onReload()` FUNCTION TO CLEAR THE CACHE AND
// UNLOAD/UNREGISTER SERVICE WORKER(S) BEFORE RELOADING THE PAGE
Reload._onMigrate(function (func, opts) {
  if (!opts.immediateMigration) {
    onReload();
    return [false];
  }
  return [true];
});
```
