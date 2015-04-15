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
  '$ionicScrollDelegate'
  '$state'
  'testData'
  ($scope, $rootScope, $timeout, $ionicPlatform, $ionicScrollDelegate, $state, testData)->


    $scope.$on '$ionicView.loaded', ()->
      console.log 'GalleryCtrl $ionicView.loaded'
      # once per controller load, setup code for view
      return


    $scope.$on '$ionicView.beforeEnter', ()->
      return 

    $scope.watch = {
      $platform : $platform
      items: []
      getHeight: (i)->
        imgH = this.items[i].dim.h
        scaledH = Math.round (window.innerWidth-20) / this.items[i].dim.w * imgH
        headerH = 37
        footerH = 49
        cardPaddingV = 2 * 5
        h = scaledH + headerH + footerH + cardPaddingV  # 372 px
        console.log "collection-repeat, getHeight() index="+i
        return h
    }

    $scope.on = {
    }

    $scope.$on '$ionicView.enter', ()->
      console.log 'GalleryCtrl $ionicView.enter'
      _init()
      return 


    $scope.$on '$ionicView.leave', ()-> 
      return 

    $scope.$on 'collection-repeat.changed', (ev, items)->
      $scope.watch.items = items
      $ionicScrollDelegate.$getByHandle('collection-repeat-wrap').resize()
      return



    _init = (count=20)->
      $scope.watch.items = []
      items = []
      now = Date.now()
      delay = 5*60*1000 # 5 minutes
      i = 0

      loop
        photo = testData.photos[i++]
        break if i >= testData.photos.length
        break if items.length == count
        continue if $state.includes('app.static-h') && photo.h != 240

        # console.log photo
        item = {
          UUID: photo.src[0...3]
          dateTaken: new Date(now + (i * delay)).toJSON()
          src: testData.baseurl + ".thumbs/bm~" + photo.src
          dim:
            w: photo.w
            h: photo.h
        }
        items.push item
        continue 

      $scope.$broadcast 'collection-repeat.changed', items
      
  ]

.value 'testData', {
  baseurl: "http://snappi.snaphappi.com/svc/storage/DEQBCEektV/"
  photos: [
    {src:"001973FD-476B-48FD-8DF5-A0D3D06BC871_L0_001.jpg" , w:320 , h:240 }    
    {src:"1AA15814-1B25-4CD3-A9FC-A82C1DBD9AAB_L0_001.jpg" ,   w:240 , h:320 }    
    {src:"3A365AA0-A722-4B17-8D0E-59BC7B1BA82B_L0_001.jpg" ,   w:320 , h:320 }    
    {src:"3E614812-FB49-432B-8A5D-6214291978CA_L0_001.jpg" ,   w:240 , h:320 }    
    {src:"5B56B2DE-7502-4B24-9C58-33CD4453A092_L0_001.jpg" , w:320 , h:240 }    
    {src:"6B66CA6C-FC8A-4F1E-A53E-822F9782608F_L0_001.jpg" ,   w:240 , h:320 }   
    {src:"6CBDE5B7-E29C-4821-A023-1AADE889A641_L0_001.jpg" ,   w:240 , h:320 }    
    {src:"7DB6F9BE-ACCE-498B-9CA1-E5E416DDEECC_L0_001.jpg" ,   w:240 , h:320 }    
    {src:"7F362883-391B-4DE2-B94B-800989364560_L0_001.jpg" ,   w:240 , h:320 }    
    {src:"8A93AE01-C2C5-4413-9528-6278F9A389CE_L0_001.jpg" , w:320 , h:240 }    
    {src:"8ABCD662-5E8E-4290-8A24-C200170F0281_L0_001.jpg" ,   w:320 , h:320 }   
    {src:"8AE53A73-D2A0-4ACA-80E0-0FA8D483CDB8_L0_001.jpg" , w:320 , h:240 }    
    {src:"8C03050B-37FE-44AB-8AD1-D9DB2EF74CD3_L0_001.jpg" , w:320 , h:240 }     
    {src:"9E6721E5-2F01-4B1A-9E15-7D7289B69DF4_L0_001.jpg" ,   w:240 , h:320 }
    {src:"13D97544-D882-4161-9692-F1144FE286CD_L0_001.jpg" , w:320 , h:240 }   
    {src:"16CB1DA3-A7D4-4FC2-AED7-C95DA8B0D475_L0_001.jpg" , w:320 , h:240 }    
    {src:"29F5E8E8-1802-4B2F-9A45-0528ED77CFBA_L0_001.jpg" , w:320 , h:240 }    
    {src:"37BA1AB5-FE8F-4E41-A971-C9554D4C5A5E_L0_001.jpg" , w:320 , h:240 }    
    {src:"41EA0A80-1057-46E8-BB93-FF6EDC92414A_L0_001.jpg" , w:320 , h:240 }    
    {src:"54B29786-B785-47D2-A7AA-0E3B1C9A0D95_L0_001.jpg" , w:320 , h:240 }    
    {src:"58E38A34-0BFB-4EF1-B249-BA233B6002DB_L0_001.jpg" , w:320 , h:240 }    
    {src:"61A0CFED-9939-4350-AF90-1B97CC180AE3_L0_001.jpg" ,   w:240 , h:320 }  
    {src:"61C036A4-DF64-4732-949E-0B9BC7C59954_L0_001.jpg" , w:320 , h:240 }    
    {src:"80B1793E-8023-4E90-802B-BA368C4BED3E_L0_001.jpg" ,   w:240 , h:320 }  
    {src:"96A3C62D-4D2C-4832-B865-E16FC81C98AE_L0_001.jpg" ,   w:240 , h:320 }   
    {src:"469CCD77-C7E8-4DC6-96C1-0DE3E6DF27B3_L0_001.jpg" ,   w:240 , h:320 } 
    {src:"683F8934-AD98-4F0C-BA6B-551A98C4E6F1_L0_001.jpg" ,   w:240 , h:320 }   
    {src:"3345ABFB-681E-4F56-8CF4-892C452ADE19_L0_001.jpg" , w:320 , h:240 }    
    {src:"3789A55E-93F8-441A-B894-187831C09C08_L0_001.jpg" , w:320 , h:240 }    
    {src:"9918DCD9-1D7D-445D-AB09-139C38BE8C5F_L0_001.jpg" , w:320 , h:240 }   
    {src:"358692E5-FB63-4A39-9721-C64B5C5E8BB2_L0_001.jpg" , w:320 , h:240 }    
    {src:"472731FB-B44E-4D3D-B472-E8D2CD576BA7_L0_001.jpg" , w:320 , h:240 }   
    {src:"904041BA-559D-43F1-BC95-C16B8D40E962_L0_001.jpg" , w:320 , h:240 }    
    {src:"6841953B-B310-4E58-86C9-0662BD959E56_L0_001.jpg" , w:320 , h:240 }    
    {src:"67492385-64DE-4ED3-944E-EE667DC701D8_L0_001.jpg" , w:320 , h:240 }    
    {src:"A0A6BF12-CADD-426C-A347-843233FACE0B_L0_001.jpg" , w:320 , h:240 }    
    {src:"A5ED4329-37B5-4799-AAA2-FDB4A71D8F66_L0_001.jpg" , w:320 , h:240 }    
    {src:"A9C34352-83E3-42F0-8852-9B2093B111AE_L0_001.jpg" , w:320 , h:240 }   
    {src:"AC072879-DA36-4A56-8A04-4D467C878877_L0_001.jpg" , w:320 , h:240 }    
    {src:"AF2478C8-22BC-445C-A4F7-8D2A8B51CC76_L0_001.jpg" , w:320 , h:240 }    
    {src:"B6C0A21C-07C3-493D-8B44-3BA4C9981C25_L0_001.jpg" , w:320 , h:240 }    
    {src:"BA358F2A-9F5A-418C-956E-48DE3BFF1F75_L0_001.jpg" , w:320 , h:240 }    
    {src:"BA726E10-1738-47C7-809E-51BCC7B0D145_L0_001.jpg" , w:320 , h:240 }    
    {src:"BB03E2E4-320F-4518-AB3A-BCC4D09B9430_L0_001.jpg" , w:320 , h:240 }    
    {src:"C3C3E86F-EFEE-4718-9879-0601E1394237_L0_001.jpg" , w:320 , h:240 }    
    {src:"C4A494E3-51BC-4896-A449-07FA2570ABFD_L0_001.jpg" , w:320 , h:240 }    
    {src:"C4FC84BB-9028-4941-8F3D-3D0FF1A06205_L0_001.jpg" , w:320 , h:240 }    
    {src:"C1701CBC-6025-4334-9E98-685D055825A6_L0_001.jpg" , w:320 , h:240 }   
    {src:"D5EC2D3C-CBA1-4A6C-B026-4BAF02780F91_L0_001.jpg" , w:320 , h:240 }    
    {src:"D6403F88-41D5-41D8-A99A-398EFDB9E068_L0_001.jpg" , w:320 , h:240 }    
    {src:"DCBE518A-C4CE-40C2-9B5A-AE8A8DB60BE4_L0_001.jpg" , w:320 , h:240 }    
    {src:"DE4D611B-DA21-4BC3-AF33-6D6328E98587_L0_001.jpg" , w:320 , h:240 }    
    {src:"E01DDD7B-1C46-48DC-BBBA-D6966A645007_L0_001.jpg" , w:320 , h:240 }   
    {src:"E4CB56EC-B414-4D47-A4E0-4BABB614978B_L0_001.jpg" , w:320 , h:240 }    
    {src:"E603FC3C-7187-4FF4-A900-2CFB3BD4227B_L0_001.jpg" , w:320 , h:240 }    
    {src:"E2741A73-D185-44B6-A2E6-2D55F69CD088_L0_001.jpg" , w:320 , h:240 }    
    {src:"E8435F1E-AA5D-4DC7-9B43-CB2DC1401B5B_L0_001.jpg" , w:320 , h:240 }    
    {src:"E49953AF-43A9-4B8E-BF33-751F095ACB95_L0_001.jpg" , w:320 , h:240 }    
    {src:"F459CBC8-607C-4080-A88F-7C1DEF6D502D_L0_001.jpg" , w:320 , h:240 }    
    {src:"F9705192-89DE-4147-A726-8A5F94FF336E_L0_001.jpg" , w:320 , h:240 }    
    {src:"FDDFF97C-63E1-44BA-B803-59C5A0A7292A_L0_001.jpg" , w:320 , h:240 }      
    ]
  } 
