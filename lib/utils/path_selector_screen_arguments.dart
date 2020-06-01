class PathSelectorScreenArguments {
  final String path;
  final void Function() onCancel;
  final void Function(String) onSelect;

  PathSelectorScreenArguments(this.path, this.onCancel, this.onSelect);
  PathSelectorScreenArguments.empty() : path = "/sdcard", onCancel = null, onSelect = null;
}