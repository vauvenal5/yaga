import 'package:logger/logger.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager_base.dart';
import 'package:yaga/model/mapping_node.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/uri_utils.dart';

class MappingManager with Isolateable<MappingManager> {
  final Logger _logger = getLogger(MappingManager);
  final NextCloudService _nextCloudService;
  final SystemLocationService _systemLocationService;
  final SettingsManagerBase _settingsManager;

  RxCommand<MappingPreference, MappingPreference> mappingUpdatedCommand;

  MappingNode root;
  Map<String, MappingPreference> mappings = {};

  MappingManager(this._settingsManager, this._nextCloudService,
      this._systemLocationService) {
    root = MappingNode();

    this.mappingUpdatedCommand = RxCommand.createSync((param) => param);

    this
        ._settingsManager
        .updateSettingCommand
        .where((event) => event is MappingPreference)
        .listen((event) {
      if (mappings.containsKey(event.key)) {
        _removeFromTree(mappings[event.key].remote.value.pathSegments, 0, root);
      }
      //todo: somehow/somewhere the view needs to be refreshed when the mapping changes
      _addMappingPreferenceToTree(event, 0, root);
      mappings[event.key] = event;

      mappingUpdatedCommand(event);
    });
  }

  void _removeFromTree(List<String> path, int index, MappingNode current) {
    if (index == path.length) {
      current.mapping = null;
      return;
    }

    _removeFromTree(path, index + 1, current.nodes[path[index]]);
  }

  void _addMappingPreferenceToTree(
      MappingPreference pref, int pathIndex, MappingNode currentNode) {
    if (pathIndex == pref.remote.value.pathSegments.length) {
      currentNode.mapping = pref;
      return;
    }

    String pathSegment = pref.remote.value.pathSegments[pathIndex];
    currentNode.nodes.putIfAbsent(pathSegment, () => MappingNode());
    _addMappingPreferenceToTree(
        pref, pathIndex + 1, currentNode.nodes[pathSegment]);
  }

  MappingPreference _getMappingPrefernce(Uri uri, MappingPreference selected,
      int pathIndex, MappingNode currentNode) {
    if (currentNode == null) {
      return selected;
    }

    if (uri.pathSegments.length == pathIndex) {
      return currentNode.mapping ?? selected;
    }

    return _getMappingPrefernce(uri, currentNode.mapping ?? selected,
        pathIndex + 1, currentNode.nodes[uri.pathSegments[pathIndex]]);
  }

  String _appendLocalMappingFolder(String path) {
    return UriUtils.chainPathSegments(path, _nextCloudService.getUserDomain());
  }

  Future<Uri> mapToLocalUri(Uri remoteUri) async {
    MappingPreference mapping = _getMappingPrefernce(
        remoteUri,
        _getDefaultMapping(this._systemLocationService.externalAppDirUri),
        0,
        root);

    return _mapUri(remoteUri, mapping);
  }

  Future<Uri> mapToTmpUri(Uri remoteUri) async {
    return _mapUri(remoteUri,
        _getDefaultMapping(this._systemLocationService.tmpAppDirUri));
  }

  Uri _mapUri(Uri remoteUri, MappingPreference mapping) {
    _logger.d("Mapping remoteUri: " + remoteUri.toString());
    _logger.d("Mapping local: " + mapping.local.value.toString());
    _logger.d("Mapping remote: " + mapping.remote.value.toString());
    Uri mappedUri =
        UriUtils.fromPathSegments(uri: mapping.local.value, pathSegments: [
      mapping.local.value.path,
      remoteUri.path.replaceFirst(mapping.remote.value.path, "")
    ]);
    _logger.d("Mapped uri: " + mappedUri.toString());
    //todo: is returning an absolute uri from mapping manager the best option?
    return this._systemLocationService.absoluteUriFromInternal(mappedUri);
  }

  MappingPreference _getDefaultMapping(Uri root) {
    UriPreference local = UriPreference(
        "localDefault",
        "local deafult",
        UriUtils.fromUri(
            uri: root, path: _appendLocalMappingFolder(root.path)));
    UriPreference remote = UriPreference(
        "remoteDefault", "remote default", this._nextCloudService.getOrigin());
    return MappingPreference("default", "default", remote, local);
  }

  Future<Uri> mapToRemoteUri(Uri local, Uri remote) async {
    Uri defaultInternal = this._systemLocationService.externalAppDirUri;
    MappingPreference mapping = _getMappingPrefernce(
        remote, _getDefaultMapping(defaultInternal), 0, root);
    String relativePath = local.path.replaceFirst(
        mapping == null ? defaultInternal.path : mapping.local.value.path, "");
    return UriUtils.fromPathSegments(
        uri: remote, pathSegments: [mapping.remote.value.path, relativePath]);
  }

  Future<Uri> mapTmpToRemoteUri(Uri local, Uri remote) async {
    Uri defaultInternal = this._systemLocationService.tmpAppDirUri;
    String relativePath = local.path
        .replaceFirst(_appendLocalMappingFolder(defaultInternal.path), "");
    return UriUtils.fromUri(uri: remote, path: relativePath);
  }
}
