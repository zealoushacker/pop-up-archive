angular.module('Directory.dashboard.controllers', ['Directory.loader', 'Directory.user'])
.controller('DashboardCtrl', [ '$scope', 'Item', 'Loader', 'Me', '$timeout', function ItemsCtrl($scope, Item, Loader, Me, $timeout) {
  Me.authenticated(function (data) {
  });
    
    $scope.slides = [
        {image: 'about/binders.jpg', description: 'Image 00', headline: 'Focus on the story',  text: 'Journalists, broadcasters, producers. You record and tell stories — you don’t archive them. But memories fade, and audio can get lost or degrade. When it’s easy to archive, it’s easy to find the threads that create stories.'},
        {image: 'about/internet_archive.jpg', description: 'Image 01', headline: 'Search to the timestamp', text: 'Sound indexed automatically. All kinds of sound collections benefit from immediate searchability, marked by time-stamps so you can find (and hear) exactly what you’re looking for.'},
        {image: 'about/lithography2.jpg', description: 'Image 02', headline: 'Rediscover material', text: 'Liberate treasure troves of sound. Robust search is great for research and production. Explore your sounds and the public repository by keyword, date, contributor, location, and more. Trapped voices from around the world are waiting to be discovered.'},
        {image: 'about/lithography.jpg', description: 'Image 03', headline: 'Integrate with workflows', text: 'Organize sound from the bottom up. We’re paying close attention to the lifecycle of digital sound in the wild. We’re sharing our learning with you: through blog posts, webinars, open source software contributions and a free public plan. We’re entering a new frontier of sound, building tools that enable new creative opportunities and wider distribution.'},
        {image: 'about/video.jpg', description: 'Image 04', headline: 'Save time, find new audiences', text: 'Built to work. We’ve done the heavy lifting and put lots of tools in one place: transcription, cataloging, storage, preservation, web formatting, and processing huge backlogs of digital sound. We’ve tested the tools through rigorous user-centered design. Our partners include radio stations and producers, oral history archives, universities, and media distributors.'}
    ]; 
    
    $scope.currentIndex = 0;

    $scope.setCurrentSlideIndex = function (index) {
        $scope.currentIndex = index;
    };

    $scope.isCurrentSlideIndex = function (index) {
        return $scope.currentIndex === index;
    };
    
    $scope.prevSlide = function () {
                $scope.currentIndex = ($scope.currentIndex < $scope.slides.length - 1) ? ++$scope.currentIndex : 0;
            };

    $scope.nextSlide = function () {
        $scope.currentIndex = ($scope.currentIndex > 0) ? --$scope.currentIndex : $scope.slides.length - 1;
    };      
}])

// .animation('.slide-animation', function () {
//   return {
//     addClass: function (element, className, done) {
//         if (className == 'ng-hide') {
//           TweenMax.to(element, 0.5, {left: -element.parent().width(), onComplete: done });
//         }
//         else {
//           done();
//         }
//     },
//     removeClass: function (element, className, done) {
//         if (className == 'ng-hide') {
//           TweenMax.set(element, { left: element.parent().width() });
//           TweenMax.to(element, 0.5, {left: 0, onComplete: done });
//         }
//         else {
//           done();
//         }
//     }
//   };
// });