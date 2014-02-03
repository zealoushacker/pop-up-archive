angular.module('fileButton', [])
.directive('fileButton', ['$timeout', function ($timeout) {
  return {
    link: function(scope, element, attributes) {

      var fileButton = angular.element(element);

      var fileInput = angular.element('<input type="file" multiple="multiple" style="display: none;"></input>');

      var onClickFunc = function() { fileInput[0].click(); }; 
      fileButton.bind('click', onClickFunc);

      var onChangeFunc = element.scope()[attributes.fileButton || 'setFiles'];
      fileInput.bind('change', onChangeFunc);

      fileButton.append(fileInput);
    }
  }
}]);
