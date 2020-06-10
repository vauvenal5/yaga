import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';

class FileManager {
  RxCommand<String, NcFile> listRemoteFilesCommand;
  RxCommand<NcFile, NcFile> _getPreviewCommand;

  RxCommand<NcFile, NcFile> downloadPreviewCommand;
  RxCommand<NcFile, NcFile> updatePreviewCommand;

  FileManager() {
    listRemoteFilesCommand = RxCommand.createFromStream((param) => getIt.get<NextCloudService>().listFiles(param));
    _getPreviewCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    _getPreviewCommand.asyncMap((ncFile) => getIt.get<NextCloudService>().getPreview(ncFile.path)
      .then((value) async {
        ncFile.previewFile.createSync(recursive: true);
        ncFile.previewFile = await ncFile.previewFile.writeAsBytes(value); 
        return ncFile;
      })
    )
    .listen((value) => updatePreviewCommand(value));

    downloadPreviewCommand = RxCommand.createSync((param) => param);
    downloadPreviewCommand
    // .flatMap((ncFile) => getIt.get<LocalImageProviderService>().getTmpFile(ncFile.path).asStream()
    //   .doOnData((tmpFile) => ncFile.previewFile = tmpFile)
    //   .map((tmpFile) => ncFile)
    // )
    .listen((ncFile) {
      if(ncFile.previewFile != null && ncFile.previewFile.existsSync()) {
        updatePreviewCommand(ncFile);
        return;
      }
      this._getPreviewCommand(ncFile);
    });

    updatePreviewCommand = RxCommand.createSync((param) => param);
  }
}