angular.module('Directory.dashboard.controllers', ['Directory.loader', 'Directory.user'])
.controller('DashboardCtrl', [ '$scope', 'Item', 'Loader', 'Me', '$timeout', function ItemsCtrl($scope, Item, Loader, Me, $timeout) {
  Me.authenticated(function (data) {
  });

  if (window.location.pathname == "/"){
    mixpanel.track(
      "Home Page"
    );
  };
    
    $scope.about_slides = [
      {image: null, description: 'Image 00', headline: 'The web is getting noisier', text: null, video: '//player.vimeo.com/video/74795063?api=1', teaser: null},
      {image: 'about/oldbooks.jpg', description: 'Image 01', headline: 'Focus on the story',  text: 'You record, organize, and share stories — you don’t archive them. But memories fade, and audio can get lost or degrade. When it’s easy to save and search sound, it’s easy to find the threads that create stories.', teaser: 'Journalists, archivists, media producers.'},
     {image: 'about/binders.jpg', description: 'Image 02', headline: 'Index sound automatically', text: 'Sound collections of all sizes benefit from immediate searchability, marked by time-stamps so producers — and audiences — can find and hear exactly what they\'re looking for.', teaser: 'Easy access and search for sound.'},
     {image: 'about/video.jpg', description: 'Image 03', headline: 'Find lost audio', text: 'Easily indexed and organized sound means quicker workflows and new access to source material. Explore your sounds and the public archive by keyword, date, contributor, location, and more. Trapped voices are waiting to be discovered.', teaser: 'Rediscover material.'},
     {image: 'about/digitalwaves.jpg', description: 'Image 04', headline: 'Add value to sound', text: 'We’re paying close attention to the lifecycle of audio on the web. Pop Up Archive\'s simple tools add value to sound by enabling new creative opportunities and wider distribution. We’re sharing our learning through blog posts, webinars, open source software contributions and a free public plan.', teaser: 'A new frontier of digital audio.'},
     {image: 'about/internet_archive.jpg', description: 'Image 05', headline: 'Integrate with workflows', text: 'We’ve done the heavy lifting and tethered lots of services in one place: transcription, cataloging, storage, preservation, a hypermedia API, and a platform for processing large amounts of digital sound. Rigorous user testing is at the heart of our design process. Pop Up Archive\'s partners include radio stations and producers, oral history archives, universities, and media distributors.', teaser: 'Actually simple.'}
    ];
    
    $scope.currentIndex = 0;

    $scope.setCurrentSlideIndex = function (index) {
      $scope.currentIndex = index;
    };

    $scope.isCurrentSlideIndex = function (index) {
      return $scope.currentIndex === index;
    };
    
    $scope.prevSlide = function (slides) {
      $scope.currentIndex = ($scope.currentIndex < slides.length - 1) ? ++$scope.currentIndex : 0;
    };

    $scope.nextSlide = function (slides) {
      $scope.currentIndex = ($scope.currentIndex > 0) ? --$scope.currentIndex : slides.length - 1;
    };  
    
    $scope.subscribe = function () {
      window.location = "/users/sign_up?plan_id=community";
      mixpanel.track(
        "Clicked Get Started"
      );
    }    
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