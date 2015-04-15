'use strict'

###*
 # @ngdoc overview
 # @name starter
 # @description
 # # starter
 #
 # Main module of the application.
###
angular
.module('starter', [
  'ionic',
  # 'ngCordova',
  'partials'
])
.config ['$ionicConfigProvider', 
  ($ionicConfigProvider)->
    return
]
.run [
  '$ionicPlatform'
  ($ionicPlatform)->
    window.$platform = {}

    $ionicPlatform.ready ()->
      # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
      # for form inputs)
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true) if window.cordova?.plugins.Keyboard
      # org.apache.cordova.statusbar required
      StatusBar.styleDefault() if window.StatusBar?
      # platform
      _.extend window.$platform, _.defaults ionic.Platform.device(), {
          available: false
          cordova: false
          platform: 'browser'
          uuid: 'browser'
          isDevice: ionic.Platform.isWebView()
          isBrowser: ionic.Platform.isWebView() == false
        }
      if $platform.cordova
        angular.noop()

      console.log '$platform', $platform
    return
]
.config [
  '$stateProvider', 
  '$urlRouterProvider', 
  ($stateProvider, $urlRouterProvider)-> 
  
    $stateProvider

    .state('app', {
      url: "/app",
      abstract: true,
      templateUrl: "/partials/templates/menu.html",
      controller: 'AppCtrl'
    })

    .state('app.static-h', {
      url: "/static-h",
      views: {
        'menuContent': {
          templateUrl: "/partials/simple.html"
          controller: 'GalleryCtrl'
        }
      }
    })

    .state('app.dynamic-h', {
      url: "/dynamic-h",
      views: {
        'menuContent': {
          templateUrl: "/partials/gallery.html"
          controller: 'GalleryCtrl'
        }
      }
    })

    .state('app.camera-roll', {
      url: "/camera-roll",
      views: {
        'menuContent': {
          templateUrl: "/partials/gallery.html"
          controller: 'CameraRollGalleryCtrl'
        }
      }
    })
    # // if none of the above states are matched, use this as the fallback
    $urlRouterProvider.otherwise('/app/dynamic-h');
]

.controller 'AppCtrl', [
  '$scope'
  '$rootScope' 
  '$timeout'
  '$ionicPlatform'
  ($scope, $rootScope, $timeout, $ionicPlatform)->
    return
  ]
