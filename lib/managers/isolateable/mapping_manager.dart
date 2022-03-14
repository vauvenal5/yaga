import 'dart:isolate';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/model/mapping_node.dart';
import 'package:yaga/model/preferences/mapping_preference.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/uri_utils.dart';

class MappingManager with Isolateable<MappingManager> {
  final _logger = YagaLogger.getLogger(MappingManager);
  final NextCloudService _nextCloudService;
  final SystemLocationService _systemLocationService;
  final SettingsManagerBase _settingsManager;

  RxCommand<MappingPreference, MappingPreference> mappingUpdatedCommand =
      RxCommand.createSync((param) => param);

  MappingNode root = MappingNode();
  Map<String, MappingPreference> mappings = {};

  MappingManager(this._settingsManager, this._nextCloudService,
      this._systemLocationService) {
    _settingsManager.updateSettingCommand
        .where((event) => event is MappingPreference)
        .listen((event) => handleMappingUpdate(event as MappingPreference));
  }

  @override
  Future<MappingManager> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    handleMappingUpdate(init.mapping);
    return this;
  }

  //todo: use a bridge and commands to handle incoming msgs in forgraound worker
  // @visibleForTesting
  void handleMappingUpdate(MappingPreference? event) {
    if (event == null) {
      return;
    }
    if (mappings.containsKey(event.key)) {
      _removeFromTree(mappings[event.key]!.remote.value.pathSegments, 0, root);
    }
    //todo: somehow/somewhere the view needs to be refreshed when the mapping changes
    _addMappingPreferenceToTree(event, 0, root);
    mappings[event.key!] = event;

    mappingUpdatedCommand(event);
  }

  void _removeFromTree(List<String> path, int index, MappingNode current) {
    if (index == path.length) {
      current.mapping = null;
      return;
    }

    _removeFromTree(path, index + 1, current.nodes[path[index]]!);
  }

  void _addMappingPreferenceToTree(
      MappingPreference pref, int pathIndex, MappingNode currentNode) {
    if (pathIndex >= pref.remote.value.pathSegments.length - 1) {
      currentNode.mapping = pref;
      return;
    }

    final String pathSegment = pref.remote.value.pathSegments[pathIndex];
    currentNode.nodes.putIfAbsent(pathSegment, () => MappingNode());
    _addMappingPreferenceToTree(
        pref, pathIndex + 1, currentNode.nodes[pathSegment]!);
  }

  MappingPreference _getMappingPrefernce(Uri uri, MappingPreference selected,
      int pathIndex, MappingNode? currentNode) {
    if (currentNode == null) {
      return selected;
    }

    if (uri.pathSegments.length == pathIndex) {
      return currentNode.mapping ?? selected;
    }

    return _getMappingPrefernce(uri, currentNode.mapping ?? selected,
        pathIndex + 1, currentNode.nodes[uri.pathSegments[pathIndex]]);
  }

  MappingPreference _getRootMappingPreference(Uri remoteUri) =>
      _getMappingPrefernce(
          remoteUri,
          _getDefaultMapping(_systemLocationService.internalStorage.uri),
          0,
          root);

  String _appendLocalMappingFolder(String path) {
    return chainPathSegments(
      path,
      _nextCloudService.origin!.userDomain,
    );
  }

  Future<bool> isSyncDelete(Uri remoteUri) async => _getRootMappingPreference(
        remoteUri,
      ).syncDeletes.value;

  Future<Uri> mapToLocalUri(Uri remoteUri) async => _mapUri(
        remoteUri,
        _getRootMappingPreference(remoteUri),
      );

  Future<Uri> mapToTmpUri(Uri remoteUri) async {
    return _mapUri(remoteUri,
        _getDefaultMapping(_systemLocationService.internalCache.uri));
  }

  Uri _mapUri(Uri remoteUri, MappingPreference mapping) {
    _logger.fine("Mapping remoteUri: $remoteUri");
    _logger.fine("Mapping local: ${mapping.local.value}");
    _logger.fine("Mapping remote: ${mapping.remote.value}");
    final Uri mappedUri = fromPathList(uri: mapping.local.value, paths: [
      mapping.local.value.path,
      remoteUri.path.replaceFirst(mapping.remote.value.path, "")
    ]);
    _logger.fine("Mapped uri: $mappedUri");
    //todo: is returning an absolute uri from mapping manager the best option?
    return _systemLocationService.absoluteUriFromInternal(mappedUri);
  }

  //todo: check what we are doing with this
  MappingPreference _getDefaultMapping(Uri root) {
    return MappingPreference(
      (builder) => builder
        ..key = "default"
        ..title = "default"
        ..remote.value = _nextCloudService.origin!.userEncodedDomainRoot
        ..local.value = fromUri(
          uri: root,
          path: _appendLocalMappingFolder(root.path),
        ),
    );
  }

  Future<Uri> mapToRemoteUri(Uri local, Uri remote) async {
    final MappingPreference mapping = _getRootMappingPreference(remote);
    final String relativePath = local.path.replaceFirst(
      mapping == null
          ? _systemLocationService.internalStorage.uri.path
          : mapping.local.value.path,
      "",
    );
    return fromPathList(
        uri: remote, paths: [mapping.remote.value.path, relativePath]);
  }

  Future<Uri> mapTmpToRemoteUri(Uri local, Uri remote) async {
    final Uri defaultInternal = _systemLocationService.internalCache.uri;
    final String relativePath = local.path
        .replaceFirst(_appendLocalMappingFolder(defaultInternal.path), "");
    return fromUri(uri: remote, path: relativePath);
  }
}
