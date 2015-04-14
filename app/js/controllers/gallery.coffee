'use strict'

###*
 # @ngdoc 
 # @name GalleryCtrl
 # @description 
 # 
 # 
###


angular.module('starter')
.controller 'GalleryCtrl', [
  '$scope'
  '$rootScope' 
  '$timeout'
  '$ionicPlatform'
  ($scope, $rootScope, $timeout, $ionicPlatform)->


    $scope.$on '$ionicView.loaded', ()->
      console.log 'GalleryCtrl $ionicView.loaded'
      # once per controller load, setup code for view
      return


    $scope.$on '$ionicView.beforeEnter', ()->
      return 

    $scope.watch = {
      $platform : $platform
    }

    $scope.on = {
    }

    $scope.$on '$ionicView.enter', ()->
      console.log 'GalleryCtrl $ionicView.enter'
      return 


    $scope.$on '$ionicView.leave', ()-> 
      return 

  ]