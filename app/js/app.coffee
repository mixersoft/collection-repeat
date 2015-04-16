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
  'plugin.cameraRoll'
])


.value '$platform', {}

.config ['$ionicConfigProvider', 
  ($ionicConfigProvider)->
    return
]
.run [
  '$ionicPlatform', '$platform'
  ($ionicPlatform, $platform)->
    window.$platform = $platform

    $ionicPlatform.ready ()->
      # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
      # for form inputs)
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true) if window.cordova?.plugins.Keyboard
      # org.apache.cordova.statusbar required
      StatusBar.styleDefault() if window.StatusBar?
      # platform
      _.extend $platform, _.defaults ionic.Platform.device(), {
          available: false
          cordova: false
          platform: 'browser'
          uuid: 'browser'
          isDevice: ionic.Platform.isWebView()
          isBrowser: ionic.Platform.isWebView() == false
        }
      $platform.id = $platform.uuid
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
      abstract: true
      views: {
        'menuContent': {
          templateUrl: "/partials/camera-roll-gallery.html"
          controller: 'CameraRollGalleryCtrl'
        }
      }
    })

    .state('app.camera-roll.small', {
      url: "/small"
    })

    .state('app.camera-roll.preview', {
      url: "/preview"
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
