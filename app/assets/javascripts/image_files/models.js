angular.module('Directory.imageFiles.models', ['RailsModel', 'S3Upload'])
.factory('ImageFile', ['$window', 'Model', 'S3Upload', '$http', function ($window, Model, S3Upload, $http) {
  var ImageFile = Model({url:'/api/items/{{itemId}}/image_files/{{id}}', name: 'image_file', only: ['url', 'filename']});

  ImageFile.prototype.cleanFileName = function (fileName) {
    return fileName.replace(/[^a-z0-9\.]+/gi,'_');
  }

  ImageFile.prototype.uploadKey = function (token, fileName) {
    return (token + '/' + this.cleanFileName(fileName));
  }

  ImageFile.prototype.getStorage = function () {
    var self = this;
    return ImageFile.processResponse($http.get(self.$url() + '/upload_to')).then(function (storage) {
      self.storage = storage;
      return self.storage;
    });
  }

  ImageFile.prototype.upload = function (file, options) {
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

 