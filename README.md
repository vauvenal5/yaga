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
    height="80"
    width="250">](https://play.google.com/store/apps/details?id=com.github.vauvenal5.yaga){: .text-decoration: none;}

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
The following things are on my roadmap and will be developed during the next months, however, not necessarily in this order. See also [issues](https://github.com/vauvenal5/yaga/issues) for a up to date state of current issues.
- [ ] Improve autmated test coverage.
- [ ] Clean up code base.
- [ ] Add favourite places to browse view.
- [ ] **Publish on F-Droid. - waiting for merge**
- [ ] Allow for moving/deleting images.
- [ ] Multiselect.

## Building from Sources

- Generate your own keystore as described in the flutter docs.
- The project uses generation for some classes so you have to first run `flutter pub run build_runner build --delete-conflicting-outputs`
- From the main directory then run: `flutter build apk --flavor play`
- Copy the app to your device and make a local installation.

## Recomendations

It is highly recommended to configure the image preview generator plugin on your Nextcloud server. This will significantly improve fetching times of previews.

## iOS Support

I am physically unable to support iOS. I simply do not own the hardware and I also do not intend buying it. If Apple changes its policies about development SDKs I will gladly add iOS support.

If somebody is willing to contribute the necessary steps for iOS support fell free to open a PR. 

### Necessary work
- It will be necessary to recheck the used libraries to see if they support iOS. (This I might do at some point in the future.)
- Some things rely on Android only implementations, for example the storage paths. They need to be changed to a OS independent implementation. (This I might do at some point in the future.)
- Necessary build configuration in the iOS project files. (Not going to happen for the time being.)
- Publishing in the app store. (Not going to happen for the time being.)
