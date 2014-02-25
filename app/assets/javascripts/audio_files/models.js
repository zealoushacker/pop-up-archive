angular.module('Directory.audioFiles.models', ['RailsModel', 'S3Upload'])
.factory('AudioFile', ['$window', 'Model', 'S3Upload', '$http', function ($window, Model, S3Upload, $http) {
  var AudioFile = Model({url:'/api/items/{{itemId}}/audio_files/{{id}}', name: 'audio_file', only: ['url', 'filename']});

  AudioFile.transcribeRatePerMinute = 2;

  AudioFile.prototype.cleanFileName = function (fileName) {
    return fileName.replace(/[^a-z0-9\.]+/gi,'_');
  }

  AudioFile.prototype.uploadKey = function (token, fileName) {
    return (token + '/' + this.cleanFileName(fileName));
  }

  AudioFile.prototype.getStorage = function () {
    var self = this;
    return AudioFile.processResponse($http.get(self.$url() + '/upload_to')).then(function (storage) {
      self.storage = storage;
      return self.storage;
    });
  }

  AudioFile.prototype.upload = function (file, options) {
    var self = this;
    self.getStorage().then(function (storage) {
      // console.log('upload_to!', storage, self, self.storage);

      options = options || {};

      options.bucket     = options.bucket       || self.storage.bucket;
      options.access_key = options.access_key   || self.storage.key;
      options.ajax_base  = self.$url();
      options.key        = self.uploadKey(options.token, file.name);
      options.file       = file;

      self.upload = new S3Upload(options);
      self.upload.upload();
    });
  };

 
  AudioFile.prototype.canOrderTranscript = function (user) {
    var self = this;

    if (self.duration <= 0) return false;

    if (!self.transcodedAt) return false;
 
    if (!user.isAdmin()) return false;

    if (!user.hasCard) return false;

    if (self.isTranscriptOrdered()) return false;

    return true;
  };

  AudioFile.prototype.isTranscriptOrdered = function () {
    var self = this;
    var t = self.taskForType('order_transcript');

    if (t && t.status != 'error') {
      return true;
    }
    return false;      
  }

  AudioFile.prototype.canSendToAmara = function (user) {
    var self = this;

    if (self.duration <= 0) return false;

    if (!self.transcodedAt) return false;
 
    if (!user.isAdmin()) return false;

    // console.log('canSendToAmara', user.organization);
    if (!user.organization || !user.organization.amaraTeam) return false;

    if (self.isOnAmara()) return false;

    return true;
  };

  AudioFile.prototype.isOnAmara = function () {
    var self = this;
    var t = self.taskForType('add_to_amara');

    if (t && t.status != 'error') {
      return true;
    }
    return false;      
  }

  AudioFile.prototype.taskForType = function (t) {
    for(var i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].type == t) { return this.tasks[i]; }
    }
  };

  AudioFile.prototype.orderTranscript = function (user) {
    var self = this;
    // console.log('orderTranscript', this);
    return AudioFile.processResponse($http.post(self.$url() + '/order_transcript')).then(function (orderTranscriptTask) {
      // console.log('orderTranscript result', orderTranscriptTask, self);
      self.tasks.push(orderTranscriptTask);
      return orderTranscriptTask;
    });
  };

  AudioFile.prototype.addToAmara = function (user) {
    var self = this;
    // console.log('addToAmara', this);
    return AudioFile.processResponse($http.post(self.$url() + '/add_to_amara')).then(function (addToAmaraTask) {
      // console.log('addToAmara result', addToAmaraTask, self);
      self.tasks.push(addToAmaraTask);
      return addToAmaraTask;
    });
  };

  AudioFile.prototype.createListen = function () {
    $http.post(this.$url() + '/listens');
  };    

  AudioFile.prototype.durationMinutes = function () {
    return $window.Math.ceil(this.duration / 60);
  }

  AudioFile.prototype.transcribePrice = function () {
    return this.durationMinutes() * AudioFile.transcribeRatePerMinute;
  };

  return AudioFile;
}])
.factory('TimedText', ['Model', '$http', function (Model, $http) {
  var TimedText = Model({url:'/api/timed_texts/{{id}}', name: 'timed_text', only: ['text']});
  return TimedText;
}]);
