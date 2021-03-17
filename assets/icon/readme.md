# Android Icons

The SVG files found in this directory are the lead files for the app icons. 

For API 26+ changes to the SVGs have to be manually propagated to the respective VectorDrawables in `../android/app/src/main/resources/drawable`.

For APIs smaller then 26 a `icon.png` has to be created from `icon.svg`. Then run the following command to generate the required icons.

```sh
flutter pub run flutter_launcher_icons:main -f pubspec.yaml
```