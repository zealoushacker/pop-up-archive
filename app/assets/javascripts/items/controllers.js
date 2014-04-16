angular.module('Directory.items.controllers', ['Directory.loader', 'Directory.user', 'Directory.items.models', 'Directory.entities.models', 'Directory.people.models', 'prxSearch', 'Directory.storage'])
.controller('ItemsCtrl', [ '$scope', 'Item', 'Loader', 'Me', 'Storage', function ItemsCtrl($scope, Item, Loader, Me, Storage) {

  $scope.Storage = Storage;

  Me.authenticated(function (data) {
    if ($scope.collectionId) {
      $scope.items = Loader.page(Item.query(), 'Items');
    }
  });

  $scope.startUpload = function() {
    var newFiles = [];
    var newImages = [];
    $scope.$emit('filesAdded', newFiles);
  }

}])
.controller('ItemCtrl', ['$scope', '$timeout', '$q', '$modal', 'Item', 'Loader', 'Me', '$routeParams', 'Collection', 'Entity', '$location', 'SearchResults', 'Storage', '$window', function ItemCtrl($scope, $timeout, $q, $modal, Item, Loader, Me, $routeParams, Collection, Entity, $location, SearchResults, Storage, $window) {

  $scope.Storage = Storage;

  $scope.storageModal = $modal({template: '/assets/items/storage.html', persist: false, show: false, backdrop: 'static', scope: $scope});

  if ($routeParams.id) {
    Loader.page(Item.get({collectionId:$routeParams.collectionId, id: $routeParams.id}), Collection.get({id:$routeParams.collectionId}), Collection.query(), 'Item-v2/'+$routeParams.id, $scope);
  }

  SearchResults.setCurrentIndex({id:$routeParams.id});
  $scope.nextItem = SearchResults.getItem(SearchResults.currentIndex + 1);
  $scope.previousItem = SearchResults.getItem(SearchResults.currentIndex - 1);
  $scope.searchResults = SearchResults;

  $scope.transcriptExpanded = false;

  $scope.isTransciptProcessing = function() {
    var item = $scope.item;
    var user = $scope.currentUser;
    return (user && item && user.canEdit(item) && (item.audioFiles.length > 0) && (item.audioFiles[0].transcript == 0));
  };

  $scope.toggleTranscript = function () {
    $scope.transcriptExpanded = !$scope.transcriptExpanded;
  };

  $scope.transcriptClass = function () {
    if ($scope.transcriptExpanded) {
      return "expanded";
    }
    return "collapsed";
  };

  $scope.itemStorage = function() {
    $q.when($scope.storageModal).then( function (modalEl) {
      modalEl.modal('show');
    });
  };
  
  $scope.clearEntities = function() {
    $scope.item.entities.forEach(function(entity) {
      if (entity.isConfirmed === false) {
    	  $scope.deleteEntity(entity);
      }
    });
  };

  $scope.deleteEntity = function(entity) {
    var e = new Entity(entity);
    e.itemId = $scope.item.id;
    e.deleting = true;
    e.delete().then(function() {
      $scope.item.entities.splice($scope.item.entities.indexOf(entity), 1);
    });
  };

  $scope.confirmEntity = function(entity) {
    // console.log('confirmEntity', entity);
    entity.itemId = $scope.item.id;
    entity.isConfirmed = true;
    var entity = new Entity(entity);
    entity.update();
  };
    
  $scope.deleteItem = function () {
    if (confirm("Are you sure you want to delete the item " + $scope.item.title +"? \n\n This cannot be undone." )){
      $scope.item.delete().then(function () {
        $timeout(function(){ $scope.$broadcast('datasetChanged')}, 100);
        $location.path('/collections/' + $scope.collection.id);
      })
    }
  };
  
  $scope.encodeText = function (text) {
    return encodeURIComponent(text);
  };
  
 $scope.my_path= $window.location.protocol + "//" + $window.location.host;
}])
.controller('ItemStorageCtrl', [ '$scope', 'Item', 'Loader', 'Me', function ItemsCtrl($scope, Item, Loader, Me) {

  function pad(number) {
    if (number < 10) {
      return "0" + number;
    }
    return number;
  }

  $scope.durationString = function (secs) {
    var d = new Date(secs * 1000);

    return pad(d.getUTCHours()) + ":" + pad(d.getUTCMinutes()) + ":" + pad(d.getUTCSeconds());
  };

}])
.controller('ItemFormCtrl', ['$window', '$cookies', '$scope', '$http', '$q', '$timeout', '$route', '$routeParams', '$modal', 'Me', 'Loader', 'Alert', 'Collection', 'Item', 'Contribution', 'ImageFile', function FilesCtrl($window, $cookies, $scope, $http, $q, $timeout, $route, $routeParams, $modal, Me, Loader, Alert, Collection, Item, Contribution, ImageFile) {

  $scope.$watch('item', function (is) {
    if (!angular.isUndefined(is) && (is.id > 0) && angular.isUndefined(is.adoptToCollection)) {
      is.adoptToCollection = is.collectionId;
    }
  });

  $scope.selectedCollection = null;

  $scope.$watch('item.collectionId', function (cid) {
    $scope.setSelectedCollection();
  })

  $scope.$watch('item.adoptToCollection', function (cid) {
    $scope.setSelectedCollection();
  })

  $scope.setSelectedCollection = function () {
    if (angular.isUndefined($scope.item))
      return;

    var collectionId = $scope.item.adoptToCollection || $scope.item.collectionId;

    if (collectionId && (collectionId > 0) && (!$scope.selectedCollection || (collectionId != $scope.selectedCollection.id))) {
      for (var i=0; i < $scope.collections.length; i++) {
        if ($scope.collections[i].id == collectionId) {
          $scope.selectedCollection = $scope.collections[i];
          break;
        }
      }
    }
  };

  if ($scope.item && $scope.item.id) {
    $scope.item.adoptToCollection = $scope.item.collectionId;
  }

  $scope.submit = function () {
    // console.log('ItemFormCtrl submit: ', $scope.item);
    var saveItem = $scope.item;
    this.item = $scope.initializeItem(true);
    $scope.clear();

    var uploadFiles = saveItem.files;
    saveItem.files = [];
    var uploadImageFiles = saveItem.imageFiles;
    saveItem.imageFiles = [];

    var audioFiles = saveItem.audioFiles;
    var imageFiles = saveItem.imageFiles;
    var contributions = saveItem.contributions;

    Collection.get(saveItem.collectionId).then(function (collection) {
      if (angular.isArray(collection.items)) {
        collection.items.push(saveItem);
      }
    });

    if (saveItem.id) {

      saveItem.update().then(function (data) {
        // reset tags
        saveItem.tagList2Tags();
        $scope.uploadImageFiles(saveItem, uploadImageFiles);        
        $scope.addRemoteImageFile(saveItem, $scope.urlForImage)
        $scope.uploadAudioFiles(saveItem, uploadFiles);
        $scope.updateAudioFiles(saveItem, audioFiles);
        $scope.updateContributions(saveItem, contributions);
        delete $scope.item;
        // console.log('scope after update', $scope);
        // $scope.item = saveItem;
        // if ($scope.item != $scope.$parent.item) {
        //   angular.copy($scope.item, $scope.$parent.item);
        // }
      });
    } else {
      saveItem.create().then(function (data) {
        // reset tags
        saveItem.tagList2Tags();
        $scope.addRemoteImageFile(saveItem, $scope.urlForImage);
        $scope.uploadImageFiles(saveItem, uploadImageFiles);
        $scope.uploadAudioFiles(saveItem, uploadFiles);
        $scope.updateAudioFiles(saveItem, audioFiles);
        $scope.updateImageFiles(saveItem, imageFiles);
        $scope.updateContributions(saveItem, contributions);
        $timeout(function(){ $scope.$broadcast('datasetChanged')}, 750);
        delete $scope.item;
        // console.log('scope after create', $scope);
      });
    }

  };

  $scope.addRemoteImageFile = function (saveItem, imageUrl){
    if (!$scope.urlForImage)
      return;
    new ImageFile({remoteFileUrl: imageUrl, itemId: saveItem.id} ).create();      
    $scope.item.images.push({ name: 'name', remoteFileUrl: imageUrl, size: ''});
    console.log("url link", $scope.urlForImage);
    $scope.urlForImage = "";
  };



  $scope.clear = function() {
    $scope.hideUploadModal();
  }

  // used by the upload-button callback when new files are selected
  $scope.setFiles = function(event) {
    element = angular.element(event.target);

    $scope.$apply(function($scope) {

      var newFiles = element[0].files;

      // default title to first file if not already set
      if (!$scope.item.title || $scope.item.title == "") {
        $scope.item.title = newFiles[0].name;
      }

      if (!$scope.item.files) {
        $scope.item.files = [];
      }

      // add files to the item
      angular.forEach(newFiles, function (file) {
        $scope.item.files.push(file);
      });

      element[0].value = "";

    });
  };

  $scope.setImageFiles = function(event) {
    element = angular.element(event.target);

    $scope.$apply(function($scope) {

      var newImageFiles = element[0].files;
      // console.log('image files',element[0].files);

      if (!$scope.item.images) {
        $scope.item.images = [];
      }

      // add image files to the item
      angular.forEach(newImageFiles, function (file) {
        $scope.item.images.push(file);
      });

      element[0].value = "";

    });
  };

  $scope.removeAudioFile = function(file) {
    if (file.id && (file.id > 0)) {
      file._delete = true;
    } else {
      $scope.item.files.splice($scope.item.files.indexOf(file), 1);
    }
  }

  $scope.removeImageFile = function(imageFile) {
    if (imageFile.id && (imageFile.id > 0)) {
      imageFile._delete = true;
    } else {
      $scope.item.images.splice($scope.item.images.indexOf(imageFile), 1);
    }
  }

  $scope.addContribution = function () {
    var c = new Contribution();
    if (!$scope.item.contributions) {
      $scope.item.contributions = [];
    }
    $scope.item.contributions.push(c);
    // console.log('addContribution', $scope);
  }

  $scope.deleteContribution = function(contribution) {
    // mark it to delete later
    if (contribution.id && (contribution.id > 0)) {
      contribution._delete = true;
    } else {
      $scope.item.contributions.splice($scope.item.contributions.indexOf(contribution), 1);
    }
  }

  $scope.updateContributions = function(item, contributions) {
    item.contributions = contributions;
    item.updateContributions();
  };

  $scope.updateAudioFiles = function(item, audioFiles) {
    item.audioFiles = audioFiles;
    item.updateAudioFiles();
  };

  $scope.updateImageFiles = function(item, imageFiles) {
    console.log("this in updateImageFiles method in items/controllers.js", this)
    item.imageFiles = imageFiles;
    item.updateImageFiles();
  };

  $scope.tagSelect = function() {
    return {
      placeholder: 'Tags...',
      width: '284px',
      tags: [],
      initSelection: function (element, callback) { 
        callback($scope.item.getTagList());
      }
    }
  };

  $scope.languageSelect = function() {
    return {
      placeholder: 'Language...',
      width: '220px',
      data: Item.languages,
      initSelection: function (element, callback) { 
        callback(element.val());
      }
    }
  };  

  // the ajax version, maybe?
  // $scope.languageSelect = function() {
  //   return {
  //     placeholder: 'Language...',
  //     width: '220px',
  //     ajax: {
  //       url: '/languages.json',
  //       results: function (data) {
  //         return {results: data};
  //       }
  //     },
  //     initSelection: function (element, callback) { 
  //       callback($scope.item.language);
  //     }
  //   }
  // };  

  $scope.roleSelect = {
    placeholder:'Role...',
    width: '160px'
  };

  $scope.peopleSelect = {
    placeholder: 'Name...',
    width: '240px',
    minimumInputLength: 2,
    quietMillis: 100,
    formatSelection: function (person) { return person.name; },
    formatResult: function (result, container, query, escapeMarkup) { 
      var markup=[];
      $window.Select2.util.markMatch(result.name, query.term, markup, escapeMarkup);
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
      url: function (self, term, page, context) {
        return '/api/collections/' + ($routeParams.collectionId || $scope.item.collectionId) + '/people';
      },
      data: function (term, page) { return { q: term }; },
      results: function (data, page) { return { results: data }; }
    }
  }

}]);
