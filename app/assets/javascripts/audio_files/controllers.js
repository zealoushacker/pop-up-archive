angular.module("Directory.audioFiles.controllers", ['ngPlayer'])
.controller("AudioFileCtrl", ['$scope', '$timeout', '$modal', 'Player', 'Me', 'TimedText', 'AudioFile', '$http', function($scope, $timeout, $modal, Player, Me, TimedText, AudioFile) {
  $scope.fileUrl = $scope.audioFile.url;

  $scope.downloadLinks = [
      {
        text: 'Text Format',
        target: '_self',
        href: "/api/items/" + $scope.item.id + "/audio_files/" + $scope.audioFile.id + "/transcript.txt"
      },
      {
        text: 'SRT Format',
        target: '_self',
        href: "/api/items/" + $scope.item.id + "/audio_files/" + $scope.audioFile.id + "/transcript.srt"
      },
      {
        text: 'XML Format (W3C Transcript)',
        target: '_self',
        href: "/api/items/" + $scope.item.id + "/audio_files/" + $scope.audioFile.id + "/transcript.xml"
      },
      {
        text: 'JSON Format',
        target: '_self',
        href: "/api/items/" + $scope.item.id + "/audio_files/" + $scope.audioFile.id + "/transcript.json"
      }
  ];
  
  $scope.embedCode =
     { "title": "Copy and Paste the Following Code to Embed This File on Your Site",
       "content": "<xmp><iframe frameborder='0' width='508' height='95' scrolling='no' seamless='yes' name='"+ $scope.item.title + "' src='"+ $scope.my_path + "/embed_player/" + encodeURIComponent($scope.item.title.replace(/\./g, '&#46;')) + "/" + $scope.audioFile.id + "/" + $scope.item.id + "/" + $scope.collection.id + "'></iframe></xmp>",
    };

  $scope.play = function () {
    $http ({
      method: 'POST',
      url: "/api/items/" + this.id + "/audio_files/" + this.audioFiles[0].id + '/listens.JSON',
      data: { 'file': this.audioFiles[0]},
      headers: {"Content-Type": undefined },
      transformRequest: angular.identity
    });   
    Player.play($scope.fileUrl);
  }

  $scope.player = Player;

  $scope.isPlaying = function () {
    return $scope.isLoaded() && !Player.paused();
  }

  $scope.isLoaded = function () {
    return Player.nowPlayingUrl() == $scope.fileUrl;
  }

  $scope.$on('transcriptSeek', function(event, time) {
    event.stopPropagation();
    $scope.play();
    $scope.player.seekTo(time);
  });

  Me.authenticated(function (me) {

    if (me.canEdit($scope.item)) {
      $scope.downloadLinks.unshift({
        text: 'Audio File',
        target: '_self',
        href: $scope.audioFile.original
      });
    }

    $scope.saveText = function(text) {
      var tt = new TimedText(text);
      tt.update();
    };

    $scope.orderTranscript = function () {
      $scope.audioFile = new AudioFile($scope.audioFile);
      $scope.audioFile.itemId = $scope.item.id;
      $scope.orderTranscriptModal = $modal({template: "/assets/audio_files/order_transcript.html", persist: false, show: true, backdrop: 'static', scope: $scope, modalClass: 'order-transcript-modal'});
      return;
    };

    $scope.addToAmara = function () {
      $scope.audioFile = new AudioFile($scope.audioFile);
      $scope.audioFile.itemId = $scope.item.id;
      var filename = $scope.audioFile.filename;
      return $scope.audioFile.addToAmara(me).then( function (task) {

        var msg = '"' + filename + '" added. ' +
        '<a data-dismiss="alert" data-target=":blank" ng-href="' + task.transcriptUrl + '">View</a> or ' + 
        '<a data-dismiss="alert" data-target=":blank" ng-href="' + task.editTranscriptUrl + '">edit the transcript</a> on Amara.';

        var alert = new Alert();
        alert.category = 'add_to_amara';
        alert.status   = 'Added';
        alert.progress = 1;
        alert.message  = msg;
        alert.add();
      });
    };

    $scope.showOrderTranscript = function () {
      return (new AudioFile($scope.audioFile)).canOrderTranscript(me);
    };

    $scope.showTranscriptOrdered = function () {
      return (new AudioFile($scope.audioFile)).isTranscriptOrdered();
    };

    $scope.showSendToAmara = function () {
      return (new AudioFile($scope.audioFile)).canSendToAmara(me);
    };

    $scope.showOnAmara = function () {
      return (new AudioFile($scope.audioFile)).isOnAmara();
    };

    $scope.addToAmaraTask = function () {
      return (new AudioFile($scope.audioFile)).taskForType('add_to_amara');
    };

  });

}])
.controller("OrderTranscriptFormCtrl", ['$scope', '$window', '$q', 'Me', 'AudioFile', function($scope, $window, $q, Me, AudioFile) {

  Me.authenticated(function (me) {

    $scope.length = function() {
      var mins = (new AudioFile($scope.audioFile)).durationMinutes();
      var label = "minutes";
      if (mins == 1) { label = "minute"; }
      return (mins + ' ' + label);
    }

    $scope.price = function() {
      return (new AudioFile($scope.audioFile)).transcribePrice();
    }

    $scope.submit = function () {
      $scope.audioFile.orderTranscript(me);
      $scope.clear();
      return;
    }

  });

  $scope.clear = function () {
    $scope.hideOrderTranscriptModal();
  }

  $scope.hideOrderTranscriptModal = function () {
    $q.when($scope.orderTranscriptModal).then( function (modalEl) {
      modalEl.modal('hide');
    });
  } 

}])
.controller("PersistentPlayerCtrl", ["$scope", 'Player', function ($scope, Player) {
  $scope.player = Player;
  $scope.collapsed = false;

  $scope.collapse = function () {
    $scope.collapsed = !$scope.collapsed;
  };

}]);