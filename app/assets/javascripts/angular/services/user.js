angular.module('Directory.user', ['Directory.loader', 'Directory.users.models'])
.factory('Me', ['$q', '$timeout', 'Loader', 'User', '$rootScope', function ($q, $timeout, Loader, User, $rootScope) {
  var currentUser;
  var authenticatedParams = [];

  var Me = Loader(User.get('me')).then( function (user) {
    currentUser = user;
    $rootScope.currentUser = user;

    var authArgsArray;
    while (authArgsArray = authenticatedParams.pop()) {
      Me.authenticated.apply(Me, authArgsArray);
    }

    return currentUser;
  });

  Me.authenticated = function () {
    var argsArray = Array.prototype.slice.call(arguments);
    if (currentUser) {
      currentUser.authenticated.apply(currentUser, argsArray);
      mixpanel.identify(currentUser.email);
    } else {
      authenticatedParams.push(argsArray);
    }
  }

  return Me;
}]);
