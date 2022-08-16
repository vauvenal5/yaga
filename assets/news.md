## What's New
**Breaking Changes:** Started with refactoring for Android 11+ support. 

This has major impact on the app, please consider raising any issues you discover on Github.

Refer to the docs for more information.

**FDroid release will not be updated for the time being if you need any of the removed features and are still on Android 10 (API Level 29) or lower consider installing from there.**

## Changelog
- targeting Android 12 (API Level 31)
- refactoring to MediaStore API for local file access
- root mapping deprecated: will be refactored in future when full MediaStore API support is implemented
- automatically resetting root mapping to revert back to default app directory
- local move/copy are currently not supported
- local delete is supported but requires user confirmation
- on Android 12 (API 31+) you can assign MANAGE_MEDIA rights to the app to avoid delete confirmation dialog
- SD card support is broken
- file provider for other apps is fixed
- about app dialog was updated to support news

