import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Codec;

import 'package:flutter/rendering.dart';
import 'package:yaga/model/fetched_file.dart';

class DownloadFileImage extends FileImage {
  final Future<FetchedFile> localFileAvailable;

  const DownloadFileImage(File file, this.localFileAvailable) : super(file);

  @override
  ImageStreamCompleter load(FileImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      informationCollector: () sync* {
        yield ErrorDescription('Path: ${file.path}');
      },
    );
  }

  Future<ui.Codec> _loadAsync(FileImage key, DecoderCallback decode) async {
    assert(key == this);

    final FetchedFile fetchedFile = await localFileAvailable;
    assert(fetchedFile.file.localFile!.file.path == file.path);

    if (fetchedFile.data.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance?.imageCache?.evict(key);
      throw StateError(
          '${file.uri.toString()} is empty and cannot be loaded as an image.');
    }

    return decode(fetchedFile.data);
  }
}
