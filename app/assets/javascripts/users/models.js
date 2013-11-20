angular.module('Directory.users.models', ['RailsModel'])
.factory('CreditCard', ['Model', function (Model) {
  var CreditCard = Model({url:'/api/me/credit_card', name: 'credit_card'});
  return CreditCard;
}])
.factory('Subscription', ['Model', function (Model) {
  var Subscription = Model({url:'/api/me/subscription', name: 'subscription'});
  return Subscription;
}])
.factory('User', ['Model', 'CreditCard', 'Subscription', function (Model, CreditCard, Subscription) {
  var User = Model({url:'/api/users', name: 'user'});

  User.prototype.authenticated = function (callback, errback) {
    var self = this;
    if (self.id) {
      if (callback) {
        callback(self);
      }

      return true;
    }

    if (errback) {
      errback(self);
    }
    
    return false;
  };

  User.prototype.canEdit = function (obj) {
    if (this.authenticated() && obj && obj.collectionId) {
      return (this.collectionIds.indexOf(obj.collectionId) > -1);
    } else {
      return false;
    }
  };

  User.prototype.isAdmin = function () {
    if (this.authenticated()) {
      return (this.role == 'admin');
    } else {
      return false;
    }
  };

  User.prototype.updateCreditCard = function (stripeToken) {
    var cc = new CreditCard({token: stripeToken});
    return cc.update().then(function () {
      return User.get('me');
    });
  };

  User.prototype.hasCreditCard = function () {
    return !!this.creditCard;
  };

  User.prototype.subscribe = function (planId, offerCode) {
    var sub = new Subscription({planId: planId});
    var self = this;
    if (typeof offerCode !== 'undefined') {
      sub.offer = offerCode;
    }
    return sub.update().then(function (plan) {
      self.plan.id = plan.id;
      self.plan.amount = plan.amount;
      self.plan.popUpHours = plan.hours;
      self.plan.interval = plan.interval;
      return User.get('me');
    });
  };

  return User;
}])
