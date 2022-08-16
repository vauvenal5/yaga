import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
import 'package:yaga/views/widgets/action_danger_dialog.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';
import 'package:yaga/views/widgets/selection_action_cancel_dialog.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';

enum SelectionViewMenu { share, delete, copy, move, download }

class SelectionPopupMenuButton extends StatelessWidget {
  final FileListLocalManager fileListLocalManager;

  const SelectionPopupMenuButton({required this.fileListLocalManager});

  @override
  Widget build(BuildContext context) {
    return YagaPopupMenuButton<SelectionViewMenu>(
      _buildSelectionPopupMenu,
      _popupMenuHandler,
    );
  }

  List<PopupMenuEntry<SelectionViewMenu>> _buildSelectionPopupMenu(
      BuildContext context) {
    if (fileListLocalManager.isRemoteUri) {
      return const [
        PopupMenuItem(
          value: SelectionViewMenu.share,
          child: ListMenuEntry(Icons.share, "Share"),
        ),
        PopupMenuItem(
          value: SelectionViewMenu.delete,
          child: ListMenuEntry(Icons.delete, "Delete"),
        ),
        PopupMenuItem(
          value: SelectionViewMenu.copy,
          child: ListMenuEntry(Icons.copy, "Copy"),
        ),
        PopupMenuItem(
          value: SelectionViewMenu.move,
          child: ListMenuEntry(Icons.forward, "Move"),
        ),
        PopupMenuItem(
          value: SelectionViewMenu.download,
          child: ListMenuEntry(Icons.file_download, "Download"),
        ),
      ];
    }

    return const [
      PopupMenuItem(
        value: SelectionViewMenu.share,
        child: ListMenuEntry(Icons.share, "Share"),
      ),
      PopupMenuItem(
        value: SelectionViewMenu.delete,
        child: ListMenuEntry(Icons.delete, "Delete"),
      ),
    ];
  }

  void _popupMenuHandler(BuildContext context, SelectionViewMenu result) {
    if (result == SelectionViewMenu.share) {
      if (fileListLocalManager.selected
          .where((element) => !element.localFile!.exists)
          .toList()
          .isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Currently sharing supports only already downloaded files.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Share.shareFiles(fileListLocalManager.selected
          .map((e) => e.localFile!.file.path)
          .toList());
      return;
    }

    if (result == SelectionViewMenu.delete) {
      showDialog(
        context: context,
        useRootNavigator: false,
        builder: (contextDialog) => fileListLocalManager.isRemoteUri
            ? ActionDangerDialog(
                title: "Delete location",
                cancelButton: 'Keep',
                normalAction: 'Delete locally',
                aggressiveAction: 'Delete remotely',
                action: (agg) => _openDeletingDialog(context, agg),
                bodyBuilder: (builderContext) => <Widget>[
                  const Text(
                    "If you delete your images locally, they will be deleted from your phone only.",
                  ),
                  const Text(
                    "If you delete them remotely they will be deleted from your phone and server.",
                  ),
                ],
              )
            : ActionDangerDialog(
                title: "Delete",
                cancelButton: 'Keep',
                aggressiveAction: 'Delete',
                action: (agg) => _openDeletingDialog(context, false),
                bodyBuilder: (builderContext) => <Widget>[
                  const Text(
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
          uri: fileListLocalManager.uri,
          fixedOrigin: true,
          onSelect: (uri) => showDialog(
            context: context,
            useRootNavigator: false,
            builder: (contextDialog) => ActionDangerDialog(
              title: "Overwrite Existing",
              cancelButton: 'Cancel',
              normalAction: 'Skip existing',
              aggressiveAction: 'Overwrite existing',
              action: (agg) => _openCancelableDialog(
                context,
                result == SelectionViewMenu.copy ? "Copying..." : "Moving...",
                result == SelectionViewMenu.copy
                    ? () =>
                        fileListLocalManager.copySelected(uri, overwrite: agg)
                    : () =>
                        fileListLocalManager.moveSelected(uri, overwrite: agg),
              ),
              bodyBuilder: (builderContext) => <Widget>[
                const Text(
                  "Do you want to overwrite existing files, if any?",
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (result == SelectionViewMenu.download) {
      for (final file in fileListLocalManager.selected) {
        getIt.get<FileManager>().downloadImageCommand(
              DownloadFileRequest(file, overrideGlobalPersistFlag: true),
            );
      }

      fileListLocalManager.deselectAll();
    }
  }

  void _openDeletingDialog(BuildContext context, bool aggressive) =>
      _openCancelableDialog(
        context,
        "Deleting...",
        () => fileListLocalManager.deleteSelected(local: !aggressive),
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
        fileListLocalManager.cancelSelectionAction,
      ),
    ).whenComplete(() => dialogOpen = false);

    actionCallback().whenComplete(() {
      if (dialogOpen) {
        Navigator.pop(context);
      }
    });
  }
}
