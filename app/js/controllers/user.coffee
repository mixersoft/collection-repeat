'use strict'

###*
 # @ngdoc function
 # @name ionBlankApp.controller:SettingsCtrl
 # @description
 # # SettingsCtrl
 # Controller of the ionBlankApp
###
angular.module('starter')
.factory 'appProfile', [
  '$rootScope', '$q', 'appParse'
  ($rootScope, $q, appParse)->

    _username = {
      regExp : /^[a-z0-9_!\@\#\$\%\^\&\*.-]{3,20}$/

      dirty : ()->
        return $rootScope.user['username'] != self.userModel()['username']

      isValid: (ev)->
        return self.userModel()['username']? && _username.regExp.test(self.userModel()['username'].toLowerCase())

      ngClassValidIcon: ()->
        return 'hide' if !_username.dirty() || !self.userModel()['username']
        if _username.isValid(self.userModel()['username'].toLowerCase())
          # TODO: also check with parse?
          return 'ion-ios-checkmark balanced' 
        else 
          return 'ion-ios-close assertive'
    }

    _password = {
      regExp : /^[A-Za-z0-9_-]{8,20}$/
      'passwordAgainModel': null
      showPasswordAgain : ''

      dirty : ()->
        return $rootScope.user['password'] != self.userModel()['password']

      edit: ()-> 
        # show password confirm popup before edit
        _password.showPasswordAgain = true
        self.userModel()['password'] = ''

      isValid: (field='password')-> # validate password or oldPassword
        return self.userModel()[field]? && _password.regExp.test(self.userModel()[field])

      isConfirmed: ()-> 
        return _password.isValid() && _password['passwordAgainModel'] == self.userModel()['password']
      
      ngClassValidIcon: (field='password')->
        return 'hide' if !_password.dirty()
        if _password.isValid(field)
          return 'ion-ios-checkmark balanced' 
        else 
          return 'ion-ios-close assertive'
      ngClassConfirmedIcon: ()->
        return 'hide' if !_password.dirty() || !_password['passwordAgainModel']
        if _password.isConfirmed() 
          return 'ion-ios-checkmark balanced' 
        else 
          return 'ion-ios-close assertive'
    }

    _email = {
      dirty : ()->
        return $rootScope.user['email'] != self.userModel()['email']
      
      regExp : /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/

      isValid: (ev)->
        return self.userModel()['email']? && _email.regExp.test(self.userModel()['email'])
      isVerified: ()->
        return self.userModel()['emailVerified']
      ngClassEmailIcon: ()->
        if _email.dirty() 
          if _email.isValid()
            return 'ion-ios-checkmark balanced' 
          else 
            return 'ion-ios-close assertive'
        else 
          if _email.isVerified()
            return 'ion-ios-checkmark balanced'
          else if self.userModel()['email']?
            return 'ion-flag assertive'
          else 
            return 'hide'

    }

    self = {
      isAnonymous: appParse.isAnonymousUser

      _userModel : {}
      userModel: (user)->
        return self._userModel if `user==null`
        return self._userModel = user

      dirty : ()->
        keys = ['username', 'password', 'email']
        return _.isEqual( _.pick( $rootScope.user, keys ),  _.pick( self.userModel(), keys )) == false

      signInP: (userCred)->
        return appParse.loginP(userCred).then (o)->
            self.userModel( _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified'] )
            return o
          , (err)->
            self.userModel( {} )
            $q.reject(err)

      submitP: ()->
        updateKeys = []
        _.each ['username', 'password', 'email'], (key)->
          updateKeys.push(key) if self[key].dirty()           # if key == 'email'  # managed by parse
          return
        if !self.isAnonymous()
          # confirm current password before change
          updateKeys.push('currentPassword')
        return appParse.saveSessionUserP(updateKeys, self.userModel() ).then (userObj)->
            self.userModel( _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified'] )
            return userObj

      ngClassSubmit : ()->
        if (self.email.dirty() && self.email.isValid()) || (self.password.dirty() && self.password.isConfirmed() )
          enabled = true 
        else 
          enabled = false
        return if enabled then 'button-balanced' else 'button-energized disabled'

      ngClassSignin : ()->
        if self.userModel()['username'] && self.userModel()['password']           
          enabled = true 
        else 
          enabled = false
        return if enabled then 'button-balanced' else 'button-energized disabled'



      displaySessionUsername: ()->
        return "anonymous" if self.isAnonymous()
        return $rootScope.sessionUser.get('username')

      signOut: ()->
        appParse.logoutSession()
        self.userModel( {} )
        return 

      username: _username
      password: _password
      email: _email
      errorMessage: ''

    }
    
    return self

]
.controller 'UserCtrl', [
  '$scope', '$rootScope', '$timeout'
  '$ionicHistory', '$ionicPopup', '$ionicNavBarDelegate', 
  'appParse', 'appProfile'
  ($scope, $rootScope, $timeout, $ionicHistory, $ionicPopup, $ionicNavBarDelegate, appParse, appProfile) ->
    
    $scope.appProfile = appProfile
    $scope.deviceReady.waitP().then (platform)->
      $scope.device = platform # deviceReady.device()
      return

    $scope.watch = {
      viewName: ()->
        return 'sign-in' if $rootScope.$state.includes('app.profile.sign-in')
        return 'anonymous' if appProfile.isAnonymous()
        return 'registered'
      showAdvanced: false 
      isWorking:
        clearAppCache: false
        clearArchive: false
        resetDeviceId: false
    }
    $scope.on = {
      showSpinnerWhenIframeLoading: (name)->
        $scope.watch.iframeOpened = $scope.watch.iframeOpened || {}
        return if $scope.watch.iframeOpened[name]?
        $scope.showLoading(true, 3000)
        $scope.watch.iframeOpened[name] = 1
      clearCacheP: ()->
        $scope.watch.isWorking.clearAppCache = true
        # clear localStorage
        $scope.watch.isWorking.clearAppCache = false
      toggleShowAdvanced: ()->
        $scope.watch.showAdvanced = !$scope.watch.showAdvanced

      resetLocalStorage: ()->
        # copied from app.coffee: _RESTORE_FROM_LOCALSTORAGE() 
        isDevice = $scope.deviceReady.device().isDevice
        otgLocalStorage.loadDefaults([
          'config', 'menuCounts'
        ]) 
        return $scope.on.clearCacheP().then ()->
          if isDevice
            msg = "You MUST close and\nre-launch this App!"
            window.alert(msg)
          else 
            window.location.reload()
          return

      resetDeviceId: ()->
        return if $scope.deviceReady.device().isBrowser
        msg = "Are you sure you want to\nreset your DeviceId?"
        resp = window.confirm(msg)
        if resp 
          $scope.watch.isWorking.resetDeviceId = true 
          # reset deviceId
          $scope.watch.isWorking.resetDeviceId = false
        return

      signOut : (ev)->
        ev.preventDefault() 
        # add confirm.
        if appProfile.isAnonymous() && $rootScope.user.tosAgree
          msg = "Are you sure you want to sign-out?\nYou do not have a password and cannot recover this account"
          resp = window.confirm(msg)
          return false if !resp 
        appProfile.signOut()
        $rootScope.$broadcast 'user:sign-out' 
        $rootScope.$state.transitionTo('app.profile.sign-in')
        return     
    
      signIn : (ev)->
        ev.preventDefault()
        return if appProfile.ngClassSignin().indexOf('disabled') > -1
        
        userCred = _.pick appProfile.userModel(), ['username', 'password']
        return appProfile.signInP(userCred).then ()->

            appProfile.errorMessage = ''
            target = 'app.profile'
            $ionicHistory.nextViewOptions({
              historyRoot: true
            })
            $rootScope.$state.transitionTo(target)  
          , (error)->
            appProfile.userModel( {} )
            $rootScope.$state.transitionTo('app.profile.sign-in')
            switch error.code 
              when 101
                message = i18n.tr('error-codes','app.profile')[error.code] # "The Username and Password combination was not found. Please try again."
              else
                message = i18n.tr('error-codes','app.profile')[10] # "Sign-in unsucessful. Please try again."
            appProfile.errorMessage = message
            return 
          .then ()->
            # refresh everything, including topPicks
            $rootScope.$broadcast 'user:sign-in' 
            return


      submit : (ev)->
        ev.preventDefault()
        return if appProfile.ngClassSubmit().indexOf('disabled') > -1

        # either update or CREATE
        isCreate = if _.isEmpty($rootScope.sessionUser) then true else false
        return appProfile.submitP()
        .then ()->
            appProfile.errorMessage = ''
            if isCreate
              $ionicHistory.nextViewOptions({
                historyRoot: true
              })
              target = 'app.profile'
              $rootScope.$state.transitionTo(target)
            # else stay on app.settings.profile page
        , (error)->
          appProfile.password.passwordAgainModel = ''
          switch error.code 
            when 202, 203
              message = i18n.tr('error-codes','app.settings')[error.code] # "That Username/Email was already taken. Please try again."
            when 301
              appProfile.userModel _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified']
              message = i18n.tr('error-codes','app.settings')[error.code] # no permission to make changes
            else
              message = i18n.tr('error-codes','app.settings')[11] # "Sign-up unsucessful. Please try again."
          appProfile.errorMessage = message
          return 
        return 
    }

    $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams)->
      return if /^app.settings/.test(toState.name) == false
      switch toState.name
        when 'app.profile.profile'
          appProfile.userModel _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified']
        when 'app.profile.sign-in'
          appProfile.userModel _.pick $rootScope.user, ['username', 'password']
      return
 


    $scope.$on '$ionicView.loaded', ()->
      return

    $scope.$on '$ionicView.beforeEnter', ()->
      appProfile.userModel _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified']
      appProfile.errorMessage = ''
      return

    $scope.$on '$ionicView.enter', ()->
      angular.noop()


    $scope.$on '$ionicView.leave', ()->
      # cached view becomes in-active 
      return 

]  