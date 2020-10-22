# Meteor.js: Exact code splitting

How to implement exact code splitting in Meteor.js following PWA principles.

## Files

- [`persistent-reactive.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/exact-code-splitting/persistent-reactive.js) — Hybrid of localStorage and *ReactiveVar*;
- [`promise-method.js`](https://github.com/veliovgroup/meteor-snippets/blob/main/exact-code-splitting/promise-method.js) — Method wrapped into promise.

## Measuring

### Bundle visualizer

To estimate a difference before and after exact code splitting we recommend taking a screenshot running your app with `--production --extra-packages bundle-visualizer` flags.

`bundle-visualizer` package visualize size of the bundle and its components, using this package it's easy to identify rudimentary dependencies and other codebase anomalies. Example:

```shell
meteor --production --extra-packages bundle-visualizer
```

### Network tab

Start your project with `--production` flag, then take a screenshot of "Network" tab in DevTools. Compare total size of all requests, load time, and quantity of requests before and after implementing exact code splitting.

## PWA Principles

> __Progressive enhancement__ is a strategy in web design that puts emphasis on web content first. This strategy involves separating the presentation semantics from the content, with presentation being implemented in one or more optional layers, activated based on aspects of the browser or Internet connection of the user. The proposed benefits of this strategy are that it allows everyone to access the basic content and functionality of a web page, whilst people with additional browser features or faster Internet access receive the enhanced version instead. — [Wiki](https://en.wikipedia.org/wiki/Progressive_enhancement)[pedia](https://en.wikipedia.org/wiki/Progressive_web_application)

This is very complex way to describe that PWA encourages developers to build lightweight and efficient websites. Here we will focus on __progressive enhancement__ in form of __progressively__ pull application's codebase (*yes! on demand*). Taking existing web application and upgrading it to exact code splitting.

## Upgrade routes

I'm using `ostrio:flow-router-extra` as main routing library. If you're using original `flow-router` library, it's backward-compatible, otherwise something similar can get implemented in other routing libraries. To load codebase per route I'm going to move all files static `import`s from application's bundle to route definition. I'm using `waitOn()` hook, which would wait for any promise(s) returned from this hook before calling `action()` hook (*where template is rendered*). Using dynamic `import()` I'm going to make route to wait before all necessary codebase is pulled from server.

```js
FlowRouter.route('/', {
  name: 'index',
  action() {
    this.render('layout', 'index');
  },
  waitOn() {
    return import('/imports/client/index/index.js');
  }
});
```

There's another great hook `whileWaiting()`, which I'm going to use to render "*loading...*" template:

```js
FlowRouter.route('/', {
  name: 'index',
  action() {
    this.render('layout', 'index');
  },
  waitOn() {
    return import('/imports/client/index/index.js');
  },
  whileWaiting() {
    this.render('layout', 'spinner');
  }
});
```

On the other route I need to pull codebase and call Meteor method before rendering template. To wrap Meteor methods into a promise I use a snippet called [`promise-method.js`](), passing data over to Route's context:

```js
const promiseMethod = (name, args, sharedObj, key) => {
  return new Promise((resolve) => {
    Meteor.apply(name, args, (error, result) => {
      if (error) {
        console.error(`[promiseMethod] [${name}]`, error);
        sharedObj[key] = void 0;
      } else {
        sharedObj[key] = result || void 0;
      }
      resolve();
    });
  });
};
```

Using `promiseMethod` with `waitOn()` where Promise or Array of [Promise] can be returned:

```js
FlowRouter.route('/:_id', {
  name: 'file',
  action() {
    this.render('layout', 'file');
  },
  waitOn(params) {
    return [promiseMethod('file.get', [params._id], this.conf, 'file'), import('/imports/client/index/index.js')];
  },
  whileWaiting() {
    this.render('layout', 'spinner');
  }
});
```

`this.conf` is shared object available in all hooks of Route. To pass data from Method to other hooks I'll use `data()` hook:

```js
FlowRouter.route('/:_id', {
  name: 'file',
  action() {
    this.render('layout', 'file');
  },
  waitOn(params) {
    return [promiseMethod('file.get', [params._id], this.conf, 'file'), import('/imports/client/index/index.js')];
  },
  whileWaiting() {
    this.render('layout', 'spinner');
  },
  data(params) {
    return this.conf.file;
  }
});
```

In the case when `file.get` Meteor method returns empty response I'll use `onNoData()` hook which is called when `data()` hook returns `undefined`.

```js
FlowRouter.route('/:_id', {
  name: 'file',
  action(params, qs, file) {
    this.render('layout', 'file', { file });
  },
  waitOn(params) {
    return [promiseMethod('file.get', [params._id], this.conf, 'file'), import('/imports/client/index/index.js')];
  },
  whileWaiting() {
    this.render('layout', 'spinner');
  },
  data(params) {
    return this.conf.file;
  },
  onNoData() {
    this.render('layout', '_404');
  },
});
```

## Persistent Data

Another important PWA principle is offline capabilities. This is partly covered by Meteor core codebase — dynamic `import()`s are cached in IndexedDB. For "recently uploaded" files on the Client I'm using "*local*" MiniMongo collection. The little trick is to update `._name` property:

```js
import { Mongo } from 'meteor/mongo';
import { FilesCollection } from 'meteor/ostrio:files';

// CREATE LOCAL COLLECTION BY PASSING null
const _files = new Mongo.Collection(null);
// SET THE SAME NAME AS ON THE SERVER
_files._name = 'uploadedFiles';

const files = new FilesCollection({
  collection: _files // Pass instance of *Mongo.Collection* to `collection`
});
```

Since we don't need reactive subscription on any of our pages, I'm going to use `file.get` method to get file's *Object* from Mongo. And `.insert()` it to local "persistent" `_files` collection:

```js
Meteor.call('file.get', params._id, (error, file) => {
  !error && _files.insert(file);
});
```

On initial application load I pull data from persistent storage and insert it to local collection to enable UI reactivity:

```js
const recentUploads = _app.persistentReactive('recentUploads', []);
const _recentUploads = recentUploads.get();

if (_recentUploads && _recentUploads.length) {
  _recentUploads.forEach((fileRef) => {
    _files.insert(fileRef);
  });
}
```
