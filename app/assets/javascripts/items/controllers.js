angular.module('Directory.items.controllers', ['Directory.loader', 'Directory.user', 'Directory.items.models', 'Directory.entities.models', 'Directory.people.models', 'prxSearch'])
.controller('ItemsCtrl', [ '$scope', 'Item', 'Loader', 'Me', function ItemsCtrl($scope, Item, Loader, Me) {
  Me.authenticated(function (data) {
    if ($scope.collectionId) {
      $scope.items = Loader.page(Item.query(), 'Items');
    }
  });

  $scope.startUpload = function() {
    var newFiles = [];
    $scope.$emit('filesAdded', newFiles);
  }

}])
.controller('ItemCtrl', ['$scope', '$timeout','Item', 'Loader', 'Me', '$routeParams', 'Collection', 'Entity', '$location', 'SearchResults', function ItemCtrl($scope, $timeout, Item, Loader, Me, $routeParams, Collection, Entity, $location, SearchResults) {

  $scope.canEdit = false;

  if ($routeParams.id) {
    Loader.page(Item.get({collectionId:$routeParams.collectionId, id: $routeParams.id}), Collection.get({id:$routeParams.collectionId}), Collection.query(), 'Item-v2/'+$routeParams.id, $scope).then(function () {
      angular.forEach($scope.collections, function (collection) {
        if (collection.id == $scope.item.collectionId) {
          $scope.canEdit = true;
        }
      });
    });
  }

  SearchResults.setCurrentIndex({id:$routeParams.id});
  $scope.nextItem = SearchResults.getItem(SearchResults.currentIndex + 1);
  $scope.previousItem = SearchResults.getItem(SearchResults.currentIndex - 1);
  $scope.searchResults = SearchResults;

  $scope.transcriptExpanded = false;

  $scope.toggleTranscript = function () {
    $scope.transcriptExpanded = !$scope.transcriptExpanded;
  }

  $scope.transcriptClass = function () {
    if ($scope.transcriptExpanded) {
      return "expanded";
    }
    return "collapsed";
  }


  $scope.deleteEntity = function(entity) {
    var e = new Entity(entity);
    e.itemId = $scope.item.id;
    e.deleting = true;
    e.delete().then(function() {
      $scope.item.entities.splice($scope.item.entities.indexOf(entity), 1);
    });
  }

  $scope.confirmEntity = function(entity) {
    // console.log('confirmEntity', entity);
    entity.itemId = $scope.item.id;
    entity.isConfirmed = true;
    var entity = new Entity(entity);
    entity.update();
  }
    
  $scope.deleteItem = function () {
    if (confirm("Are you sure you want to delete the item " + $scope.item.title +"? \n\n This cannot be undone." )){
      $scope.item.delete().then(function () {
        $timeout(function(){ $scope.$broadcast('datasetChanged')}, 100);
        $location.path('/collections/' + $scope.collection.id);
      })
    }
  }

}])
.controller('ItemFormCtrl', ['$scope', '$routeParams', 'Schema', 'Item', 'Contribution', function ($scope, $routeParams, Schema, Item, Contribution) {

  $scope.item = {};
  $scope.itemTags = [];

  if ($scope.$parent.item) {
    // console.log('$scope.$parent.item', $scope.$parent.item);
    angular.copy($scope.$parent.item, $scope.item);
    angular.forEach($scope.item.tags, function(v,k){ this.push({id:v, text:v}); }, $scope.itemTags);
  }

  $scope.fields = Schema.columns;

  $scope.tagSelect = function() {

    // console.log('tagSelect', $scope.item, $scope.itemTags);

    return {
      placeholder: 'Tags...',
      width: '220px',
      tags: [],
      initSelection: function (element, callback) { 
        // console.log('tagSelect initSelection', $scope.itemTags);
        callback($scope.itemTags);
      }
    }
  };

  $scope.roleSelect = {
    placeholder:'Role...',
    width: '160px'
  };

  $scope.deleteContribution = function(contribution) {
    contribution._delete = true;
  }

  $scope.addContribution = function () {
    var c = new Contribution();
    if (!$scope.item.contributions) {
      $scope.item.contributions = [];
    }
    $scope.item.contributions.push(c);
  }

  $scope.peopleSelect = {
    placeholder: 'Name...',
    width: '240px',
    minimumInputLength: 2,
    quietMillis: 100,
    formatSelection: function (person) { return person.name; },
    formatResult: function (result, container, query, escapeMarkup) { 
      var markup=[];
      window.Select2.util.markMatch(result.name, query.term, markup, escapeMarkup);
      return markup.join("");
    },
    createSearchChoice: function (term, data) {
      if ($(data).filter(function() {
        return this.name.toUpperCase().localeCompare(term.toUpperCase()) === 0;
      }).length === 0) {
        return { id: 'new', name: term };
      }
    },
    initSelection: function (element, callback) {
      var scope = angular.element(element).scope();
      callback(scope.contribution.person);
    },
    ajax: {
      url: '/api/collections/' + $routeParams.collectionId + '/people',
      data: function (term, page) { return { q: term }; },
      results: function (data, page) { return { results: data }; }
    }
  }

  $scope.$parent.$watch('item', function (is) {
    // console.log('$scope.$parent.$watch item', $scope.$parent.item);
    if (is && $scope.item != is) {
      angular.copy(is, $scope.item);
      $scope.itemTags = [];
      angular.forEach($scope.item.tags, function(v,k){ this.push({id:v, text:v}); }, $scope.itemTags);
    }
  });

  $scope.submit = function () {

    var cleanTags = [];
    angular.forEach($scope.itemTags, function(v,k){ this.push(v.id); }, cleanTags);
    $scope.item.tags = cleanTags;
    
    if ($scope.item.id) {
      $scope.item.update().then(function (data) {
        $scope.item.updateContributions();
        angular.copy($scope.item, $scope.$parent.item);
        // $scope.close();
      });
    } else {
      $scope.item.create().then(function (data) {
        $timeout(function(){ $scope.$broadcast('datasetChanged')}, 750);
        $scope.close();
      });
    }
  }

}]);
