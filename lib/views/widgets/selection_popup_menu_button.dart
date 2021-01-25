import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/widgets/selection_action_cancel_dialog.dart';
import 'package:yaga/views/widgets/selection_action_danger_dialog.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';

enum SelectionViewMenu { share, delete, copy, move }

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
      PopupMenuItem(
        child: ListMenuEntry(Icons.delete, "Delete"),
        value: SelectionViewMenu.delete,
      ),
      PopupMenuItem(
        child: ListMenuEntry(Icons.copy, "Copy"),
        value: SelectionViewMenu.copy,
      ),
      PopupMenuItem(
        child: ListMenuEntry(Icons.forward, "Move"),
        value: SelectionViewMenu.move,
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
      return;
    }

    if (result == SelectionViewMenu.delete) {
      showDialog(
        context: context,
        useRootNavigator: false,
        builder: (contextDialog) => this.fileListLocalManager.isRemoteUri
            ? SelectionActionDangerDialog(
                title: "Delete location",
                cancelButton: 'Keep',
                normalAction: 'Delete locally',
                aggressiveAction: 'Delete remotely',
                action: (agg) => _openDeletingDialog(context, agg),
                bodyBuilder: (builderContext) => <Widget>[
                  Text(
                    "If you delete your images locally, they will be deleted from your phone only.",
                  ),
                  Text(
                    "If you delete them remotely they will be deleted from your phone and server.",
                  ),
                ],
              )
            : SelectionActionDangerDialog(
                title: "Delete",
                cancelButton: 'Keep',
                aggressiveAction: 'Delete',
                action: (agg) => _openDeletingDialog(context, false),
                bodyBuilder: (builderContext) => <Widget>[
                  Text(
                    "This images seem to be local to your phone. Do you really want to delete them?",
                  ),
                ],
              ),
      );
    }

    if (result == SelectionViewMenu.copy || result == SelectionViewMenu.move) {
      Navigator.pushNamed(
        context,
        PathSelectorScreen.route,
        arguments: PathSelectorScreenArguments(
          uri: this.fileListLocalManager.uri,
          fixedOrigin: true,
          onSelect: (uri) => showDialog(
            context: context,
            useRootNavigator: false,
            builder: (contextDialog) => SelectionActionDangerDialog(
              title: "Overwrite Existing",
              cancelButton: 'Cancel',
              normalAction: 'Skip existing',
              aggressiveAction: 'Overwrite existing',
              action: (agg) => _openCancelableDialog(
                context,
                result == SelectionViewMenu.copy ? "Copying..." : "Moving...",
                result == SelectionViewMenu.copy
                    ? () => this
                        .fileListLocalManager
                        .copySelected(uri, overwrite: agg)
                    : () => this
                        .fileListLocalManager
                        .moveSelected(uri, overwrite: agg),
              ),
              bodyBuilder: (builderContext) => <Widget>[
                Text(
                  "Do you want to overwrite existing files, if any?",
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _openDeletingDialog(BuildContext context, bool aggressive) =>
      _openCancelableDialog(
        context,
        "Deleting...",
        () => this.fileListLocalManager.deleteSelected(!aggressive),
      );

  void _openCancelableDialog(
    BuildContext context,
    String text,
    Future<bool> Function() actionCallback,
  ) {
    bool dialogOpen = true;

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => SelectionActionCancelDialog(
        text,
        this.fileListLocalManager.cancelSelectionAction,
      ),
    ).whenComplete(() => dialogOpen = false);

    actionCallback().whenComplete(() {
      if (dialogOpen) {
        Navigator.pop(context);
      }
    });
  }
}
