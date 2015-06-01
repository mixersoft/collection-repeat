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
  'ngCordova',
  'ngStorage'
  'partials'
  'plugin.cameraRoll'
  'snappi.util'
  'parse.backend'
])

.config ['$ionicConfigProvider', 
  ($ionicConfigProvider)->
    return
]
.run [
  '$ionicPlatform', '$rootScope', 'deviceReady', 'PARSE_CREDENTIALS'
  ($ionicPlatform, $rootScope, deviceReady, PARSE_CREDENTIALS)->
    Parse.initialize( PARSE_CREDENTIALS.APP_ID, PARSE_CREDENTIALS.JS_KEY )
    $rootScope.sessionUser = Parse.User.current()
    window.debug = {}

    $ionicPlatform.ready ()->
      # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
      # for form inputs)
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true) if window.cordova?.plugins.Keyboard
      # org.apache.cordova.statusbar required
      StatusBar.styleDefault() if window.StatusBar?
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

    .state('app.home', {
      url: "/home",
      views: {
        'menuContent': {
          templateUrl: "/partials/home.html"
          controller: 'HomeCtrl'
        }
      }
    })

    .state('app.profile', {
      url: "/profile",
      views: {
        'menuContent': {
          templateUrl: "/partials/profile.html"
          controller: 'UserCtrl'
        }
      }
    })

    .state('app.profile.sign-in', {
      url: "/sign-in",
      # views: {
      #   'menuContent': {
      #     templateUrl: "/partials/templates/sign-in.html"
      #     controller: 'UserCtrl'
      #   }
      # }
    })


    # // if none of the above states are matched, use this as the fallback
    $urlRouterProvider.otherwise('/app/home');
]

.controller 'AppCtrl', [
  '$scope'
  '$rootScope' , '$state'
  '$timeout'
  'deviceReady'
  '$localStorage'
  ($scope, $rootScope, $state, $timeout, deviceReady, $localStorage)->
    $scope.deviceReady = deviceReady

    _.extend $rootScope, {
      $state : $state
      user : $rootScope.sessionUser?.toJSON() || {}
      device : null # deviceReady.device(platform)
    }

    window.debug['$platform'] = $rootScope.localStorage = $localStorage
    if $rootScope.localStorage['device']?
      platform = $rootScope.localStorage['device']
      window.debug['$platform'] = $rootScope['device'] = deviceReady.device(platform)
      console.log 'localStorage $platform', window.debug['$platform']
    else       
      # platform
      deviceReady.waitP().then (platform)->
        window.debug['$platform'] = $rootScope['device'] = $rootScope.localStorage['device'] = platform
        console.log 'deviceReady $platform', window.debug['$platform']

    window.debug['ls'] = $localStorage

    return


  ]
