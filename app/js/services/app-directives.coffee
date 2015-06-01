'use strict'

###*
 # @ngdoc directive
 # @name onTheGoApp.service:directives
 # @description
 # # directives
###


### 
# directive: lazy-src
# load img.src from the following sources, in order of priority
#   imgCacheSvc (browser/WebView FileURL)
#   cameraRoll.dataURL[] (dataURL, FileURL or parse URL)
#   lorempixel (for brower debug)
# 
# uses $q.promise to load src from promise if not immediately available
#
# attributes: 
#   lazySrc: UUID of photo, used to fetch img.src
#   spinner: add ion loading-c spinner, show during img.load
#   format: [thumbnail, preview]
# 
###
angular.module('starter') 

.directive 'map', [ ()->
  return {
    restrict: 'E',
    scope: {
      onCreate: '&'
      latlon: '='
      # template: <map on-create="mapCreated(map)"" latlon="43.07493,-89.381388"></map>
    },
    link: ($scope, $element, $attr)->

      _map = null
      _initialize = ()->
        # 43.07493, -89.381388
        return if !$scope.latlon
        $scope.latlon = $scope.latlon.split(',') if _.isString $scope.latlon
        [lat,lon] = $scope.latlon
        # [lat,lon] = [43.07493, -89.381388]
        mapOptions = {
          center: new google.maps.LatLng(lat, lon),
          zoom: 16,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        }
        _map = new google.maps.Map($element[0], mapOptions)

        $scope.onCreate({map: _map})
        # // Stop the side bar from dragging when mousedown/tapdown on the map
        google.maps.event.addDomListener $element[0], 'mousedown', (e)->
          e.preventDefault();
          return false;

      $scope.$watch 'latlon', (newVal, oldVal)->
        return if !newVal 
        return _initialize() if !_map
        newVal = newVal.split(',') if _.isString newVal
        [lat,lon] = newVal
        _map.setCenter(new google.maps.LatLng(lat, lon))
        return 

      if document.readyState == "complete" 
        _initialize() 
      else
        google.maps.event.addDomListener(window, 'load', _initialize);
  }
]

.directive 'lazySrc', [
  'deviceReady', 'PLUGIN_CAMERA_CONSTANTS', 'cameraRoll', 'imageCacheSvc', '$rootScope', '$q', '$parse'
  (deviceReady, CAMERA, cameraRoll, imageCacheSvc, $rootScope, $q, $parse)->

    _queued = {}
    $rootScope.$on 'cameraRoll.fetchPhotosFromQueue', (ev, args)->
      _.each args.photos, (photo)->
        $el = _queued[photo.UUID]
        return if !$el
        # console.log "queue fetch, resp=" + JSON.stringify _.pick photo, ['UUID', 'data']
        return if $el.attr('lazy-src') != photo.UUID # stale
        $el.attr('src', photo.data) 
        delete _queued[photo.UUID]
        return

    _getAsSnappiSqThumb = (src='')->
      return src if src.indexOf('snaphappi.com/svc') == -1  # autoRender not available
      parts = src.split('/')
      return src if parts[parts.length-1].indexOf('sq~') == 0 # already an sq~ URL
      parts.push( '.thumbs/sq~' + parts.pop() )
      return parts.join('/')

    _setLazySrc = (element, UUID, format)->
      # console.log '\nsetLazySrc for UUID='+UUID
      throw "ERROR: asset is missing UUID" if !UUID
      IMAGE_SIZE = format || 'thumbnail'

      # priorities: stashed FileURL > cameraRoll.dataURL > photo.src
      scope = element.scope()
      photo = scope.item || scope.photo  # TODO: refactor in TopPicks, use scope.photo

      isWorkorder = $rootScope.isStateWorkorder() 
      isOrder = $rootScope.$state.includes('app.orders')
      isMoment = IMAGE_SIZE=='thumbnail' && (isWorkorder || isOrder)
      isBrowser = !isDevice =  deviceReady.device().isDevice

      if isDevice 
        # get updated values from cameraRoll.map()
        mappedPhoto = _.find( cameraRoll.map(), {UUID: photo.UUID})
        _.extend( photo, mappedPhoto) if mappedPhoto


      if isMoment && isOrder
        if isOrder && photo.src?.indexOf('file:') == 0
          return photo.src # element.attr('src', src)
        else if isRemote = (photo.deviceId != $rootScope.device.id)
          thumbSrc = _getAsSnappiSqThumb(photo.src)
          return thumbSrc # element.attr('src', thumbSrc)
        # else continue to bottom to get local img


      if isMoment && isWorkorder # try to use /sq~ images from autoRender
        thumbSrc = _getAsSnappiSqThumb(photo.src || photo.woSrc)
        return thumbSrc # element.attr('src', thumbSrc)


      # TODO: confirm photo.from=='PARSE' are all photos from not in CameraRoll
      # what about cameraRoll phtoos with an OLD deviceId?
      if isWorkorder || photo.from=='PARSE' # preview
        return photo.src || photo.woSrc # element.attr('src', photo.src || photo.woSrc) 

      if isBrowser && photo.from == 'PARSE' 
        # user sign-in viewing topPicks from browser
        return photo.src # element.attr('src', photo.src) 

      # return if isBrowser && !photo # digest cycle not ready yet  
      if !isWorkorder && isBrowser && window.TEST_DATA # DEMO mode
        return _useLoremPixel(element, UUID, format)

      if isBrowser
        return # window.TEST_DATA not ready yet
      ##
      #
      # NOTE: src values AFTER this point are retrieved async, update element directly
      #
      ##

      # console.log "lazySrc notCached for format=" + format + ", UUID="+UUID
      if isBrowser
        throw "_setLazySrc() img.src not found for isBrowser==true and " + [UUID, format].join(':')

      # isDevice so check CameraRoll with promise
      options = {
        size: IMAGE_SIZE
        DestinationType : CAMERA.DestinationType.FILE_URI 
      }
      # options.DestinationType = CAMERA.DestinationType.DATA_URL if IMAGE_SIZE=='preview'
      cameraRoll.getPhoto_P( UUID, options ).then (resp)->
        if resp == 'queued'
          _queued[UUID] = element
          return
        # stashed > cameraRoll
        if options.DestinationType == CAMERA.DestinationType.FILE_URI
          imageCacheSvc.stashFile(UUID, IMAGE_SIZE, resp.data, resp.dataSize) # FILE_URI
        else if options.DestinationType == CAMERA.DestinationType.DATA_URL && IMAGE_SIZE == 'preview'
          imageCacheSvc.cordovaFile_USE_CACHED_P(element, resp.UUID, resp.data) 
        else 
          'not caching DATA_URL thumbnails'

        if element.attr('lazy-src') != resp.UUID
          throw '_setLazySrc(): collection-repeat changed IMG[lazySrc] before cameraRoll image returned'
        else 
          element.attr('src', resp.data) 
        return
      .catch (error)->
        console.warn "_setLazySrc():", error
        return 
      return null # src will be set async from event='cameraRoll.fetchPhotosFromQueue'
        

    _useLoremPixel = (element, UUID, format)->
      console.error "ERROR: using lorempixel from device" if deviceReady.device().isDevice
      scope = element.scope()
      switch format
        when 'thumbnail'
          options = scope.options  # set by otgMoment`
          src = TEST_DATA.lorempixel.getSrc(UUID, options.thumbnailSize, options.thumbnailSize)
        when 'preview'
          src = scope.item?.src
          src = TEST_DATA.lorempixel.getSrc(UUID, scope.item.originalWidth, scope.item.originalHeight) if !src
      return src # element.attr('src', src) 

    # from onImgLoad attrs.spinner
    _spinnerMarkup = '<i class="icon ion-load-c ion-spin light"></i>'
    _clearGif = 'img/clear.gif'  
    _handleLoad = (ev)->
      $elem = angular.element(ev.currentTarget)
      if $elem.attr('src') == _clearGif
        UUID = $elem.attr('lazy-src')
        # console.log "img.src=clearGif error, UUID="+UUID
        return 
      $elem.removeClass('loading')
      $elem.next().addClass('hide')  if $elem.attr('spinner')?
      onImgLoad = $elem.attr('on-photo-load')
      if onImgLoad?
        fn = $parse(onImgLoad) 
        scope = $elem.scope()
        scope.$apply ()->
          fn scope, {$event: ev}
          return
      return

    _handleError = (ev)->
      $elem = angular.element(ev.currentTarget)
      UUID = $elem.attr('lazy-src')
      console.error "img.onerror, UUID="+UUID+", src="+ev.currentTarget.src[-30..]
      return


    return {
      restrict: 'A'
      scope: false
      link: (scope, element, attrs) ->
        format = attrs.format

        attrs.$observe 'lazySrc', (UUID)->
          if deviceReady.device().isDevice==null
            console.error "ERROR: using lazySrc BEFORE deviceReady.waitP()" 
            return 
          if !UUID
            console.log "$$$ attrs.$observe 'lazySrc', UUID+" + UUID
            return 
          # element.attr('uuid', UUID)
          src = _setLazySrc(element, UUID, format)
          # element.attr('src', _clearGif) if !src
          element.attr('src', src) if src
          element.addClass('loading')
          element.next().removeClass('hide') if element.attr('spinner')?
          return src

        element.on 'load', _handleLoad
        # element.on 'error', _handleError
        scope.$on 'destroy', ()->
          element.off _handleLoad
          element.off _handleError
          return
        element.after(_spinnerMarkup) if attrs.spinner?
        return
  }
]


.directive 'onImgLoad', ['$parse' , ($parse)->
  # add ion-animation.scss
  spinnerMarkup = '<i class="icon ion-load-c ion-spin light"></i>'
  _clearGif = 'img/clear.gif'
  _handleLoad = (ev, photo, index)->
    $elem = angular.element(ev.currentTarget)
    $elem.removeClass('loading')
    $elem.next().addClass('hide')
    onImgLoad = $elem.attr('on-img-load')
    fn = $parse(onImgLoad)
    scope = $elem.scope()
    scope.$apply ()->
      fn scope, {$event: ev}
      return
    return
  _handleError = (ev)->
    console.error "img.onerror, src="+ev.currentTarget.src


  return {
    restrict: 'A'
    link: (scope, $elem, attrs)->


      # NOTE: using collection-repeat="item in items"
      attrs.$observe 'ng-src', ()->
        $elem.addClass('loading')
        $elem.next().removeClass('hide')
        return

      $elem.on 'load', _handleLoad
      $elem.on 'error', _handleError
      scope.$on 'destroy', ()->
        $elem.off _handleLoad
        $elem.off _handleError
      $elem.after(spinnerMarkup)
      return
    }
  ]

  
.service 'PtrService', [
  '$timeout'
  '$ionicScrollDelegate' 
  ($timeout, $ionicScrollDelegate)-> 
    ###
     * Trigger the pull-to-refresh on a specific scroll view delegate handle.
     * @param {string} delegateHandle - The `delegate-handle` assigned to the `ion-content` in the view.
     * see: https://calendee.com/2015/04/25/trigger-pull-to-refresh-in-ionic-framework-apps/
    ###
    this.triggerPtr = (delegateHandle)->

      $timeout ()->

        scrollView = $ionicScrollDelegate.$getByHandle(delegateHandle).getScrollView();

        return if (!scrollView)

        scrollView.__publish(
          scrollView.__scrollLeft, -scrollView.__refreshHeight,
          scrollView.__zoomLevel, true)

        scrollView.refreshStartTime = Date.now()

        scrollView.__refreshActive = true
        scrollView.__refreshHidden = false
        scrollView.__refreshShow() if scrollView.__refreshShow
        scrollView.__refreshActivate() if scrollView.__refreshActivate
        scrollView.__refreshStart() if scrollView.__refreshStart

    return
        
]


.directive 'notify', ['notifyService'
  (notifyService)->
    return {
      restrict: 'A'
      scope: true
      templateUrl: 'views/template/notify.html'
      link: (scope, element, attrs)->
        scope.notify = notifyService

        if notifyService._cfg.debug
          window.debug.notify = notifyService        
        return
    }

]

