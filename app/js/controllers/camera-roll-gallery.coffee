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
  'imageCacheSvc'
  ($scope, $rootScope, $timeout, $ionicPlatform, $ionicScrollDelegate, $state, cameraRoll, CAMERA, imageCacheSvc)->

    LIMIT = 100

    TARGET_WIDTH = 320
    TARGET_TYPE = 'FILE_URI'

    defaults = {
      'iPhone': 
        targetWidth: 320
        targetHeight: 320  
        autoRotate: true       
      'iPhone6@2x': 
        targetWidth: 750
        targetHeight: 750
        autoRotate: true
      'iPhone6plus2@x': 
        targetWidth: 1080
        targetHeight: 1080
        autoRotate: true
    }

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams, error)->
      if $state.includes('app.camera-roll')
        $scope.watch.targetWidth = toParams.size
        $scope.watch.targetType = toParams.type     
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
      targetWidth: null
      targetType: null # [FILE_URI | DATA_URL]
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
      fetchSrc: (i)->
        return 0 if _.isEmpty(this.items) || i >= this.items.length
        
        photo = this.items[i]
        src = imageCacheSvc.get(photo.UUID, $scope.watch.targetWidth, $scope.watch.targetType)
        if src
          photo.isLoading = false
          return photo.src = src 

        # load from plugin.cameraRoll
        options = {}
        if isNaN($scope.watch.targetType)
          options['DestinationType'] = CAMERA.DestinationType[$scope.watch.targetType]
        else 
          options['DestinationType'] = $scope.watch.targetType

        if isNaN($scope.watch.targetWidth)
          options['size'] = $scope.watch.targetWidth
        else
          options['size'] = options['targetWidth'] = options['targetHeight'] = parseInt $scope.watch.targetWidth

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
        }] 
        $scope.$broadcast 'collection-repeat.changed', testData
      else 
        $scope.watch.items = cameraRoll.map()[(-1*LIMIT)...] 
        $ionicScrollDelegate.$getByHandle('collection-repeat-wrap').resize()

    $ionicPlatform.ready ()->
      return cameraRoll.mapP(null, 'force')
      .then (mapped)->
        console.log "mapped cameraRoll: ", JSON.stringify {count: mapped.length, first: mapped[0] } 
      .catch (err)->
        console.error "Error mapping cameraRoll ", err

      
  ]

