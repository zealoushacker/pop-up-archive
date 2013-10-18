angular.module("Directory.audioFiles.controllers", ['ngPlayer'])
.controller("AudioFileCtrl", ['$scope', '$timeout', '$modal', 'Player', 'Me', 'TimedText', 'AudioFile', function($scope, $timeout, $modal, Player, Me, TimedText, AudioFile) {
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

  $scope.play = function () {
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

    // if (me.canEdit($scope.item)) {
    //   $scope.downloadLinks.unshift({
    //     text: 'Audio File',
    //     target: '_self',
    //     href: $scope.audioFile.urls[0];
    //   });
    // }

    $scope.saveText = function(text) {
      var tt = new TimedText(text);
      tt.update();
    };

    $scope.orderTranscript = function () {
      $scope.orderTranscriptModal = $modal({template: "/assets/audio_files/order_transcript.html", persist: false, show: true, backdrop: 'static', scope: $scope, modalClass: 'order-transcript-modal'});
      return;
    };

    $scope.addToAmara = function () {
      return (new AudioFile($scope.audioFile)).addToAmara(me);
    };

    $scope.showOrderTranscript = function () {
      return (new AudioFile($scope.audioFile)).canOrderTranscript(me);
    };

    $scope.showTranscriptInProgress = function () {
      return (new AudioFile($scope.audioFile)).isTranscriptOrdered();
    };

    $scope.showSendToAmara = function () {
      return (new AudioFile($scope.audioFile)).canSendToAmara(me);
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
      // $scope.audioFile = new AudioFile($scope.audioFile);
      // $scope.audioFile.itemId = $scope.item.id;
      // return $scope.audioFile.orderTranscript();
      $scope.close();
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