import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:wc_flutter_share/wc_flutter_share.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';

enum SelectionViewMenu { share }

class SelectionPopupMenuButton extends StatelessWidget {
  final FileListLocalManager fileListLocalManager;

  SelectionPopupMenuButton({@required this.fileListLocalManager});

  @override
  Widget build(BuildContext context) {
    return YagaPopupMenuButton<SelectionViewMenu>(
      _buildSelectionPopupMenu,
      _popupMenuHandler,
    );
  }

  List<PopupMenuEntry<SelectionViewMenu>> _buildSelectionPopupMenu(
      BuildContext context) {
    return [
      PopupMenuItem(
        child: ListMenuEntry(Icons.share, "Share"),
        value: SelectionViewMenu.share,
      ),
    ];
  }

  void _popupMenuHandler(BuildContext context, SelectionViewMenu result) {
    if (result == SelectionViewMenu.share) {
      if (fileListLocalManager.selected.length == 1 &&
          fileListLocalManager.selected[0].localFile.existsSync()) {
        NcFile selected = fileListLocalManager.selected[0];

        WcFlutterShare.share(
          //todo: dp we need to move this to a service or controller?
          sharePopupTitle: 'share',
          fileName: selected.name,
          mimeType: lookupMimeType(
            selected.localFile.path,
          ), //todo: move mime type to NcFile
          bytesOfFile: (selected.localFile as File).readAsBytesSync(),
        ).then((value) => fileListLocalManager.deselectAll());
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text(
              "Currently sharing supports only one already downloaded file."),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
