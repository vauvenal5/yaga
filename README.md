# Nextcloud Yaga - Yet Another Gallery App

## Table of Contents
* [State of Yaga](#state-of-yaga)
    * [Features](#features)
    * [Next Steps](#next-steps)
* [Getting Started](#getting-started)
* [Recomendations](#recomendations)
* [iOS Support](#ios-support)
    * [Necessary work](#necessary-work)

## State of Yaga

This app is in an open beta stage. It is tested and fairly stable on an Android One device with Android version 10. You can download it from Google Play. For more information on how to use the app [read the docs](https://vauvenal5.github.io/yaga/).

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png"
    alt="Get it on Google Play"
    height="80">](https://play.google.com/store/apps/details?id=com.github.vauvenal5.yaga)
[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
    alt="Get it on F-Droid"
    height="80">](https://f-droid.org/packages/com.github.vauvenal5.yaga)

### Features
- Nextcloud login flow is implemented
    - Flutter WebView is used and some strange behavior can come from bugs in there. Usually retrying fixes the issue.
    - Login token is being persisted with the `flutter_secure_storage` plugin.
- Category view
    - Displays images in groups sorted by date modified, as list, or as simple grid.
    - Path to display can be set in the view settings.
    - Path can be local or remote.
- Browse view
    - Allows for browsing local and remote directories.
    - Has a focus mode implemented which allows to view current folder like in Category view without changing settings.
- Image view
    - Opening an image from the category or browse view will result in a image view, displaying the image.
    - If opened from category view, displayed images are currently limited to the choosen date.
    - If opened from browser view, displayed images are limited to the current folder.
    - Images can be shared with other apps from this view.
- Root Mapping
    - Allows to set directory mappings between local and remote directories. Basically allowing you to chose where to store your downloaded images or a subset of them.
    - Default mapping points to app folder.
    - Currently limited to one mapping.
    - Previews are always mapped to cache.

### Next Steps

My current plan is to release a stable `v1.0.0` version around christmas this year. For this release I am aming to complete all features that are required for the app to feel like a complete gallery app with respect to the provided functionality.

You can track planned features, current issues as well as what is sceduled for `v1.0.0` in the [issues](https://github.com/vauvenal5/yaga/issues) section.

## Building from Sources

- Generate your own keystore as described in the flutter docs.
- The project uses generation for some classes so you have to first run `flutter pub run build_runner build --delete-conflicting-outputs`
- From the main directory then run: `flutter build apk --flavor play`
- Copy the app to your device and make a local installation.

## Recomendations

It is highly recommended to configure the image preview generator plugin on your Nextcloud server. This will significantly improve fetching times of previews.

## APK Signature

If you decide to download the APK file attached to a Github release, you can verify the APK signature in the following way:
```
apksigner verify --print-certs app-play-release.apk
```

The output should look like this:
```
Signer #1 certificate DN: CN=vauvenal5, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown
Signer #1 certificate SHA-256 digest: dd1652817e4ed5cbd341336add61a10851fd93b2b79c93124ec9d584fdc54b06
Signer #1 certificate SHA-1 digest: 1c54e02710c9ef669c0e75950e25825a5a11a349
Signer #1 certificate MD5 digest: 7f8367b3ebbc8618b1dc0dff81e225b9
```

## iOS Support

I am physically unable to support iOS. I simply do not own the hardware and I also do not intend buying it. If Apple changes its policies about development SDKs I will gladly add iOS support.

If somebody is willing to contribute the necessary steps for iOS support fell free to open a PR. 

### Necessary work
- It will be necessary to recheck the used libraries to see if they support iOS. (This I might do at some point in the future.)
- Some things rely on Android only implementations, for example the storage paths. They need to be changed to a OS independent implementation. (This I might do at some point in the future.)
- Necessary build configuration in the iOS project files. (Not going to happen for the time being.)
- Publishing in the app store. (Not going to happen for the time being.)
