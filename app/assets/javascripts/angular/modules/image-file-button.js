angular.module('imageFileButton', [])
.directive('imageFileButton', ['$timeout', function ($timeout) {
  return {
    link: function(scope, element, attributes) {
      var imageFileButton = angular.element(element);

      var imageFileInput = angular.element('<input type="file" multiple="multiple" ng-model="newItem.images"></input>');

      var onClickFunc = function() { imageFileInput[0].click(); };

      imageFileButton.bind('click', onClickFunc);

      var onChangeFunc = element.scope()[attributes.imageFileButton || 'setImageFiles'];
      imageFileInput.bind('change', onChangeFunc);

      imageFileButton.append(imageFileInput); 
    }
  }
}])
