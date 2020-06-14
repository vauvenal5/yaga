import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;

import 'package:flutter/rendering.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/service_locator.dart';

class DownloadFileImage extends FileImage {
  final Future<File> localFileAvailable;

  DownloadFileImage(File file, this.localFileAvailable) : super(file);

  @override
  ImageStreamCompleter load(FileImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      informationCollector: () sync* {
        yield ErrorDescription('Path: ${file?.path}');
      },
    );
  }

  Future<ui.Codec> _loadAsync(FileImage key, DecoderCallback decode) async {
    assert(key == this);

    File localFile = await localFileAvailable;
    assert(localFile.path == this.file.path);

    final Uint8List bytes = await file.readAsBytes();

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('${file.uri.toString()} is empty and cannot be loaded as an image.');
    }

    return await decode(bytes);
  }
  
}