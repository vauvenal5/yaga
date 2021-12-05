import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/choice_preference.dart';
import 'package:yaga/model/sorted_category_list.dart';
import 'package:yaga/model/sorted_file_folder_list.dart';
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
  final bool Function(NcFile)? _filter;

  const ImageViewContainer({
    required this.fileListLocalManager,
    required this.viewConfig,
    bool Function(NcFile)? filter,
  }) : _filter = filter;

  Widget _buildImageView(ChoicePreference choice, SortedFileList files) {
    SortedFileList filteredFiles = files;
    if (_filter != null) {
      filteredFiles = files.applyFilter(_filter!);
    }

    if (choice.value == NcGridView.viewKey) {
      return NcGridView(filteredFiles as SortedFileFolderList, viewConfig);
    }

    if (choice.value == CategoryView.viewKey) {
      return CategoryView(filteredFiles as SortedCategoryList, viewConfig);
    }

    if (choice.value == NcListView.viewKey) {
      return NcListView(
        sorted: filteredFiles as SortedFileFolderList,
        viewConfig: viewConfig,
      );
    }

    return CategoryViewExp(filteredFiles as SortedCategoryList, viewConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      //todo: generalize stream builder for preferences
      StreamBuilder<ChoicePreference>(
        initialData: getIt
            .get<SharedPreferencesService>()
            .loadPreferenceFromString(viewConfig.view),
        stream: getIt
            .get<SettingsManager>()
            .updateSettingCommand
            .where((event) => event.key == viewConfig.view.key)
            .map((event) => event as ChoicePreference),
        builder: (context, choice) {
          final bool sortChanged = fileListLocalManager.setSortConfig(
            ViewConfiguration.getSortConfigFromViewChoice(choice.data!),
          );
          return _buildImageContainterStreamBuilder(
            context,
            choice.data!,
            sortChanged,
          );
        },
      ),
      StreamBuilder<bool>(
        initialData: fileListLocalManager.loadingChangedCommand.lastResult,
        stream: fileListLocalManager.loadingChangedCommand,
        builder: (context, snapshot) =>
            snapshot.data! ? const LinearProgressIndicator() : Container(),
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
          ? fileListLocalManager.emptyFileList
          : fileListLocalManager.filesChangedCommand.lastResult,
      stream: fileListLocalManager.filesChangedCommand.where(
        // this filter makes sure that if viewType is changed while loading we do not run into trouble
        (event) =>
            event.config.sortType == fileListLocalManager.sortConfig.sortType,
      ),
      builder: (context, files) => RefreshIndicator(
        onRefresh: () async => fileListLocalManager.updateFilesAndFolders(),
        child: _buildImageView(choice, files.data!),
      ),
    );
  }
}
