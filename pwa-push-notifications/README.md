# PWA: Web Push Notifications

This is set of snippets related to implementing PWA with Web Push Notifications coupled with Meteor.js front-end runtime.

## Files

- [`sw.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/sw-v2.js) — Service Worker with listeners for Web Push Notifications events;
- [`reload.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/reload.js) — Reload Service Worker and purge cache inside Hot Code Push (HCP) event;
- [`setup-service-worker.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/setup-service-worker.js) — Client/Browser Service Worker registration and control;
- [`web-push.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/web-push.js) — Push Notifications *Client* helper
- [`web-push-server.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/web-push-server.js) — Push Web Notifications from *Server* helper
- [`settings.json`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/settings.json) — Updated `settings.json` with VAPID settings for Web Push Notifications

## Goals

1. Send push-notification to supported browsers from the sever
2. Pass PN subscription details to the "long running" Meteor.Methods to notify user once the task is ready (*see example below*)

## Dependencies

To push messages from server use [`web-push`](npmjs.com/package/web-push) NPM package. It has very simple usage, see production implementation in [`web-push-server.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/web-push-server.js).

## Changes

Incremental changes applied to the files originally created in [PWA tutorial](https://github.com/veliovgroup/meteor-snippets/tree/main/pwa):

- Enable PNs from Service Worker `activate` event
- Listen for `webPush.enable` event in the Main thread
- Listen for Service Worker `notificationclick` event
- Enable push notifications in the Main thread after `load` event is fired on the `window`

### Changes in Service Worker

Send `webPush.enable` event to the main-thread window inside `activate` event:

```js
self.addEventListener('activate', async (event) => {
  /* ... */

  // GET OPEN WINDOWS ACCOCIATED WITH THIS SERVICE WORKER
  const availClients = await self.clients.matchAll({
    includeUncontrolled: false,
    type: 'window'
  });

  // USE ONLY FIST AVAILABALE WINDOW
  // TO ACTIVATE WEB-PUSH NOTIFICATIONS
  const client = availClients[0];
  if (client) {
    client.postMessage({
      action: 'webPush.enable'
    });
  }
});
```

Listen for `notificationclick`

```js
self.addEventListener('notificationclick', async (event) => {
  // CLOSE/HIDE NOTIFICATION BOX
  event.notification.close();
  // DISMISS IF USER CLICKED ON [dismiss]
  if (event.action !== 'dismiss') {
    // GET MAIN-THREAD WINDOW(S)
    event.waitUntil(self.clients.matchAll({
      includeUncontrolled: false,
      type: 'window'
    }).then(async (availClients) => {
      // GET OPENED WINDOWS, GRAB THE FIRST ONE
      const client = availClients[0];
      if (client && 'focus' in client) {
        if (!client.focused) {
          // GET WINDOW INTO THE FOCUS
          await client.focus();
        }

        // SEND `openRoute` EVENT TO THE MAIN-THREAD
        client.postMessage({
          action: 'openRoute',
          url: event.notification.data.url
        });
      } else if ('openWindow' in self.clients) {
        // OPEN NEW WINDOW IF NONE IS OPEN ATM
        self.clients.openWindow(event.notification.data.url);
      }
    }));
  }
});
```

### Changes in the main-thread script

Add `message` listener to open routes when notification is clicked and enable Web Push Notifications after `activate` event in the Service Worker:

```js
navigator.serviceWorker.addEventListener('message', (event) => {
  if (event.data.action === 'openRoute' && event.data.url) {
    FlowRouter.go(event.data.url);
  } else if ('PushManager' in window && event.data.action === 'webPush.enable') {
    webPush.enable();
  }
}, false);
```

Check/Ensure Web Push Notifications are enabled after Service Worker is loaded:

```js
import { webPush } from './web-push.js';

window.addEventListener('load', () => {
  /* ... */

  // ENSURE PNs RIGHT AFTER PAGE IS FULLY LOADED
  if ('PushManager' in window) {
    webPush.check();
  }
});
```

## WebPush on Client

To check and enable Web Push Notifications we created [`web-push.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/web-push.js) helper. `webPush` object methods and properties:

- `.isSupported` {*Boolean*} — `true` if Web Push Notifications API enabled and available in this browser
- `.isEnabled` {*Boolean*} — `true` if Web Push Notifications are enabled and permitted by user
- `.subscription` {*String*|*void 0*} — Subscription object as a string. This should be sent to server. If `.subscription` property is undefined that means browser not subscribed for PNs or user declined PNs in permissions, check `.isEnabled` property
- `.check()` {*Promise*} — Check and ensure PNs activated on the browser. *Promise* resolved to {*Boolean*} value, `true` if action was successful
- `.enable()` {*Promise*} — Enable/Subscribe to Push Notifications. Set `.subscription` property. *Promise* resolved to {*Boolean*} value, `true` if action was successful
- `.disable()` {*Promise*} — Disable/Unsubscribe from Push Notifications. *Promise* resolved to {*Boolean*} value, `true` if action was successful

## WebPush on Server

- [`web-push-server.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/web-push-server.js) — Push Web Notifications from *Server*. `webPush` object methods and properties:
  - `.send(subscription, messageObj)`
    - `subscription` {*String*} — Object as a string, from `ServiceWorkerRegistration#pushManager.getSubscription()`
    - `messageObj` {*Object*} — Message body as plain-object
      - `messageObj.data.url` {*String*} — URL to follow by clicking on Notification box
      - `messageObj.title` {*String*} - Notification title
      - `messageObj.body` {*String*} - Notification body
      - `messageObj.icon` {*String*} - URL to the image
      - `messageObj.badge` {*String*} - URL to the image
      - [see all available options](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/web-push-server.js#L15)

## Vapid settings

- [`settings.json`](https://github.com/veliovgroup/meteor-snippets/blob/main/pwa-push-notifications/settings.json):
  - `vapid` {*Object*}
  - `vapid.email` {*String*} — Tech support email address, example `mailto:webmaster@example.com`;
  - `vapid.privateKey` {*String*} — The value generated by `webpush.generateVAPIDKeys().privateKey`, private key should be generated only once per each application, and remain the same in the future;
  - `public.vapid.publicKey` {*String*} — The value generated by `webpush.generateVAPIDKeys().publicKey`, public key should be generated only once per each application, and remain the same in the future;

## Sending Push Notification from server

Load files and setup service worker:

```js
import { setUpServiceWorker } from './setup-service-worker.js';
import './reload.js';

setUpServiceWorker();
```

After PNs are enabled inside `setUpServiceWorker()` function use `webPush.isEnabled` to check that PN supported and user granted its usage. If PNs are enabled grab `webPush.subscription` and send to the server (*or write to database*):

```js
import { webPush } from './web-push.js';

const data = { /* data to be sent to the server via method */ }

if (webPush.isEnabled && webPush.subscription) {
  data.pnSubscription = webPush.subscription;
}

Meteor.call('slow-method', data, () => {
  /* ... */
});
```

Then, on a *Server* inside method send PN after async task is finished:

```js
import { webPush } from './web-push-server.js';

Meteor.methods({
  'slow-method'(data) {
    callSlowAsyncTask(data, (error) => {
      const notification = {
        data: {
          url: '/' // <-- This URL will be opened after user clicked on Notification
        },
        title: 'Operation completed',
        body: 'Successfully performed. Click to view',
      };

      if (error) {
        notification.title = 'Operation failed';
        notification.body = 'Method ended up with an error. Click to view';
      }

      if (data.pnSubscription) {
        webPush.send(data.pnSubscription, notification);
      }
    });
  }
});
```
