# collection-repeat
A test project for optimizing the ionic collection-repeat directive for use with cameraRoll photos. My goal is to minimize this issue:

> "Whenever you set the src of an img on iOS to a non-cached value, there is a freeze of anywhere from 50-150ms–even on an iPhone 6." http://blog.ionic.io/collection-repeat-iteration-two/

The project includes a cordova plugin I had developed to access photos from the iOS camera roll. There are multiple test views available from the left menu
- Static-H: static list with 360px static JPGs hosted on an Amazon AWS server 
- dynamic-H: dynamic list layout for static JPGs hosted on an Amazon AWS server (landscape & portrait photos)
- CameraRoll: FILE_URI jpgs fetched by the plugin from the cameraRoll and copied to the app storage folder, in 2 sizes
- CameraRoll DataURL: DataURLs fetched by the plugin from the cameraRoll

NOTE: the 'cameraRoll' service will cache FILE_URI/DATA_URLs for the life of the app. But the cache will be cleared when the app is restarted. This is probably why DataURLs take so much memory.


# installation
```
git clone [repo] [folder]
cd [folder]
npm install
bower install
ionic platform add ios
ionic lib update
gulp
ionic build ios
ionic emulate
```

# observations
Collection-Repeat scrolling is rather "jumpy" on an iPhone 6. I don't know the internals of the directive as others, but I'm wondering if there is there anything we can do to smooth it out. I would welcome suggestions on what to try or where to look.

DataURLs use a lot of memory, and don't seem to add any performance
