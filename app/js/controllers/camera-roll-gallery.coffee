'use strict'

###*
 # @ngdoc 
 # @name CameraRollGalleryCtrl
 # @description 
 # 
 # 
###


# ionic plugin add /dev.snaphappi.com/snappi-onthego/CordovaNativeMessenger

angular.module('starter')
.controller 'CameraRollGalleryCtrl', [
  '$scope'
  '$rootScope' 
  '$timeout'
  '$ionicPlatform'
  '$ionicScrollDelegate'
  '$state', 
  'cameraRoll'
  'PLUGIN_CAMERA_CONSTANTS'
  ($scope, $rootScope, $timeout, $ionicPlatform, $ionicScrollDelegate, $state, cameraRoll, CAMERA)->

    LIMIT = 100
    SIZE = 'small'

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams, error)->
      if $state.includes('app.camera-roll.small')
        $scope.watch.size = 'small'
      if $state.includes('app.camera-roll.preview')
        $scope.watch.size = 'preview'        
      return 

    $scope.$on '$ionicView.loaded', ()->
      console.log 'CameraRollGalleryCtrl $ionicView.loaded'
      # once per controller load, setup code for view
      return


    $scope.$on '$ionicView.beforeEnter', ()->
      return 

    $scope.watch = {
      $platform : $platform
      items: []
      size: null
      getHeight: (i)->
        return 0 if _.isEmpty(this.items) || i >= this.items.length
        photo = this.items[i]
        imgH = photo.originalHeight
        photo.scaledH = scaledH = Math.round (window.innerWidth-20) / photo.originalWidth * imgH
        headerH = 37
        footerH = 49
        cardPaddingV = 2 * 5
        h = scaledH + headerH + footerH + cardPaddingV  # 372 px
        console.log "collection-repeat, getHeight() index=%d, height=%d", i, h
        this.fetchSrc(i)
        return h
      fetchSrc: (i, type="FILE_URI")->
        return 0 if _.isEmpty(this.items) || i >= this.items.length
        
        photo = this.items[i]
        return photo.srcSize[$scope.watch.size] if photo.srcSize?[$scope.watch.size]?
        # load from plugin.cameraRoll
        options = {
          size: $scope.watch.size || SIZE
          DestinationType: CAMERA.DestinationType[type]
        }
        photo.isLoading = true
        cameraRoll.getPhoto( photo.UUID, options)
        return 
    }

    $scope.on = {
    }

    $scope.$on '$ionicView.enter', ()->
      console.log 'CameraRollGalleryCtrl $ionicView.enter'
      $ionicPlatform.ready ()->
        _reset()
      return 


    $scope.$on '$ionicView.leave', ()-> 
      return 

    $scope.$on 'collection-repeat.changed', (ev, items)->
      $scope.watch.items = items
      $ionicScrollDelegate.$getByHandle('collection-repeat-wrap').resize()
      return

    $scope.$on 'sync.cameraRollComplete', (ev, options)->
      $scope.watch.items = cameraRoll.map()[(-1*LIMIT)...] if options.changed == true
      return


    _reset = ()->
      if $platform.isBrowser
        testData = [{
          "UUID":"48D5CC58-4E86-4E56-917F-26C618C0521F/L0/001",
          "favorite":false, "hidden":false,
          "mediaType":1,"mediaSubTypes":0,
          "burstIdentifier":"DF4B2BC2-4105-40A8-BC21-80D2E6F246E6","representsBurst":false,"burstSelectionTypes":0
          "originalHeight":3264,"originalWidth":2448,"dateTaken":"2014-10-11T18:46:53+03:00","from":"CameraRoll",
          "src": null
          "isLoading": true
          "srcSize":{}
        }] 
        $scope.$broadcast 'collection-repeat.changed', testData
      else 
        $ionicScrollDelegate.$getByHandle('collection-repeat-wrap').resize()

    $ionicPlatform.ready ()->
      return cameraRoll.mapP(null, 'force')
      .then (mapped)->
        console.log "mapped cameraRoll: ", JSON.stringify {count: mapped.length, first: mapped[0] } 
      .catch (err)->
        console.error "Error mapping cameraRoll ", err

      
  ]

