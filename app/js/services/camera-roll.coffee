'use strict'

###*
 # @ngdoc factory
 # @name cameraRoll
 # @description 
 # methods for accessing snappiAssetsPicker cordova plugin
 # 
###


angular
.module 'plugin.cameraRoll', []
.value 'PLUGIN_CAMERA_CONSTANTS', {
  DestinationType:
    DATA_URL: 0
    FILE_URI: 1
  EncodingType:
    JPEG: 0
    PNG: 1
  PictureSourceType:
    PHOTOLIBRARY: 0
    CAMERA: 1
    SAVEDPHOTOALBUM: 2
  MediaType:
    PICTURE: 0
    VIDEO: 1
    ALLMEDIA: 2
  PopoverArrowDirection:
    ARROW_UP: 1
    ARROW_DOWN: 2
    ARROW_LEFT: 4
    ARROW_RIGHT: 8
    ARROW_ANY: 15
}

.value 'imageCacheSvc', {
  empty: true
}

.factory 'cameraRoll', [
  '$q', '$timeout', '$rootScope', 
  '$platform'
  'PLUGIN_CAMERA_CONSTANTS', 'pluginCameraRoll', 'imageCacheSvc'
  ($q, $timeout, $rootScope,  $platform, CAMERA, pluginCameraRoll, imageCacheSvc)->
    _getAsLocalTime = (d, asJSON=true)->
        d = new Date() if !d    # now
        d = new Date(d) if !_.isDate(d)
        throw "_getAsLocalTimeJSON: expecting a Date param" if !_.isDate(d)
        d.setHours(d.getHours() - d.getTimezoneOffset() / 60)
        return d.toJSON() if asJSON
        return d


    self = {
      _queue: {}  # array of DataURLs to fetch, use with debounce
      _mapAssetsLibrary: []  # stash in loadMomentsFromCameraRoll()
      # array of photos, use found = _.findWhere cameraRoll.map(), (UUID: uuid)
      # props: id->UUID, date, src, caption, rating, favorite, topPick, shared, exif
      #   plugin adds: dateTaken, origH, origW, height, width, crop, orientation,
      #   parse adds: assetId, from, createdAt, updatedAt
      dataURLs: {
        preview: {}     # indexBy UUID
        thumbnail: {}   # indexBy UUID
      }
      readyP: ()->
        return 

      map: (snapshot)->
        self._mapAssetsLibrary = angular.copy snapshot if `snapshot!=null`
        return self._mapAssetsLibrary

      
      mapP: (options, force=null)->
        if !force && self._mapAssetsLibrary?
          $rootScope.$broadcast('sync.cameraRollComplete', {changed:false})
          return $q.when self._mapAssetsLibrary 

        return pluginCameraRoll.mapAssetsLibraryP(options) 
        .then ( mapped )->
          _.each mapped, (o)->
            o.from = 'CameraRoll'
            o.deviceId = $platform.uuid
            o.src = null
            return
          if _.isEmpty self._mapAssetsLibrary
            self._mapAssetsLibrary = mapped 
            $rootScope.$broadcast('sync.cameraRollComplete', {changed:true})
          else if force == 'merge'
            # refresh cameraRoll should not reset PARSE photos. only do so on clearPhotos_PARSE
            # MERGE into existing map() to avoid topPicks flash
            added = _.difference _.pluck(mapped, 'UUID'), _.pluck(self._mapAssetsLibrary, 'UUID')
            removed = _.difference _.pluck(self.filterDeviceOnly(), 'UUID'), _.pluck(mapped, 'UUID') 
            changed = false
            if removed.length
              self._mapAssetsLibrary = _.filter self._mapAssetsLibrary, (o)->
                return removed.indexOf(o.UUID) == -1
            if added.length
              addedObjs = _.filter mapped, (o)->
                return added.indexOf(o.UUID) > -1
              self._mapAssetsLibrary = self._mapAssetsLibrary.concat addedObjs

            # reset favorites
            favorites = {}
            _.each mapped, (o)->
              favorites[o.UUID] = !!o.favorite
              return
            _.each self._mapAssetsLibrary, (o)->
              return if favorites[o.UUID]? 
              return if o.favorite == favorites[o.UUID]
              o.favorite = favorites[o.UUID]
              changed = true
              return

            changed = changed || removed.length || added.length
            $rootScope.$broadcast('sync.cameraRollComplete', {changed:true}) if changed
          else if force=='replace'
            # mapped = mapped.concat( self.filterParseOnly() )
            self._mapAssetsLibrary = mapped 
            $rootScope.$broadcast('sync.cameraRollComplete', {changed:true})
          else
            'not updated'
          return self._mapAssetsLibrary


      loadCameraRollP: (options, force='merge')->
        defaults = {
          size: 'thumbnail'
          type: 'favorites,moments' # defaults
          # pluck: ['favorite','mediaType', 'mediaSubTypes', 'hidden']  
          # fromDate: null
          # toDate: null
        }
        options = _.defaults options || {}, defaults
        # options.fromDate = self.getDateFromLocalTime(options.fromDate) if _.isDate(options.fromDate)
        # options.toDate = self.getDateFromLocalTime(options.toDate) if _.isDate(options.toDate)

        start = new Date().getTime()
        return self.mapP(options, force)
        .then (mapped)->
          promise = self.loadFavoritesP(5000) if options.type.indexOf('favorites') > -1
          # don't wait for promise
          return mapped

        .then ( mapped )->

          # end = new Date().getTime()
          # console.log "\n*** mapAssetsLibraryP() complete, elapsed=" + (end-start)/1000
          return mapped if $platform.isBrowser

          # don't wait for promise
          if options.type.indexOf('moments') > -1
            moments = self.loadMomentsFromCameraRoll( mapped )
            promise = self.loadMomentThumbnailsP().then ()->
              # console.log "\n @@@load cameraRoll thumbnails loaded from loadCameraRollP()"
              return

          # cameraRoll ready
          return mapped

        .catch (error)->
          console.warn "ERROR: loadCameraRollP, error="+JSON.stringify( error )[0..100]
          if error == "ERROR: window.Messenger Plugin not available" && $platform.isBrowser
            self._mapAssetsLibrary = [] if force=='replace' && !window.TEST_DATA
            $rootScope.$broadcast 'cameraRoll.loadPhotosComplete', {type:'moments'}
            $rootScope.$broadcast 'cameraRoll.loadPhotosComplete', {type:'favorites'}
            return true
          return $q.reject(error)
        .finally ()->
          return

      loadFavoritesP: (delay=10)->
        # load 'preview' of favorites from cameraRoll, from mapAssetsLibrary()
        favorites = _.filter self.map(), {favorite: true}
        options = {
          size: 'preview'
          type: 'favorites'
        }
        # check against imageCacheSvc
        notCached = _.filter favorites, (photo)->
            return false if imageCacheSvc.isStashed( photo.UUID, options.size ) 
            return false if self.dataURLs[options.size][photo.UUID]?
            return true
        # console.log "\n\n\n*** preloading favorite previews for UUIDs, count=" + notCached.length 
        # console.log notCached
        return self.loadPhotosP(notCached, options, delay)


      loadPhotosP: (photos, options, delay=10)->
        options = _.defaults options || {} , {
          DestinationType: CAMERA.DestinationType.FILE_URI
        }
        return $q.when('success') if _.isEmpty photos
        dfd = $q.defer()
        _fn = ()->
            start = new Date().getTime()
            return pluginCameraRoll.getDataURLForAssetsByChunks_P( 
              photos
              , options                         
              # , null  # onEach, called for cameraRoll thumbnails and favorites
              , (photo)->
                if options.DestinationType == CAMERA.DestinationType.FILE_URI 
                  imageCacheSvc.stashFile(photo.UUID, options.size, photo.data, photo.dataSize) # FILE_URI
              , pluginCameraRoll.SERIES_DELAY_MS 
            )
            .then ()->
              end = new Date().getTime()
              # console.log "\n*** thumbnail preload complete, elapsed=" + (end-start)/1000
              $rootScope.$broadcast 'cameraRoll.loadPhotosComplete', options # for cancel loading timer
              dfd.resolve('success')
            .then ()->
              return

        $timeout ()-> 
            _fn()     
          , delay  
        return dfd.promise   
   

      isDataURL : (src)->
        throw "isDataURL() ERROR: expecting string" if typeof src != 'string'
        return /^data:image/.test( src )

      ## @param options = {UUID: data: or dataURL:}
      ## options.data, options.dataURL:
      ##    dataURL from cameraRoll.addDataURL(),
      ##    fileURL from imageCacheSvc.cordovaFile_USE_CACHED_P, or 
      ##    PARSE URL from workorders
      addDataURL: (size, options)->
        # console.log "\n\n adding for size=" + size
        if !/preview|thumbnail/.test( size )
          return console.warn "ERROR: invalid dataURL size, size=" + size
        _logOnce "sdkhda", "WARNING: NOT truncating to UUID(36), UUID="+options.UUID if options.UUID.length > 36

        imgSrc = options.data || options.dataURL
        self.dataURLs[size][options.UUID] = imgSrc

        if self.isDataURL(imgSrc) # cacheDataURLs
          $timeout ()->
              promise = imageCacheSvc.cordovaFile_CACHE_P( options.UUID, size, imgSrc).then (fileURL)->
                # console.log "\n\n imageCacheSvc has cached dataURL, path=" + fileURL
                self.dataURLs[size][options.UUID] = fileURL
            , 10 
        # console.log "\n\n added!! ************* " 
        return self


      getDateFromLocalTime : (dateTaken)->
        return null if !dateTaken
        if dateTaken.indexOf('+')>-1
          datetime = new Date(dateTaken) 
          # console.log "compare times: " + datetime + "==" +dateTaken
        else 
          # dateTaken contains no TZ info
          datetime = _getAsLocalTime(dateTaken, false) 

        datetime.setHours(0,0,0,0)
        date = _getAsLocalTime( datetime, true)
        return date.substring(0,10)  # like "2014-07-14"








      ### #########################################################################
      # methods for getting photos from cameraRoll, isDevice==true
      ### #########################################################################  

      ### called by: 
          directive:lazySrc AFTER imgCacheSvc.isStashed_P().catch
          otgParse.uploadPhotoFileP
          otgUploader.uploader.type = 'parse'
          NOTE: use getPhoto_P() for noCache = true, i.e. fetch but do NOT cache
      ###
      ###
      # @params UUID, string, iOS example: '1E7C61AB-466A-468A-A7D5-E4A526CCC012/L0/001'
      # @params options object
      #   size: ['thumbnail', 'preview', 'previewHD']
      #   DestinationType : [0,1],  default CAMERA.DestinationType.FILE_URI 
      #   noCache: boolean, default false, i.e. cache the photo using imageCacheSvc.stashFile
      # @return photo object, {UUID: data: dataSize:, ...}
      # @throw error if photo.dataSize == 0
      ###
      getPhoto_P :  (UUID, options)->
        options = _.defaults options || {}, {
          size: 'preview'
          noCache : false
          DestinationType : CAMERA.DestinationType.FILE_URI 
        }

        if getFromCache = options.noCache == false # check imageCacheSvc
          found = self.getPhoto(UUID, options) 
        if isBrowser = $platform.isBrowser 
          found = self.getPhoto(UUID, options) 
        if isWorkorder = $rootScope.isStateWorkorder() 
          # HACK: for now, force workorders to get parse URLS, skip cameraRoll
          # TODO: check cameraRoll if owner is DIY workorder
          # i.e. workorderObj.get('devices').indexOf($platform.id) > -1
          found = self.getPhoto(UUID, options) 
        if found  
          photo = {
            UUID: UUID
            data: found
          }
          return $q.when(found) 
          

        # load from cameraRoll if workorderObj.get('devices').indexOf($platform.id) > -1
        if isDevice = !isBrowser 
          return pluginCameraRoll.getDataURLForAssets_P( 
            [UUID], 
            options, 
            null  # TODO: how should we merge for owner TopPicks?
          ).then (photos)->
              photo = photos[0]   # resolve( photo )
              if photo.dataSize == 0
                return $q.reject {
                  message: "error: dataSize==0"
                  UUID: UUID
                  size: options.size
                }
              return photo
        else 
          return $q.reject {
            message: 'ERROR: getPhoto_P()'
          }



      ### getPhoto if cached, otherwise queue for retrieval, 
          SAVE TO CACHE with imgCacheSvc or cameraRoll.dataURL
        called by: 
          directive:lazySrc
          otgUploader.uploader.type = 'parse'
      ###
      ###
      # @params UUID, string, iOS example: '1E7C61AB-466A-468A-A7D5-E4A526CCC012/L0/001'
      # @params options object
      #   size: ['thumbnail', 'preview', 'previewHD', 'orig'], default options.size=='preview'
      #   DestinationType : [0,1],  default CAMERA.DestinationType.FILE_URI       
      # @return found object { UUID: data: dataSize: }
      #    dataURL from cameraRoll.dataURls,
      #    fileURL from imageCacheSvc.cordovaFile_USE_CACHED_P, or 
      #      pluginCameraRoll.getPhotoForAssets_P([UUID], options.DestinationType=1)
      #    NOTE: PARSE FILE_URI from workorders, photo.src is set directly by directive:lazySrc
      ###
      getPhoto: (UUID, options)->
        options = _.defaults options || {}, {
          size: 'preview'
          DestinationType : CAMERA.DestinationType.FILE_URI 
          # noCache : false     # FORCE cache via queue
        }
        size = options.size
        if !/small|preview|thumbnail/.test size
          throw "ERROR: invalid dataURL size, size=" + size
        
        if options.DestinationType == CAMERA.DestinationType.FILE_URI
          # stashed = imageCacheSvc.isStashed(UUID, size)
          # if stashed
          #   found = {
          #     data: stashed.fileURL
          #     dataSize: stashed.fileSize
          #   }
          'skip'
        else 
          dataURL = self.dataURLs[size][UUID]
          if !dataURL && UUID.length == 36
            dataURL = _.find self.dataURLs[size], (o,key)->
                return o if key[0...36] == UUID
          if dataURL
            found = {
              data: dataURL
              dataSize: dataURL.length
            }
        if found # add extended attributes
          _.defaults found, options
          found['UUID'] = UUID
          return found

        # still not found, add to queue for fetch
          # console.log "image not cached, queuePhoto(UUID)=" + UUID
        self.queuePhoto(UUID, options)
        return null

      # fetch a photo by UUID, AND save to cache
      # called by getPhoto(), but NOT getPhoto_P()
      # self._queue is fetched by:
      # > debounced_fetchPhotosFromQueue 
      #   > fetchPhotosFromQueue 
      #     > getPhotoForAssetsByChunks_P()      
      queuePhoto : (UUID, options)->
        return if $platform.isBrowser
        item = _.defaults {UUID: UUID}, _.pick options, ['size', 'DestinationType']
        self._queue[UUID] = item
        # # don't wait for promise
        self.debounced_fetchPhotosFromQueue()
        # $rootScope.$broadcast 'cameraRoll.queuedPhoto'
        return


      # called by cameraRoll.queuePhoto()
      fetchPhotosFromQueue : ()->
        queuedAssets = self.queue()

        chunks = _.reduce queuedAssets, (result, o)->
            type = o.size + ':' + o.DestinationType
            result[type].push o.UUID
            return result
          , {
            'thumbnail:1': [] # Camera.DestinationType.FILE_URI ==1
            'small:1': []
            'preview:1': []
            'previewHD:1': []
            'thumbnail:0': [] # DATA_URL == 0
            'small:0': []
            'preview:0': []
            'previewHD:0': []            
          }

        promises = []
        _.each chunks, (assets, type)->
          # console.log "\n\n *** fetchPhotosFromQueueP START! size=" + size + ", count=" + assets.length + "\n"
          return if assets.length == 0
          [size, DestinationType] = type.split(':')
          options = {
            size: size
            DestinationType: parseInt(DestinationType)
          }
          promises.push pluginCameraRoll.getDataURLForAssetsByChunks_P(
              assets
              , options
              , (photo)->

                if options.DestinationType == CAMERA.DestinationType.FILE_URI 
                  # imageCacheSvc.stashFile(photo.UUID, options.size, photo.data, photo.dataSize) # FILE_URI
                  found = _.find self._mapAssetsLibrary, {UUID: photo.UUID}
                  throw "Error: cameraRoll item not found in map" if !found
                  found.srcSize = {} if !found.srcSize?
                  found.srcSize[options.size] = photo.data
                  found.src = photo.data
                  found.size = photo.dataSize
                else if options.DestinationType == CAMERA.DestinationType.DATA_URL 
                  self.dataURLs[options.size][photo.UUID] = photo.data
                  found = _.find self._mapAssetsLibrary, {UUID: photo.UUID}
                  throw "Error: cameraRoll item not found in map" if !found
                  found.srcSize = {} if !found.srcSize?
                  found.src = photo.data
                  found.size = photo.data.length
                console.log "cameraRoll loaded, src="+photo.data[-50...]
                found.isLoading = false
            ).then (photos)->
              return photos 

        return $q.all(promises).then (o)->
            # console.log "*** fetchPhotosFromQueueP $q All Done! \n" 
            return

      debounced_fetchPhotosFromQueue : ()->
        return console.log "\n\n\n ***** Placeholder: add debounce on init *********"


      ### #########################################################################
      # END methods for getting photos from cameraRoll, isDevice==true
      ### #########################################################################



      # getter, or reset queue
      queue: (clear, PREVIEW_LIMIT = 50 )->
        self._queue = {} if clear=='clear'

        smallOnes = _.reject self._queue, {size: 'preview'}
        previews = _.filter self._queue, {size: 'preview'}

        if previews.length > PREVIEW_LIMIT
          remainder = previews[PREVIEW_LIMIT..]

        batch = smallOnes.concat previews.slice(0, PREVIEW_LIMIT)
        self._queue = if remainder?.length then _.indexBy( remainder, 'UUID') else {}

        # order by smallOnes then previews
        return batch



      # IMAGE_WIDTH should be computedWidth - 2 for borders
      getCollectionRepeatHeight : (photo, IMAGE_WIDTH)->
        if !IMAGE_WIDTH
          MAX_WIDTH = if $platform.isDevice then 320 else 640
          IMAGE_WIDTH = Math.min(deviceReady.contentWidth()-22, MAX_WIDTH)
        if !photo.scaledH || IMAGE_WIDTH != photo.scaledW
          if photo.originalWidth && photo.originalHeight
            aspectRatio = photo.originalHeight/photo.originalWidth 
            # console.log "index="+index+", UUID="+photo.UUID+", origW="+photo.originalWidth + " origH="+photo.originalHeight
            h = aspectRatio * IMAGE_WIDTH
          else # browser/TEST_DATA
            throw "ERROR: original photo dimensions are missing"
          photo.scaledW = IMAGE_WIDTH  
          photo.scaledH = h
        else 
          h = photo.scaledH
        return h

      # array of moments
      moments: []
      # orders
      orders: [] # order history
      state:
        photos:
          sort: null
          stale: false
    } # end cameraRoll

    self.debounced_fetchPhotosFromQueue = _.debounce self.fetchPhotosFromQueue
        , 1000
        , {
          leading: false
          trailing: true
          }

    return self
]
.factory 'pluginCameraRoll', [
  '$rootScope', '$q', '$timeout',
  'PLUGIN_CAMERA_CONSTANTS'
  ($rootScope, $q, $timeout, CAMERA)->

    # wrap $ionicPlatform ready in a promise, borrowed from otgParse   
    PLUGIN = {
      MAX_PHOTOS: 200
      CHUNK_SIZE : 30
      SERIES_DELAY_MS: 100


      mapAssetsLibraryP: (options={})->
        # console.log "mapAssetsLibrary() calling window.Messenger.mapAssetsLibrary(assets)"

        # defaults = {
        #   # pluck: ['DateTimeOriginal', 'PixelXDimension', 'PixelYDimension', 'Orientation']
        #   fromDate: '2014-09-01'
        #   toDate: null
        # }
        # options = _.defaults options, defaults
        # options.fromDate = cameraRoll.getDateFromLocalTime(options.fromDate) if _.isDate(options.fromDate)
        # options.toDate = cameraRoll.getDateFromLocalTime(options.toDate) if _.isDate(options.toDate)

        return $q.when().then (retval)->
          dfd = $q.defer()
          return $q.reject "ERROR: window.Messenger Plugin not available" if !(window.Messenger?.mapAssetsLibrary)
          # console.log "about to call Messenger.mapAssetsLibrary(), Messenger.properties=" + JSON.stringify _.keys window.Messenger.prototype 
          window.Messenger.mapAssetsLibrary (mapped)->
              ## example: [{"dateTaken":"2014-07-14T07:28:17+03:00","UUID":"E2741A73-D185-44B6-A2E6-2D55F69CD088/L0/001"}]
              # attributes: UUID, dateTaken, mediaType, MediaSubTypes, hidden, favorite, originalWidth, originalHeight
              # console.log "\n *** mapAssetsLibrary Got it!!! length=" + mapped.length
              return dfd.resolve ( mapped )
            , (error)->
              return dfd.reject("ERROR: MessengermapAssetsLibrary(), msg=" + JSON.stringify error)
          # console.log "called Messenger.mapAssetsLibrary(), waiting for callbacks..."
          return dfd.promise

      ##
      ## @param assets array [UUID,] or [{UUID:},{}]
      ## @param options = { DestinationType:, size: }
      ## @param eachPhoto is a callback, usually supplied by cameraRoll
      ##
      getDataURLForAssets_P: (assets, options, eachPhoto)->
        # call getPhotosByIdP() with array
        options = _.defaults options || {} , {
          size: 'preview'
          DestinationType : CAMERA.DestinationType.FILE_URI 
        }
        return PLUGIN.getPhotosByIdP(assets , options).then (photos)->
            _.each photos, (photo)->

              eachPhoto(photo) if _.isFunction eachPhoto

              return 

              # # # merge into cameraRoll.dataUrls
              # # # keys:  UUID,data,elapsed, and more...
              # # # console.log "\n\n>>>>>>>  getPhotosByIdP(" + photo.UUID + "), DataURL[0..80]=" + photo.data[0..80]
              # # # cameraRoll.dataUrls[photo.format][ photo.UUID[0...36] ] = photo.data
              # cameraRoll._addOrUpdatePhoto_FromCameraRoll(photo)
              # cameraRoll.addDataURL(photo.format, photo)
              # console.log "\n*****************************\n"

            # console.log "\n********** updated cameraRoll.dataURLs for this batch ***********\n"

            return photos
          , (errors)->
            console.warn "ERROR: getDataURLForAssetsByChunks_P", errors
            return $q.reject(errors)  # pass it on

      ##
      ## primary entrypoint for getting assets from an array of UUIDs
      ## @param assets array [UUID,] or [{UUID:},{}]
      ##
      getDataURLForAssetsByChunks_P : (tooManyAssets, options, eachPhoto, delayMS=0)->
        if tooManyAssets.length < PLUGIN.CHUNK_SIZE
          return PLUGIN.getDataURLForAssets_P(tooManyAssets, options, eachPhoto) 
        # load dataURLs for assets in chunks
        chunks = []
        chunkable = _.clone tooManyAssets
        chunks.push chunkable.splice(0, PLUGIN.CHUNK_SIZE ) while chunkable.length
        # console.log "\n ********** chunk count=" + chunks.length

        
        ## in Parallel, overloads device
        if !delayMS
          promises = []
          _.each chunks, (assets, i, l)->
            # console.log "\n\n>>> chunk="+i+ " of length=" + assets.length
            promise = PLUGIN.getDataURLForAssets_P( assets, options, eachPhoto )
            promises.push(promise)
          return $q.all(promises).then (photos)->
              allPhotos = []
              # console.log photos
              _.each photos, (chunkOfPhotos, k)->
                allPhotos = allPhotos.concat( chunkOfPhotos )
              # console.log "\n\n>>>  $q.all() done, dataURLs for all chunks retrieved!, length=" + allPhotos.length + "\n\n"
              return allPhotos
            , (errors)->
              console.warn "ERROR: getDataURLForAssetsByChunks_P"
              console.warn errors  

        allPhotos = []
        recurivePromise = (chunks, delayMS)->
          assets = chunks.shift()
          # all chunks fetched, exit recursion
          return $q.reject("done") if !assets
          # chunks remain, fetch chunk
          return PLUGIN.getDataURLForAssets_P( assets, options, eachPhoto)
          .then (chunkOfPhotos)->
            return allPhotos if chunkOfPhotos=="done"
            allPhotos = allPhotos.concat( chunkOfPhotos ) # collate resolves into 1 array
            return chunkOfPhotos
          .then (o)->   # delay between recursive call
            dfd = $q.defer()
            $timeout ()->
              # console.log "\n\ntimeout fired!!! remaining="+chunks.length+"\n\n"
              dfd.resolve(o)
            , delayMS || PLUGIN.SERIES_DELAY_MS
            return dfd.promise 
          .then (o)->
              # call recurively AFTER delay
              return recurivePromise(chunks)

        return recurivePromise(chunks, 500).catch (error)->
          return $q.when(allPhotos) if error == 'done'
          return $q.reject(error)
        .then (allPhotos)->
          # console.log "\n\n>>>  SERIES fetch done, dataURLs for all chunks retrieved!, length=" + allPhotos.length + "\n\n"
          return allPhotos

      ##
      ## @param assets array [UUID,] or [{UUID:},{}]
      ##
      getPhotosByIdP: (assets, options={} )->
        return $q.when([]) if _.isEmpty assets
        # takes asset OR array of assets
        options.size = options.size || 'thumbnail'

        defaults = {
          small: 
            targetWidth: 320
            targetHeight: 320
            resizeMode: 'aspectFit'
            autoRotate: true
            DestinationType: CAMERA.DestinationType.FILE_URI  # 1          
          preview: 
            targetWidth: 720
            targetHeight: 720
            resizeMode: 'aspectFit'
            autoRotate: true
            DestinationType: CAMERA.DestinationType.FILE_URI  # 1
          previewHD: 
            targetWidth: 1080
            targetHeight: 1080
            resizeMode: 'aspectFit'
            autoRotate: true
            DestinationType: CAMERA.DestinationType.FILE_URI  # 1
          thumbnail:
            targetWidth: 64
            targetHeight: 64
            resizeMode: 'aspectFill'
            autoRotate: true
            DestinationType: CAMERA.DestinationType.FILE_URI  # 1
        }
        _.defaults options, defaults[options.size]

        assets = [assets] if !_.isArray(assets)
        assetIds = assets
        assetIds = _.pluck assetIds, 'UUID' if assetIds[0].UUID
        

        # console.log "\n>>>>>>>>> getPhotosByIdP: assetIds=" + JSON.stringify assetIds 
        # console.log "\n>>>>>>>>> getPhotosByIdP: options=" + JSON.stringify options

        $q.when().then (retval)->
          dfd = $q.defer()
          start = new Date().getTime()
          return $q.reject "ERROR: window.Messenger Plugin not available" if !(window.Messenger?.getPhotoById)
          remaining = assetIds.length
          retval = {
            photos: []
            errors: []
          }

          # similar to $q.all()
          _resolveIfDone = (remaining, retval, dfd)->
            # console.log "***  _resolveIfDone ****, remaining=" + remaining
            return if remaining
            if retval.errors.length == 0
              end = new Date().getTime()
              elapsed = (end-start)/1000
              # console.log "\n>>>>>>>> window.Messenger.getPhotoById()  complete, count=" + retval.photos.length + " , elapsed=" + elapsed + "\n\n"
              return dfd.resolve ( retval.photos ) 
            else if retval.photos.length && retval.errors.length 
              # console.warn "WARNING: SOME errors occurred in Messenger.getPhotoById(), errors=" + JSON.stringify retval.errors
              # ???: how do we handle the errors? save them until last?
              return dfd.resolve ( retval.photos ) 
            else if retval.errors.length 
              console.warn "ERROR: Messenger.getPhotoById(), errors=" + JSON.stringify retval.errors
              return dfd.reject retval.errors


          _patchOrientation = (photo)->
            # http://cloudintouch.it/2014/04/03/exif-pain-orientation-ios/
            lookup = [1,3,6,8,2,4,5,7]
            if photo.UIImageOrientation?
              photo.orientation == 'unknown' 
            else 
              photo.orientation = lookup[ photo.UIImageOrientation ] 
              delete photo.UIImageOrientation
            return 

          window.Messenger.getPhotoById assetIds, options, (photo)->
              if options.DestinationType==CAMERA.DestinationType.FILE_URI && photo.dataSize == 0
                console.warn "getPhotoById() Error, dataSize==0", _.pick photo, ['UUID', 'data', 'dataSize', 'dateTaken']

              # one callback for each element in assetIds
              end = new Date().getTime()
              ## expecting photo keys: [data,UUID,dateTaken,originalWidth,originalHeight]
              ## NOTE: extended attrs from mapAssetsLibrary: UUID, dateTaken, mediaType, MediaSubTypes, hidden, favorite, originalWidth, originalHeight
              # photo.elapsed = (end-start)/1000
              photo.from = 'cameraRoll'
              photo.autoRotate = options.autoRotate
              photo.orientation = _patchOrientation( photo )  # should be EXIF orientation

              # plugin method options              
              photo.format = options.type  # thumbnail, preview, previewHD
              photo.crop = options.resizeMode == 'aspectFill'
              photo.targetWidth = options.targetWidth
              photo.targetHeight = options.targetHeight

              retval.photos.push photo
              remaining--
              return _resolveIfDone(remaining, retval, dfd)
            , (error)->
              # example: {"message":"Base64 encoding failed","UUID":"05B86AB8-7C56-41DA-A6D8-E6D1F01B2620/L0/001"}
              # skip future uploads
              retval.errors.push error
              remaining--
              return _resolveIfDone(remaining, retval, dfd)

          return dfd.promise

    }
    return PLUGIN
]

