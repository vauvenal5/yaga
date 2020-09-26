import 'package:flutter/material.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/widgets/image_views/category_view.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_views/grid_view.dart';

class ImageViewContainer extends StatelessWidget {
  final FileListLocalManager fileListLocalManager;
  final ChoicePreference choicePreference;
  final List<NcFile> Function(List<NcFile>) _filter;

  ImageViewContainer({@required this.fileListLocalManager, @required this.choicePreference, filter = _defaultFilter}) : this._filter = filter;

  static List<NcFile> _defaultFilter(List<NcFile> files) => files; 

  Widget _buildImageView(ChoicePreference choice, List<NcFile> files) {
    List<NcFile> filteredFiles = this._filter(files);

    if(choice.value == GridViewWidget.viewKey) {
      return GridViewWidget(filteredFiles);
    }

    if(choice.value == CategoryView.viewKey) {
      return CategoryView(filteredFiles);
    }

    return CategoryViewExp(filteredFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //todo: generalize stream builder for preferences
        StreamBuilder<ChoicePreference>(
          initialData: getIt.get<SharedPreferencesService>().loadChoicePreference(this.choicePreference),
          stream: getIt.get<SettingsManager>().updateSettingCommand
            .where((event) => event.key == choicePreference.key)
            .map((event) => event as ChoicePreference),
          builder: (context, choice) {
            return StreamBuilder<List<NcFile>>(
              initialData: this.fileListLocalManager.filesChangedCommand.lastResult,
              stream: this.fileListLocalManager.filesChangedCommand,
              builder: (context, files) => RefreshIndicator(
                child: _buildImageView(choice.data, files.data),
                onRefresh: () async => this.fileListLocalManager.updateFilesAndFolders()
              )
            );
          }
        ),
        StreamBuilder<bool>(
          initialData: this.fileListLocalManager.loadingChangedCommand.lastResult,
          stream: this.fileListLocalManager.loadingChangedCommand,
          builder: (context, snapshot) => snapshot.data ? LinearProgressIndicator() : Container(),
        )
      ]
    );
  }
}