import { Meteor } from 'meteor/meteor';

const promiseMethod = (name, args) => {
  return new Promise((resolve, reject) => {
    Meteor.apply(name, args, (error, result) => {
      if (error) {
        reject(error);
      } else {
        resolve(result);
      }
    });
  });
};

export { promiseMethod };
