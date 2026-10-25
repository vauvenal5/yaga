import 'package:built_collection/built_collection.dart';
import 'package:files_app/files_app.dart';
import 'package:neon_framework/models.dart';
import 'package:photos_app/photos_app.dart';

/// The collection of clients enabled for the Neon app.
final AppImplementations appImplementations = AppImplementations(
  registeredAppImplementations: BuiltSet<AppImplementation>({
    PhotosApp(),
  }),
  dependencyApps: BuiltSet<AppImplementation>({
    FilesApp(),
  })
);
