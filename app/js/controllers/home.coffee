'use strict'

###*
 # @ngdoc 
 # @name HomeCtrl
 # @description 
 # 
 # 
###


angular.module('starter')
.controller 'HomeCtrl', [
  '$scope'
  '$rootScope' 
  '$timeout'
  '$ionicPlatform'
  '$ionicScrollDelegate'
  'deviceReady'
  ($scope, $rootScope, $timeout, $ionicPlatform, $ionicScrollDelegate, deviceReady)->

    $scope.deviceReady.waitP().then (platform)->
      $scope.device = platform # deviceReady.device()
      return

    $scope.watch = {
      items : []
    }

    $scope.on = {
    }


    $scope.$on '$ionicView.loaded', ()->
      _init()
      console.log 'HomeCtrl $ionicView.loaded'
      # once per controller load, setup code for view
      return

    $scope.$on '$ionicView.beforeEnter', ()->
      return 

    $scope.$on '$ionicView.enter', ()->
      console.log 'HomeCtrl $ionicView.enter'
      
      return 


    $scope.$on '$ionicView.leave', ()-> 
      return 

    $scope.$on 'collection-repeat.changed', (ev, items)->
      $scope.watch.items = items
      $ionicScrollDelegate.$getByHandle('collection-repeat-wrap').resize()
      return



    _init = ()->
      items = $scope.watch.items
      $scope.$broadcast 'collection-repeat.changed', items
      
  ]

