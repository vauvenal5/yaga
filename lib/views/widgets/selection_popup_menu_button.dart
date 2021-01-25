import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/model/route_args/path_selector_screen_arguments.dart';
import 'package:yaga/views/screens/path_selector_screen.dart';
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
            ? _buildRemoteDialog(
                contextDialog,
                context,
                const Text("Delete location"),
                const Text('Keep'),
                const Text('Delete locally'),
                const Text('Delete remotely'),
                _openDeletingDialog,
                <Widget>[
                  Text(
                      "If you delete your images locally, they will be deleted from your phone only."),
                  Text(
                      "If you delete them remotely they will be deleted from your phone and server."),
                ],
              )
            : _buildLocalDialog(contextDialog, context),
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
            builder: (contextDialog) => _buildRemoteDialog(
              contextDialog,
              context,
              const Text("Overwrite Existing"),
              const Text('Cancel'),
              const Text('Skip existing'),
              const Text('Overwrite existing'),
              (context, aggressive) => _openCancelableDialog(
                context,
                result == SelectionViewMenu.copy ? "Copying..." : "Moving...",
                result == SelectionViewMenu.copy
                    ? () => this
                        .fileListLocalManager
                        .copySelected(uri, overwrite: aggressive)
                    : () => this
                        .fileListLocalManager
                        .moveSelected(uri, overwrite: aggressive),
              ),
              <Widget>[
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

  AlertDialog _buildRemoteDialog(
    BuildContext contextDialog,
    BuildContext parentContex,
    Text title,
    Text cancelButton,
    Text normalAction,
    Text aggressiveAction,
    Function(BuildContext, bool) openDialog,
    List<Widget> children,
  ) {
    return AlertDialog(
      title: title,
      content: SingleChildScrollView(
        child: ListBody(
          children: children,
        ),
      ),
      actions: [
        TextButton(
          child: cancelButton,
          onPressed: () {
            Navigator.pop(contextDialog);
          },
        ),
        TextButton(
          child: normalAction,
          onPressed: () {
            Navigator.pop(contextDialog);
            openDialog(parentContex, false);
          },
        ),
        TextButton(
          child: aggressiveAction,
          style: TextButton.styleFrom(primary: Colors.red),
          onPressed: () {
            Navigator.pop(parentContex);
            openDialog(parentContex, true);
          },
        ),
      ],
    );
  }

  AlertDialog _buildLocalDialog(
      BuildContext contextDialog, BuildContext parentContex) {
    return AlertDialog(
      title: const Text("Deleting"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
                "This images seem to be local to your phone. Do you really want to delete them?"),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Keep'),
          onPressed: () {
            Navigator.pop(contextDialog);
          },
        ),
        TextButton(
          child: Text('Delete'),
          style: TextButton.styleFrom(primary: Colors.red),
          onPressed: () {
            Navigator.pop(contextDialog);
            this._openDeletingDialog(parentContex, false);
          },
        ),
      ],
    );
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
      builder: (context) => AlertDialog(
        title: Text(text),
        content: SingleChildScrollView(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => this.fileListLocalManager.cancelSelectionAction(),
          ),
        ],
      ),
    ).whenComplete(() => dialogOpen = false);

    actionCallback().whenComplete(() {
      if (dialogOpen) {
        Navigator.pop(context);
      }
    });
  }
}
