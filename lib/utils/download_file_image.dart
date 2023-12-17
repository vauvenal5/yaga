import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Codec, ImmutableBuffer;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:yaga/model/fetched_file.dart';

typedef _SimpleDecoderCallback = Future<ui.Codec> Function(ui.ImmutableBuffer buffer);

// this entire class is a copy of the respective FileImage functions
// with the addition of an await for the localFileAvailable
// proper solution would probably be to write an own ImageProvider
class DownloadFileImage extends FileImage {
  final Future<FetchedFile> localFileAvailable;

  const DownloadFileImage(File file, this.localFileAvailable) : super(file);

  /// this function is copied from parent without changes
  @override
  ImageStreamCompleter loadBuffer(FileImage key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode: decode),
      scale: key.scale,
      debugLabel: key.file.path,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${file.path}'),
      ],
    );
  }

  @override
  @protected
  ImageStreamCompleter loadImage(FileImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode: decode),
      scale: key.scale,
      debugLabel: key.file.path,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${file.path}'),
      ],
    );
  }

  /// this function is copied from the parent
  /// await localFileAvailable was added and Uint8List result is reused
  Future<ui.Codec> _loadAsync(
      FileImage key, {
        required _SimpleDecoderCallback decode,
      }) async {
    await localFileAvailable;
    assert(key == this);
    // TODO(jonahwilliams): making this sync caused test failures that seem to
    // indicate that we can fail to call evict unless at least one await has
    // occurred in the test.
    // https://github.com/flutter/flutter/issues/113044
    final int lengthInBytes = await file.length();
    if (lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }
    return (file.runtimeType == File)
        ? decode(await ui.ImmutableBuffer.fromFilePath(file.path))
        : decode(await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes()));
  }
}
