angular.module('Directory.searches.controllers', ['Directory.loader', 'Directory.searches.models', 'Directory.searches.filters', 'Directory.collections.models', 'prxSearch'])
.controller('SearchCtrl', ['$scope', '$location', 'Query', function ($scope, $location, Query) {
  $scope.location = $location;
  $scope.$watch('location.search().query', function (search) {
    $scope.query = new Query(search);
  });
}])
.controller('GlobalSearchCtrl', ['$scope', 'Query', '$location', function ($scope, Query, $location) {
  $scope.query = new Query();
  $scope.go = function () {
    $location.path('/search');
    $scope.query.commit();
    $scope.query = new Query();
  }
}])
.controller('SearchResultsCtrl', ['$scope', 'Search', 'Loader', '$location', '$routeParams', 'Query', 'Collection', 'SearchResults', function ($scope, Search, Loader, $location, $routeParams, Query, Collection, SearchResults) {
  $scope.location = $location;
  
  $scope.$watch('location.search().query', function (searchquery) {
    $scope.query = new Query(searchquery);
    fetchPage();
  });

  $scope.$watch('location.search().page', function (page) {
    fetchPage();
  });

  $scope.$on("datasetChanged", function () {
    fetchPage();
  });

  $scope.nextPage = function () {
    $location.search('page', (parseInt($location.search().page) || 1) + 1);
    fetchPage();
  }

  $scope.backPage = function () {
    $location.search('page', (parseInt($location.search().page) || 2) - 1);
    fetchPage();
  }

  $scope.addSearchFilter = function (filter) {
    $scope.query.add(filter.field+":"+'"'+filter.valueForQuerying()+'"');
  }

  function fetchPage () {
    searchParams = {};

    if ($routeParams.contributorName) {
      searchParams['filters[contributor]'] = $routeParams.contributorName;
    }

    if (typeof $routeParams.collectionId !== 'undefined') {
      searchParams['filters[collection_id]'] = $routeParams.collectionId;
    }

    if ($scope.query) {
      searchParams.query = $scope.query.toSearchQuery();
    }
    searchParams.page = $location.search().page;

    if (!$scope.search) {
      $scope.search = Loader.page(Search.query(searchParams));
    } else {
      Loader(Search.query(searchParams), $scope);
    }

    $scope.$watch('search', function (search) {
      SearchResults.setResults(search);
    });
  }
}]);