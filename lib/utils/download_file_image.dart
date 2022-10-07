import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Codec, ImmutableBuffer;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:yaga/model/fetched_file.dart';

class DownloadFileImage extends FileImage {
  final Future<FetchedFile> localFileAvailable;

  const DownloadFileImage(File file, this.localFileAvailable) : super(file);

  /// this function is copied from parent without changes
  @override
  ImageStreamCompleter loadBuffer(FileImage key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode, null),
      scale: key.scale,
      debugLabel: key.file.path,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${file.path}'),
      ],
    );
  }

  /// this function is copied from the parent
  /// await localFileAvailable was added and Uint8List result is reused
  Future<ui.Codec> _loadAsync(FileImage key, DecoderBufferCallback? decode, DecoderCallback? decodeDeprecated) async {
    assert(key == this);

    final FetchedFile fetchedFile = await localFileAvailable;
    assert(fetchedFile.file.localFile!.file.path == file.path);

    final Uint8List bytes = fetchedFile.data;
    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }

    if (decode != null) {
      return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    }
    return decodeDeprecated!(bytes);
  }
}
