angular.module('Directory.alerts', ['ngLoadingIndicators'])
.factory('Alert', ['$rootScope', '$timeout', 'loading', function ($rootScope, $timeout, loading) {

  var alerts = [];

  function schedulePeriodicUpdate (alert) {
      alert.$timeout = $timeout(function () {
      alert.sync(alert).then(function (arg) {
        if (!(alert.done || alert.path || alert.progress == 100)){
          schedulePeriodicUpdate(alert);
        } else {
          $rootScope.$broadcast('alertEnded', alert);
          loading(false);
        }
        return arg;
      });
    }, 500);
  }

  function makeSyncWrapper (syncSpec) {
    var pArgument = syncSpec.promise;
    var pReceiver = pArgument.splice(0, 1)[0];
    var pFunction = pArgument.splice(0, 1)[0];
    return function (alert) {
      return Function.prototype.apply.call(pFunction, pReceiver, pArgument).then(function (object) {
        angular.forEach(syncSpec, function (hash, attribute) {
          if (attribute != 'promise'){
            angular.forEach(hash, function (options, value) {
              if (object[attribute] == value) {
                angular.forEach(options, function (alertValue, alertKey) {
                  if (typeof alertValue === 'string') {
                    alertValue = alertValue.replace(/\:(\w+)/g, function(m) {
                      return object[m.replace(':','')];
                    });
                  }
                  alert[alertKey] = alertValue;
                });
              }
            });
          }
        });
        return object;
      });
    }
  }

  function Alert(data) {
    data = (data || {});
    this.category = data.category;
    this.status   = data.status;
    this.message  = data.message;
    this.path     = data.path;
    this.done     = data.done;
    this.progress = data.progress;
    this.sync     = data.sync;
  }

  Alert.prototype = {
    add: function () {
      alerts.push(this);
      this.startSync();
    },

    isComplete: function () {
      var alert = this;
      return (alert.done || parseInt(alert.progress, 10) >= 100);
    },

    startSync: function (sync) {
      var promise;
      this.sync = (sync || this.sync);
      if (typeof this.sync == 'function') {
        promise = this.sync(this);
        if (promise && typeof promise.then == 'function') {
          loading(true);
          schedulePeriodicUpdate(this);
        }
      } else if (typeof this.sync == 'object') {
        this.startSync(makeSyncWrapper(this.sync));
      }
    },
    
    dismiss: function () {
      if (this.$timeout && typeof this.$timeout.cancel == 'function'){
        this.$timeout.cancel();
      }
      alerts.splice(alerts.indexOf(this), 1);
    }
  }

  Alert.add = function(alert) {
    var newAlert = new Alert(alert);
    alert.add();
    return alert;
  }

  Alert.getAlerts = function() {
    return alerts;
  }

  return Alert;
}]).directive('popUpAlertsDropdown', ['$parse', '$compile', function($parse, $compile) {

  var template = '' +
  '<ul class="dropdown-menu alert-showers pull-right" role="menu" aria-labelledby="alerts-dropdown" ng-hide="alerts.length == 0">' +
    '<li class="alert-shower" ng-repeat="alert in alerts" ng-class="{pending:!(alert.done)}">' +
      '<a class="pull-right dismiss" ng-click="alert.dismiss(); $event.stopPropagation()" ><i class="icon-remove-circle"></i></a></br>' +
      '<a ng-href="{{alert.path}}">' +
          '<div class="message">' +
            '<span class="status">{{alert.status}}:</span> {{alert.message}}' +
          '</div>' +
          '<div class="progress progress-striped" ng-class="{active:alert.progress && alert.progress < 100}">' +
            '<div class="bar" ng-style="{width:alert.progress+\'%\'}"></div>' +
          '</div>' +
      '</a>' +
    '</li>' +
  '<ul>';

  return {
    restrict: 'A',
    scope: true,
    link: function postLink(scope, element, attr) {

      var getter = $parse(attr.popUpAlertsDropdown);

      scope.alerts = getter(scope);
      var dropdown = $compile(template)(scope);
      dropdown.insertAfter(element);

      element
        .addClass('dropdown-toggle')
        .attr('data-toggle', "dropdown");
    
    }
  };

}]);
