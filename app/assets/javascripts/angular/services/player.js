(function () {

  function getEvent (event) {
    if (typeof event.originalEvent !== 'undefined') {
      return event.originalEvent;
    } else {
      return event;
    }
  }

  angular.module('ngPlayer', ['ngPlayerHater'])
  .factory('Player', ['playerHater', '$rootScope', function (playerHater, $rootScope) {
    var Player = {};

    var waveformData = [];

    function generateWaveform() {
      waveformData.length = 0;
      var l = 0;
      var segments = parseInt(Math.random() * 1000 + 1000);

      for (var i=0; i < segments; i++) {
        l = waveformData[i] = Math.max(Math.round(Math.random() * 10) + 2, Math.min(Math.round(Math.random() * -20) + 50, Math.round(l + (Math.random() * 25 - 12.5))));
      }
    }

    generateWaveform();

    $rootScope.$watch(function () { return (playerHater.nowPlaying || {}).position }, function (position) {
      Player.time = position / 1000;
    });

    $rootScope.$watch(function () { return (playerHater.nowPlaying || {}).duration }, function (duration) {
      Player.duration = duration / 1000;
    });

    $rootScope.$watch(function () { return playerHater.nowPlaying }, function () {
      generateWaveform();
    });

    function simpleFile(filename) {
      var file = filename;
      if (angular.isArray(file)) {
        file = file[0];
      }
      var parts = (file || '').split('/');
      return parts[parts.length-1].split('?', 2)[0];
    }

    Player.nowPlayingUrl = function () {
      return (playerHater.nowPlaying || {}).url;
    };

    Player.waveform = function () {
      return waveformData;
    }

    Player.play = function (url, title) {
      if (typeof url === 'undefined' ||
        playerHater.nowPlaying && simpleFile(url) === simpleFile(playerHater.nowPlaying.url)) {
        return playerHater.play();
      } 
      return playerHater.play({url:url, title: title});
    };

    Player.nowPlaying = function () {
      if (playerHater.nowPlaying) {
        return playerHater.nowPlaying.title || simpleFile(playerHater.nowPlaying.url);
      }
      return null;
    };

    Player.albumArt = function () {
      return "/assets/minimark.png";
    }

    Player.paused = function () {
      return playerHater.paused;
    };

    Player.pause = function () {
      return playerHater.pause();
    };

    Player.seekTo = function (position) {
      return playerHater.seekTo(position * 1000);
    };

    Player.rewind = function () {
      this.seekTo(0);
    };

    return Player;
  }])
  .filter('timeCode', function () {
    function pad(number) {
      if (number < 10) {
        return "0" + number;
      }
      return number;
    }

    return function (data, options) {
      if (isNaN(data)) {
        return "00:00.0";
      }
      var date = new Date(data*1000);
      return [date.getUTCHours(), pad(date.getMinutes()), pad(date.getUTCSeconds())].join(':') + '.' + parseInt(date.getUTCMilliseconds()/100);
    }
  })
  .directive("verticalScrubber", ["Player", '$timeout', function (Player, $timeout) {
    return {
      restrict: 'C',
      link: function(scope, el, attr) {
        scope.player = Player;
        var mouseIsDown = false;

        var barEl = angular.element("<div class='bar'></div>");
        scope.$watch('player.time', function (time) {
          barEl.css('height', time * 100 / Player.duration + "%");
        });
        el.bind('mousedown', function mouseIsDown (e) {
          e = getEvent(e);

          var element = this;
          var $this = angular.element(this);
          var $window = angular.element(window);
          var $body = angular.element(window.document.getElementsByTagName('body'));
          
          $body.addClass('scrubbing');
          var timeoutComplete = true;

          function markTimeoutComplete() {
            timeoutComplete = true;
          }

          function mouseIsMoving (e) {
            var top = 0, el = element;
            do {
              top += el.offsetTop || 0;
              el = el.offsetParent;
            } while(el);

            e = getEvent(e);

            var relativePosition = e.clientY - top;
            if (relativePosition >= 0) {
              var percentage = (relativePosition / element.offsetHeight);
              if (timeoutComplete) {
                timeoutComplete = false
                $timeout(function () { Player.seekTo((percentage * Player.duration)) }, 10).then(markTimeoutComplete, markTimeoutComplete);
              }
            }
          }

          $window.bind('mousemove', mouseIsMoving);

          function unbindAll () {
            $window.unbind('mouseup', unbindAll);
            $window.unbind('mousemove', mouseIsMoving);
            $body.removeClass('scrubbing');
          }

          $window.bind('mouseup', unbindAll);

          mouseIsMoving(e);
        });
        el.append(barEl);
      }
    }
  }])
  .directive("scrubber", ["Player", function (Player) {
    return {
      restrict: 'C',
      template: '<canvas></canvas>',
      replace: false,
      link: function (scope, el, attrs) {
        var element = el.find('canvas')[0];
        var context = element.getContext('2d');
        var mapped  = mapToArray(Player.waveform(), el.width());

        function canvasWidth() {
          return el.width();
        }

        function canvasHeight() {
          return el.height();
        }

        function barTop(size, height) {
          return Math.round((50 - size) * (height / 50) * 0.5);
        }

        function barHeight(size, height) {
          return Math.round(size * (height / 50));
        }

        function mapToArray(waveform, size) {
          var currentPixel = 0;
          var currentChunk = 0;
          var chunksPerPixel = waveform.length / size;
          var chunkStart, chunkEnd, sum, j;
          var array = [];
          while (currentPixel < size) {
            chunkStart = Math.ceil(currentChunk);
            currentChunk += chunksPerPixel;
            chunkEnd = Math.floor(currentChunk);

            sum = 0;
            for (j = chunkStart; j <= chunkEnd; j += 1) {
              sum += waveform[j];
            }

            array[currentPixel] = sum / (chunkEnd - chunkStart + 1);
            currentPixel += 1;
          }
          return array;
        }

        function redraw() {
          var height = canvasHeight();
          var width  = mapped.length;
          element.width = width;
          element.height = height;
          var scrubberEnd = Math.round(width * Player.time / Player.duration) || 0;
          context.clearRect(0, 0, width + 200, height + 200);
          context.fillStyle = 'rgb(255, 190, 48)';
          for (var i = 0; i < width; i++) {
            if (i == scrubberEnd) {
              context.fillStyle = "rgb(187, 187, 187)";
            }
            context.fillRect(i, barTop(mapped[i], height), 1, barHeight(mapped[i], height));
          }
        }

        function drawScrubber(to, from) {
          var height = canvasHeight();
          from = Math.floor(from / Player.duration * mapped.length);
          to   = Math.ceil(to / Player.duration * mapped.length);
          if (to > from) {
            context.fillStyle = 'rgb(255, 190, 48)'
            for (var i=from; i<=to; i++) {
              context.fillRect(i, barTop(mapped[i], height), 1, barHeight(mapped[i], height));
            }
          } else {
            context.fillStyle = "rgb(187, 187, 187)";
            for (var i=to; i<=from+1; i++) {
              context.fillRect(i, barTop(mapped[i], height), 1, barHeight(mapped[i], height));
            }
          }
        }

        scope.$watch(Player.waveform, function (waveform) {
          mapped = mapToArray(waveform, canvasWidth());
          redraw();
        });

        var currentWidth = mapped.length, currentHeight = canvasHeight();
        function checkWaveform () {
          if (currentWidth != canvasWidth() || currentHeight != canvasHeight()) {
            context.scale(currentWidth/canvasWidth(), currentHeight/canvasHeight());
            if (currentWidth != canvasWidth()) {
              mapped = mapToArray(Player.waveform(), canvasWidth());
            }
            currentWidth = canvasWidth();
            currentHeight = canvasHeight();
            redraw();
          }
        }

        scope.$watch(function () { return Player.time }, drawScrubber);

        scope.$watch(checkWaveform);
        angular.element(window).bind('resize', checkWaveform);
        
        el.bind('click', function (e) {
          var left = 0, element = this;
          do {
            left += element.offsetLeft || 0;
            element = element.offsetParent;
          } while(element);
          e = getEvent(e);
          e.stopPropagation();
          var relativePosition = e.offsetX || (e.clientX - left);
          var percentage = (relativePosition / el[0].offsetWidth);
          Player.seekTo(percentage * Player.duration);
        });
      }
    }
  }])
  .directive("transcript", ['Player','$parse', function (Player, $parse) {
    return {
      restrict: 'C',
      replace: true,
      scope: {
        transcript: "=transcriptText",
        canEdit: "=transcriptEditable",
        transcriptTimestamps: "@",
        currentTime: "=",
        fileUrl: "=",
        saveText: "&"
      },
      priority: -1000,
      template: '<div class="file-transcript">' +
                  '<table class="table">' +
                    '<tr ng-repeat="text in transcript" ng-class="{current: transcriptStart==text.startTime}" >' +
                      '<td style="width: 8px; text-align:left;"><a ng-click="seekTo(text.startTime)"><i class="icon-play-circle"></i></a></td>' +
                      '<td style="width: 16px; text-align:left; padding: 0 0 0 10px" ng-show="showRange">{{toTimestamp(text.startTime)}}</td>' +
                      '<td ng-show="showStart">{{toTimestamp(text.startTime)}}</td>' +
                      '<td ng-show="!editorEnabled"><a ng-click="seekTo(text.startTime)"><div class="file-transcript-text" ng-bind-html-unsafe="text.text"></div></a></td>' +
                      '<td ng-show="canShowEditor()" style="width: 8px; padding-right: 10px; text-align: right">'+
                        '<a href="#" ng-click="enableEditor()"><i class="icon-pencil"></i></a></td>' +
                      '<td ng-show="editorEnabled"><input ng-model="editableTranscript" ng-show="editorEnabled"></td>' +
                      '<td ng-show="editorEnabled" style="width: 50px;">' +
                        '<a href="#" ng-click="updateText(text)" style="width: 8px; float: left; padding: 0 8px">' +
                          '<i class="icon-ok"></i></a>' +
                        '<a href="#" ng-click="disableEditor()" style="width: 8px; float: left; padding: 0 10px 0 8px">' +
                          '<i class="icon-remove"></i></a></td>' +
                    '</tr>' +
                  '</table>' +
                '</div>',
      link: function (scope, el, attrs) {
        var lastSecond = -1;

        scope.player = Player;

        scope.transcriptStart = 0;
        scope.transcriptRows = {};
        scope.transcriptTimestamps = scope.transcriptTimestamps || 'range';

        scope.$watch('transcript', function (is, was) {
          angular.copy({}, scope.transcriptRows);
          angular.forEach(is, function(row, index) {
            scope.transcriptRows[row.startTime] = index;
          });
        });

        if (scope.transcriptTimestamps == 'range') {
          scope.showRange = true;
          scope.showStart = false;
        } else if (scope.transcriptTimestamps = 'start') {
          scope.showStart = true;
          scope.showRange = false;
        }

        scope.updateText = function (text) {
          text.text = this.editableTranscript;
          this.disableEditor();
          this.saveText({text: text});
        };

        scope.toTimestamp = function (seconds) {
          var d = new Date(seconds * 1000);
          if (seconds > 3600) {
            return Math.floor(seconds / 3600) + ":" + dd(Math.floor(seconds % 3600 / 60)) + ":" + dd(seconds % 3600 % 60);
          } else {
            return Math.floor(seconds / 60) + ":" + dd(seconds % 60);
          }
        }

        var dd = function (dd) {
          if (dd < 10) {
            return "0" + dd;
          }
          return dd;
        }

        scope.seekTo = function(time) {
          scope.$emit('transcriptSeek', time);
        }

        //edit transcripts
        scope.editorEnabled = false;

        scope.canShowEditor = function() {
          return (!this.editorEnabled && scope.canEdit && (parseInt(this.text.id, 10) > 0));
        };
        
        scope.enableEditor = function() {
          this.editorEnabled = true;
          this.editableTranscript = this.text.text;
        };
        
        scope.disableEditor = function() {
          this.editorEnabled = false;
        };

        if (scope.transcript && scope.transcript.length > 0) {
          scope.$watch('currentTime', function (time) {
            var second = parseInt(time, 10);
            var height = angular.element(".file-transcript table tr")[0].scrollHeight;
            if (second != lastSecond) {
              if ((scope.player.nowPlayingUrl() == scope.fileUrl) && (second in scope.transcriptRows)) {
                var index = scope.transcriptRows[second];
                if (index != undefined) {
                  el[0].scrollTop = Math.max((index - 1), 0) * height;
                  scope.transcriptStart = second;
                }
              }
              lastSecond = second;
            }
          });
        }

      }
    }
  }]);
})();