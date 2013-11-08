angular.module('Directory.csvImport.controllers', ['fileButton', 'Directory.alerts', 'Directory.csvImports.models', 'Directory.collections.models', 'Directory.loader', 'Directory.csvImports.filters'])
.controller("ImportCtrl", ['$scope', 'CsvImport', '$routeParams', 'Collection', 'Loader', function($scope, CsvImport, $routeParams, Collection, Loader) {

  Loader.page(CsvImport.get($routeParams.importId), Collection.query(), 'importEdit-'+$routeParams.importId, $scope).then(function (data) {
    var existingGroup = 'Or use an existing collection';
    angular.forEach($scope.collections, function forEachHeader (c, index) { c.grouping = existingGroup; });

    var newGroup = "Create a new '" + $scope.csvImport.file + "' collection";
    $scope.collections = [
      { id:  0, title: "New Private Collection",          grouping: newGroup },
      { id: -1, title: "New Public Collection",           grouping: newGroup },
      { id: -2, title: "New Internet Archive Collection", grouping: newGroup }
    ].concat($scope.collections);
  });

  $scope.getNewPreviewRows = function getNewPreviewRows () {
     CsvImport.get($scope.csvImport.id).then(function(data) {
      $scope.csvImport.previewRows = data.previewRows;
     });
  }

  $scope.save = function save () {
    $scope.csvImport.update();
  }

}])
.controller("ImportMappingCtrl", ['$scope', 'Schema', 'Alert', 'MappingSet', '$location', function ($scope, Schema, Alert, MappingSet, $location) {
  $scope.schema = Schema.get();

  $scope.parseNestedQuery = window.parseNestedQuery;

  $scope.mappingSet = new MappingSet();

  $scope.submitMapping = function submitMapping () {
    var i = $scope.csvImport;
    i.commit = 'import';
    i.update();
    var alert = new Alert({status:"Submitting", message:i.file, progress:1, sync: i.alertSync()});
    alert.i = i;
    alert.add();
    $location.path('/imports');
  }

  $scope.$watch('csvImport.headers', function watchImportHeaders (headers) {
    angular.forEach(headers, function forEachHeader (header, index) {
      $scope.$watch('mappingSet.mappingAsArry['+index+']', function (columnName, was) {
        if (columnName) {
          $scope.csvImport.mappings[index].column = columnName;
        } else if (was) {
          $scope.csvImport.resetMappingToExtra(index);
        }
      });
      $scope.$watch('csvImport.mappings['+index+'].column', function watchMappingColumn (columnName) {
          if (columnName) {
            var type, column = $scope.schema.columnByName(columnName);
            $scope.mappingSet.set(index, columnName);
            if (column) {
              type = $scope.schema.types.get(column.typeId);
              $scope.csvImport.mappings[index].type = type.name;
            }
          }
        });
        $scope.$watch('csvImport.mappings['+index+'].type', function watchMappingType (typeName) {
          if (typeName) {
            var column = $scope.schema.columnByName($scope.csvImport.mappings[index].column);
            if (column && $scope.schema.types.get(column.typeId).name != typeName) {
              $scope.csvImport.mappings[index].column = undefined;
            }
          }
        });
    });
  });
}])
.controller('AlertCtrl', ['$scope', 'Alert', '$timeout', function ($scope, Alert, $timeout) {
  $scope.alertData = {};
  $scope.alertData.alerts = Alert.getAlerts();

  $scope.dismissIfDone = function(alert) {
    $scope.forceAlertsShow = false;
    if (alert.path || alert.done) {
      alert.dismiss();
    }
  }

  // Wrap that method up - middleware style
  var oldAddAlert = Alert.prototype.add;
  Alert.prototype.add = function () {
    $("#alerts-container").addClass("open");
    $scope.forceAlertsShow = true;
    $timeout(function () { $scope.forceAlertsShow = false }, 2000);
    return oldAddAlert.call(this);
  }
}])
.controller('ImportsCtrl', ['$scope', 'CsvImport', 'Loader', function ($scope, CsvImport, Loader) {
  Loader.page(CsvImport.query(), 'Imports', $scope);
}])
.controller('FSImportCtrl', ['$scope', '$http', 'CsvImport', '$timeout', 'Alert', function ($scope, $http, CsvImport, $timeout, Alert) {

  $scope.setFiles = function(element) {
    $scope.$apply(function($scope) {
      angular.forEach(element[0].files, function (file) {
        $scope.files.push(file);
      });
    });
  };

  $scope.submit = function () {
    angular.forEach($scope.files, function(file) {
      var alert = new Alert();
      alert.category = 'upload';
      alert.status = "Uploading";
      alert.progress = 1;
      alert.message = file.name;
      alert.add();

      var fData = new FormData();
      fData.append('csv_import[file]', file);

      $http({
        method: 'POST',
        url: '/api/csv_imports',
        data: fData,
        headers: { "Content-Type": undefined },
        transformRequest: angular.identity
      }).success(function(data, status, headers, config) {
        var csvImport = new CsvImport({id:data.id});
        alert.progress = 25;
        alert.status = "Waiting";
        alert.startSync(csvImport.alertSync());
      });
    });
  };
}]);
