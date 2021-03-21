import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/image_views/category_view.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_views/nc_grid_view.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';

class ImageViewContainer extends StatelessWidget {
  final FileListLocalManager fileListLocalManager;
  final ViewConfiguration viewConfig;
  final bool Function(NcFile) _filter;

  ImageViewContainer({
    @required this.fileListLocalManager,
    @required this.viewConfig,
    bool Function(NcFile) filter,
  }) : this._filter = filter;

  Widget _buildImageView(ChoicePreference choice, SortedFileList files) {
    SortedFileList filteredFiles = files;
    if (_filter != null) {
      filteredFiles = files.applyFilter(_filter);
    }

    if (choice.value == NcGridView.viewKey) {
      return NcGridView(filteredFiles, viewConfig);
    }

    if (choice.value == CategoryView.viewKey) {
      return CategoryView(filteredFiles, viewConfig);
    }

    if (choice.value == NcListView.viewKey) {
      return NcListView(
        sorted: filteredFiles,
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
            .loadPreferenceFromString(this.viewConfig.view),
        stream: getIt
            .get<SettingsManager>()
            .updateSettingCommand
            .where((event) => event.key == this.viewConfig.view.key)
            .map((event) => event as ChoicePreference),
        builder: (context, choice) {
          bool sortChanged = this.fileListLocalManager.setSortConfig(
                ViewConfiguration.getSortConfigFromViewChoice(choice.data),
              );
          return _buildImageContainterStreamBuilder(
            context,
            choice.data,
            sortChanged,
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

  Widget _buildImageContainterStreamBuilder(
    BuildContext context,
    ChoicePreference choice,
    bool sortChanged,
  ) {
    return StreamBuilder<SortedFileList>(
      key: ValueKey(fileListLocalManager.sortConfig.sortType),
      initialData: sortChanged
          ? this.fileListLocalManager.emptyFileList
          : this.fileListLocalManager.filesChangedCommand.lastResult,
      stream: this.fileListLocalManager.filesChangedCommand.where(
            // this filter makes sure that if viewType is changed while loading we do not run into trouble
            (event) =>
                event.config.sortType ==
                fileListLocalManager.sortConfig.sortType,
          ),
      builder: (context, files) => RefreshIndicator(
        child: _buildImageView(choice, files.data),
        onRefresh: () async =>
            this.fileListLocalManager.updateFilesAndFolders(),
      ),
    );
  }
}
