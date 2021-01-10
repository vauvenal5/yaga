import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
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
      if (fileListLocalManager.selected
              .where((element) => !element.localFile.existsSync())
              .toList()
              .length >
          0) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content:
              Text("Currently sharing supports only already downloaded files."),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      Share.shareFiles(
          fileListLocalManager.selected.map((e) => e.localFile.path).toList());
    }
  }
}
