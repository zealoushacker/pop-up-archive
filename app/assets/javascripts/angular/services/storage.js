angular.module('Directory.storage', [])
.factory('Storage', [ '$rootScope', function ($rootScope) {

  var Storage = {};

  Storage.storageClass = function (storage) {
    if (!storage) {
      return '';
    }
    var s = angular.lowercase(storage) || "aws";
    return ('storage-' + s);
  };

  return Storage;

}]);
