'use strict'

###*
 # @ngdoc factory
 # @name appParse
 # @description 
 # methods for accessing parse javascript SDK
 # 
###



angular
.module 'parse.backend', []
.value 'PARSE_CREDENTIALS', {
  APP_ID : ""
  JS_KEY : ""
  REST_API_KEY : ""
}
.factory 'restApi', [
  '$http', 'PARSE_CREDENTIALS'
  ($http, PARSE_CREDENTIALS)->
    parseHeaders_GET = {
        'X-Parse-Application-Id': PARSE_CREDENTIALS.APP_ID,
        'X-Parse-REST-API-Key':PARSE_CREDENTIALS.REST_API_KEY,
    }
    parseHeaders_SET = _.defaults { 'Content-Type':'application/json' }, parseHeaders_GET
    self = {
        getAll: (className)->
            return $http.get('https://api.parse.com/1/classes/' + className, {
              headers: parseHeaders_GET
            })
        get: (className, id)->
            return $http.get('https://api.parse.com/1/classes/' + className + '/' + id, {
              headers: parseHeaders_GET
            })
        create: (className, data)->
            return $http.post('https://api.parse.com/1/classes/' + className, data, {
              headers: parseHeaders_SET
            })
        edit: (className, id, data)->
            return $http.put('https://api.parse.com/1/classes/' + className + '/' + id, data, {
              headers: parseHeaders_SET
            });
        delete: (className, id)->
            return $http.delete('https://api.parse.com/1/classes/' + className + '/' + id, {
              headers: parseHeaders_SET
            })
    }
    return self
]

.factory 'appParse', [
  '$q', '$timeout', '$rootScope', 'deviceReady'
  ($q, $timeout, $rootScope, deviceReady)->

    parseClass = {
      BacklogObj : Parse.Object.extend('BacklogObj')
    }

    ANON_PREFIX = {
      username: 'anonymous-'
      password: 'password-'
    }

    ANON_USER = {
      id: null
      username: null
      password: null
      email: null
      emailVerified: false
      tosAgree: false
      rememberMe: false
      isRegistered: false       
    }


    self = {
      isAnonymousUser: ()->
        return true if _.isEmpty $rootScope.sessionUser
        return true if $rootScope.sessionUser.get('username').indexOf(ANON_PREFIX.username) == 0
        # return true if $rootScope.sessionUser.get('username') == 'browser'
        return false

      mergeSessionUser: (anonUser={})->
        anonUser = _.extend _.clone(ANON_USER), anonUser
        # merge from cookie into $rootScope.user
        $rootScope.sessionUser = Parse.User.current()
        return anonUser if !($rootScope.sessionUser instanceof Parse.Object)

        isRegistered = !self.isAnonymousUser()
        return anonUser if !isRegistered
        
        userCred = _.pick( $rootScope.sessionUser.toJSON(), [
          'username', 'role', 
          'email', 'emailVerified', 
          'tosAgree', 'rememberMe'
        ] )
        userCred.password = 'HIDDEN'
        userCred.tosAgree = !!userCred.tosAgree # checkbox:ng-model expects a boolean
        userCred.isRegistered = true
        return _.extend anonUser, userCred

      signUpP: (userCred)->
        user = new Parse.User();
        user.set("username", userCred.username.toLowerCase())
        user.set("password", userCred.password)
        user.set("email", userCred.email) 
        return user.signUp().then (user)->
            return $rootScope.sessionUser = Parse.User.current()
          , (user, error)->
            $rootScope.sessionUser = null
            $rootScope.user.username = ''
            $rootScope.user.password = ''
            $rootScope.user.email = ''
            console.warn "parse User.signUp error, msg=" + JSON.stringify error
            return $q.reject(error)

      ###
      # @params userCred object, keys {username:, password:}
      #     or array of keys
      ###
      loginP: (userCred, signOutOnErr=true)->
        userCred = _.pick userCred, ['username', 'password']
        return deviceReady.waitP().then ()->
          return Parse.User.logIn( userCred.username.trim().toLowerCase(), userCred.password )
        .then (user)->  
            $rootScope.sessionUser = Parse.User.current()
            $rootScope.user.isRegistered = true
            $rootScope.user = self.mergeSessionUser($rootScope.user)
            return user
        , (error)->
            if signOutOnErr
              $rootScope.sessionUser = null
              $rootScope.$broadcast 'user:sign-out'
              console.warn "User login error. msg=" + JSON.stringify error
            $q.reject(error)


      logoutSession: (anonUser)->
        Parse.User.logOut()
        $rootScope.sessionUser = Parse.User.current()
        _.extend $rootScope.user , ANON_USER
        return

      anonSignUpP: (seed)->
        _uniqueId = (length=8) ->
          id = ""
          id += Math.random().toString(36).substr(2) while id.length < length
          id.substr 0, length
        seed = _uniqueId(8) if !seed
        anon = {
          username: ANON_PREFIX.username + seed
          password: ANON_PREFIX.password + seed
        }
        return self.signUpP(anon).then (userObj)->
              return userObj
            , (userCred, error)->
              console.warn "parseUser anonSignUpP() FAILED, userCred=" + JSON.stringify userCred 
              return $q.reject( error )

      # confirm userCred or create anonymous user if Parse.User.current()==null
      checkSessionUserP: (userCred, createAnonUser=true)-> 
        if userCred # confirm userCred
          authPromise = self.loginP(userCred, false).then null, (err)->
              return $q.reject({
                  message: "userCred invalid"
                  code: 301
                })
        else if $rootScope.sessionUser
          authPromise = $q.when($rootScope.sessionUser)
        else 
          authPromise = $q.reject()

        if createAnonUser
          authPromise = authPromise.then (o)->
              return o
            , (error)->
              return self.anonSignUpP()

        return authPromise


      saveSessionUserP : (updateKeys, userCred)->
        # update or create
        if _.isEmpty($rootScope.sessionUser)
          # create
          promise = self.signUpP(userCred)
        else if self.isAnonymousUser()
          promise = $q.when()
        else  # verify userCred before updating user profile
          reverify = {
            username: userCred['username']
            password: userCred['currentPassword']
          }
          promise = self.checkSessionUserP(reverify, false)

        promise = promise.then ()->
            # userCred should be valid, continue with update
            _.each updateKeys, (key)->
                return if key == 'currentPassword'
                if key=='username'
                  userCred['username'] = userCred['username'].trim().toLowerCase()
                $rootScope.sessionUser.set(key, userCred[key])
                return
            return $rootScope.sessionUser.save().then ()->
                return $rootScope.user = self.mergeSessionUser($rootScope.user)
              , (error)->
                $rootScope.sessionUser = null
                $rootScope.user.username = ''
                $rootScope.user.password = ''
                $rootScope.user.email = ''
                console.warn "parse User.save error, msg=" + JSON.stringify error
                return $q.reject(error)
          .then ()->
              $rootScope.sessionUser = Parse.User.current()
              return $q.when($rootScope.sessionUser)
            , (err)->
              return $q.reject(err) # end of line

      updateUserProfileP : (options)->
        keys = ['tosAgree', 'rememberMe']
        options = _.pick options, keys
        return $q.when() if _.isEmpty options
        return deviceReady.waitP().then ()->
          return self.checkSessionUserP(null, true)
        .then ()->
            return $rootScope.sessionUser.save(options)
          , (err)->
            return err



      ###
      # THESE METHODS ARE UNTESTED
      ###

      uploadPhotoMetaP: (workorderObj, photo)->
        return $q.reject("uploadPhotoMetaP: photo is empty") if !photo
        # upload photo meta BEFORE file upload from native uploader
        # photo.src == 'queued'
        return deviceReady.waitP().then self.checkSessionUserP(null, false)
        .then ()-> 
          attrsForParse = [
            'dateTaken', 'originalWidth', 'originalHeight', 
            'rating', 'favorite', 'caption', 'hidden'
            'exif', 'orientation', 'location'
            "mediaType",  "mediaSubTypes", "burstIdentifier", "burstSelectionTypes", "representsBurst",
          ]
          extendedAttrs = _.pick photo, attrsForParse
          # console.log extendedAttrs

          parseData = _.extend {
                # assetId: photo.UUID  # deprecate
                UUID: photo.UUID
                owner: $rootScope.sessionUser
                deviceId: deviceReady.device().id
                src: "queued"
            }
            , extendedAttrs # , classDefaults

          photoObj = new parseClass.PhotoObj parseData , {initClass: false }
          # set default ACL, owner:rw, Curator:rw
          photoACL = new Parse.ACL(parseData.owner)
          photoACL.setRoleReadAccess('Curator', true)
          photoACL.setRoleWriteAccess('Curator', true)
          photoObj.setACL (photoACL)
          return photoObj.save()
        .then (o)->
            # console.log "photoObj.save() complete: " + JSON.stringify o.attributes 
            return 
          , (err)->
            console.warn "ERROR: uploadPhotoMetaP photoObj.save(), err=" + JSON.stringify err
            return $q.reject(err)

      uploadPhotoFileP : (options, dataURL)->
        # called by parseUploader, _uploadNext()
        # upload file then update PhotoObj photo.src, does not know workorder
        # return parseFile = { UUID:, url(): }
        return deviceReady.waitP().then self.checkSessionUserP(null, false) 
          .then ()->
            if deviceReady.device().isBrowser
              return $q.reject( {
                UUID: UUID
                message: "error: file upload not available from browser"
              }) 
          .then ()->
            photo = {
              UUID: options.UUID
              filename: options.filename
              data: dataURL
            }
            # photo.UUID, photo.data = dataURL
            return self.uploadFileP(photo.data, photo)
          .catch (error)->
            skipErrorFile = {
              UUID: error.UUID
              url: ()-> return error.message
            }
            switch error.message
              when "error: Base64 encoding failed", "Base64 encoding failed"
                return $q.when skipErrorFile
              when "error: UUID not found in CameraRoll", "Not found!"
                return $q.when skipErrorFile
              else 
                throw error     

      # 'parse' uploader only, requires DataURLs
      uploadFileP : (base64src, photo)->
        if /^data:image/.test(base64src)
          # expecting this prefix: 'data:image/jpg;base64,' + rawBase64
          mimeType = base64src[10..20]
          ext = 'jpg' if (/jpg|jpeg/i.test(mimeType))   
          ext = 'png' if (/png/i.test(mimeType)) 
          filename = photo.filename || photo.UUID.replace('/','_') + '.' + ext

          console.log "\n\n >>> Parse file save, filename=" + filename
          console.log "\n\n >>> Parse file save, dataURL=" + base64src[0..50]

          # get mimeType, then strip off mimeType, as necessary
          base64src = base64src.split(',')[1] 
        else 
          ext = 'jpg' # just assume

        # save DataURL as image file on Parse
        parseFile = new Parse.File(filename, {
            base64: base64src
          })
        return parseFile.save()

    }
    return self
]


# # test cloudCode with js debugger
window.cloud = {  }




