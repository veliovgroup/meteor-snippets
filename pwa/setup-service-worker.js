/**
 * @locus Client
 */

import { Meteor } from 'meteor/meteor';

/**
 * @function
 * @name setUpServiceWorker
 * @param {boolean} force - Register new service worker ignoring existing controller
 * @summary Register service worker, make sure no duplicate or dead controllers attached
 * @returns {void 0}
 */
const setUpServiceWorker = async (force) => {
  try {
    if ('serviceWorker' in navigator) {
      if (force === true || !navigator.serviceWorker.controller) {
        // window.addEventListener('beforeinstallprompt', () => {
        //   // This is a great place to tell to your UI that
        //   // Service Worker is supported by this browser
        // });

        window.addEventListener('load', async () => {
          try {
            await navigator.serviceWorker.register(Meteor.absoluteUrl('sw-v1.js'));
          } catch (error) {
            console.info('Can\'t load SW');
            console.error(error);
          }
        });
      } else {
        const swRegistration = await navigator.serviceWorker.ready;

        if (!swRegistration) {
          setUpServiceWorker(true);
        }
      }
    }
  } catch (e) {
    // We're good here
    // Just an old browser
  }
};

export { setUpServiceWorker };
