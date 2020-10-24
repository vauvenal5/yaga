import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/views/widgets/image_views/category_view.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_views/nc_grid_view.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';

class ImageViewContainer extends StatelessWidget {
  final Logger _logger = getLogger(ImageViewContainer);
  final FileListLocalManager fileListLocalManager;
  final ViewConfiguration viewConfig;
  final List<NcFile> Function(List<NcFile>) _filter;

  ImageViewContainer(
      {@required this.fileListLocalManager,
      @required this.viewConfig,
      filter = _defaultFilter})
      : this._filter = filter;

  static List<NcFile> _defaultFilter(List<NcFile> files) => files;

  Widget _buildImageView(ChoicePreference choice, List<NcFile> files) {
    List<NcFile> filteredFiles = this._filter(files);

    if (choice.value == NcGridView.viewKey) {
      return NcGridView(filteredFiles, viewConfig);
    }

    if (choice.value == CategoryView.viewKey) {
      return CategoryView(filteredFiles, viewConfig);
    }

    if (choice.value == NcListView.viewKey) {
      return NcListView(
        files: filteredFiles,
        viewConfig: this.viewConfig,
      );
    }

    return CategoryViewExp(filteredFiles, viewConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      //todo: generalize stream builder for preferences
      StreamBuilder<ChoicePreference>(
        initialData: getIt
            .get<SharedPreferencesService>()
            .loadChoicePreference(this.viewConfig.view),
        stream: getIt
            .get<SettingsManager>()
            .updateSettingCommand
            .where((event) => event.key == this.viewConfig.view.key)
            .map((event) => event as ChoicePreference),
        builder: (context, choice) {
          return StreamBuilder<List<NcFile>>(
            initialData:
                this.fileListLocalManager.filesChangedCommand.lastResult,
            stream: this.fileListLocalManager.filesChangedCommand,
            builder: (context, files) => RefreshIndicator(
              child: _buildImageView(choice.data, files.data),
              onRefresh: () async =>
                  this.fileListLocalManager.updateFilesAndFolders(),
            ),
          );
        },
      ),
      StreamBuilder<bool>(
        initialData: this.fileListLocalManager.loadingChangedCommand.lastResult,
        stream: this.fileListLocalManager.loadingChangedCommand,
        builder: (context, snapshot) =>
            snapshot.data ? LinearProgressIndicator() : Container(),
      )
    ]);
  }
}
