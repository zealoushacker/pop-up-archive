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
.controller('SearchResultsCtrl', ['$scope', 'Search', 'Loader', '$location', '$routeParams', 'Query', 'Collection', 'SearchResults', '$http', function ($scope, Search, Loader, $location, $routeParams, Query, Collection, SearchResults, $http) {
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
    $location.path('/search');
    $scope.query.add(filter.field+":"+'"'+filter.valueForQuerying()+'"');
  }
  
  $scope.termSearch = function (args) {
    $location.path('/search');
    $scope.query.add(args.field+":"+'"'+args.term+'"');
  };
  
  $scope.sortOptions = [{name: "Relevancy", sort_by: "_score", sort_order: "desc"},
                        {name: "Newest Added to Oldest Added", sort_by: "date_added", sort_order: "desc"}, 
                        {name: "Oldest Added to Newest Added", sort_by: "date_added", sort_order: "asc"},
                        {name: "Newest Created to Oldest Created", sort_by: "date_created", sort_order: "desc"},
                        {name: "Oldest Created to Newest Created", sort_by: "date_created", sort_order: "asc"}];
                        
  $scope.selectedSort = $scope.sortOptions[0];
  
  $scope.sortResults = function (args) {
    $location.search('sortBy', args.sort_by);
    $location.search('sortOrder', args.sort_order);
    $scope.$on('$locationChangeSuccess', function () {
        fetchPage();
    });
  };

  function fetchPage () {
    searchParams = {};

    if ($routeParams.contributorName) {
      searchParams['filters[contributor]'] = $routeParams.contributorName;
    }

    if (typeof $routeParams.collectionId !== 'undefined') {
      searchParams['filters[collection_id]'] = $routeParams.collectionId;
    }
    
    if (typeof $routeParams.sortBy) {
      searchParams['sort_by'] = $routeParams.sortBy;
    }
    
    if (typeof $routeParams.sortOrder) {
      searchParams['sort_order'] = $routeParams.sortOrder;
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
  
  $scope.letters= ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

  $scope.setQuery = function (args) {
    console.log(args.field);
    
    if (args.field){
      if (args.field == "Collection"){
        $scope.title_term= "Collection";
        $scope.field= "collection_title";
      }
      else if (args.field == "creator"){
        $scope.title_term= "Creator";
        $scope.field= "creator";
      }
      else if (args.field == "interviewer"){
        $scope.title_term="Interviewer";
        $scope.field="interviewers";
      }
      else if (args.field == "interviewee"){
        $scope.title_term="Interviewee";
        $scope.field="interviewees";
      }
      else if (args.field == "producer"){
        $scope.title_term="Producer";
        $scope.field="producers";
      }
      else if (args.field == "host"){
        $scope.title_term="Host";
        $scope.field="hosts";
      }
      else if (args.field == "guest"){
        $scope.title_term="Guest";
        $scope.field="guests";
      }
      else if (args.field =="tag"){
        $scope.title_term= "Tag";
        $scope.field="tags";
      }
      else if (args.field == "seriesTitle"){
        $scope.title_term="Series";
        $scope.field="series_title";
      }
      else if (args.field == "episodeTitle"){
        $scope.title_term="Episode";
        $scope.field="episode_title";
      }
    };
    if (args.letter){
      letter= args.letter;
    };
    $http.get('/api/search?facets['+$scope.field+'][regex]='+letter+'.*&facets['+$scope.field+'][regex_flags]=CASE_INSENSITIVE&facets['+$scope.field+'][size]=100').success(function(data) {
        $scope.terms = data.facets[$scope.field].terms;
    });
  };
  
  $scope.newView = false;
  
  $scope.toggleView = function () {
    $scope.newView=!$scope.newView;
  };

}]);