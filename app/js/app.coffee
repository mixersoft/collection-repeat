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
      url: "/camera-roll/:size/:type",
      views: {
        'menuContent': {
          templateUrl: "/partials/camera-roll-gallery.html"
          controller: 'CameraRollGalleryCtrl'
        }
      }
    })



    # // if none of the above states are matched, use this as the fallback
    $urlRouterProvider.otherwise('/app/dynamic-h');
]

.directive 'onImgLoad', ['$parse' , ($parse)->
  spinnerMarkup = '<i class="icon ion-load-c ion-spin light"></i>'
  _handleLoad = (ev, photo, index)->
    $elem = angular.element(ev.currentTarget)
    $elem.removeClass('loading')
    $elem.next().addClass('hide')
    onImgLoad = $elem.attr('on-photo-load')
    fn = $parse(onImgLoad)
    scope = $elem.scope()
    scope.$apply ()->
      fn scope, {$event: ev}
      return
    return

  return {
    restrict: 'A'
    link: (scope, $elem, attrs)->


      # NOTE: using collection-repeat="item in items"
      attrs.$observe 'ngSrc', ()->
        $elem.addClass('loading')
        $elem.next().removeClass('hide')
        return

      $elem.on 'load', _handleLoad
      scope.$on 'destroy', ()->
        $elem.off _handleLoad
      $elem.after(spinnerMarkup)
      return
    }
  ]

.controller 'AppCtrl', [
  '$scope'
  '$rootScope' 
  '$timeout'
  '$ionicPlatform'
  ($scope, $rootScope, $timeout, $ionicPlatform)->
    return
  ]
