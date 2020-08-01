import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/mapping_node.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/uri_utils.dart';

class MappingManager {
  
  SettingsManager _settingsManager;

  LocalImageProviderService _localImageProviderService;

  NextCloudService _nextCloudService;

  RxCommand<MappingPreference, MappingPreference> mappingUpdatedCommand;

  MappingNode root;
  Map<String, MappingPreference> mappings = {};
  
  MappingManager(this._settingsManager, this._localImageProviderService, this._nextCloudService) {
    root = MappingNode();

    this.mappingUpdatedCommand = RxCommand.createSync((param) => param);
    
    this._settingsManager.updateSettingCommand.where((event) => event is MappingPreference)
      .listen((event) {
        if(mappings.containsKey(event.key)) {
          _removeFromTree(mappings[event.key].remote.value.pathSegments, 0, root);
        }
        //todo: somehow/somewhere the view needs to be refreshed when the mapping changes
        _addMappingPreferenceToTree(event, 0, root);
        mappings[event.key] = event;

        mappingUpdatedCommand(event);
      });
  }

  void _removeFromTree(List<String> path, int index, MappingNode current) {
    if(index == path.length) {
      current.mapping = null;
      return;
    }

    _removeFromTree(path, index+1, current.nodes[path[index]]);
  }

  void _addMappingPreferenceToTree(MappingPreference pref, int pathIndex, MappingNode currentNode) {
    if(pathIndex == pref.remote.value.pathSegments.length) {
      currentNode.mapping = pref;
      return;
    }

    String pathSegment = pref.remote.value.pathSegments[pathIndex];
    currentNode.nodes.putIfAbsent(pathSegment, () => MappingNode());
    _addMappingPreferenceToTree(pref, pathIndex+1, currentNode.nodes[pathSegment]);
  }

  MappingPreference _getMappingPrefernce(Uri uri, MappingPreference selected, int pathIndex, MappingNode currentNode) {
    if(currentNode == null) {
      return selected;
    }

    if(uri.pathSegments.length == pathIndex) {
      return currentNode.mapping??selected;
    }

    return _getMappingPrefernce(uri, currentNode.mapping??selected, pathIndex+1, currentNode.nodes[uri.pathSegments[pathIndex]]);
  }

  String _prependLocalMappingFolder(String path) {
    return "/${_nextCloudService.getUserDomain()}$path";
  }

  String _appendLocalMappingFolder(String path) {
    return "$path/${_nextCloudService.getUserDomain()}";
  }

  Future<File> mapToLocalFile(Uri remoteUri) async {
    MappingPreference mapping = _getMappingPrefernce(remoteUri, null, 0, root);

    if(mapping == null) {
      return this._localImageProviderService.getLocalFile(_prependLocalMappingFolder(remoteUri.path));
    }

    String mappedPath = remoteUri.path.replaceFirst(mapping.remote.value.path, "");
    return this._localImageProviderService.getLocalFile(mappedPath, internalPathPrefix: mapping.local.value);
  }

  Future<File> mapToTmpFile(Uri remoteUri) async {
    return _localImageProviderService.getTmpFile(_prependLocalMappingFolder(remoteUri.path));
  }

  Future<Uri> mapToRemoteUri(Uri local, Uri remote, Uri defaultInternal) async {
    MappingPreference mapping = _getMappingPrefernce(remote, null, 0, root);
    String relativePath = local.path.replaceFirst(mapping==null ? defaultInternal.path : mapping.local.value.path, "");
    //todo: solve this in a more elegant way
    if(mapping != null && mapping.remote.value.path != "/") {
      relativePath = mapping.remote.value.path + relativePath;
    }
    return UriUtils.fromUri(uri: remote, path: relativePath);
  }

  Future<Uri> mapTmpToRemoteUri(Uri local, Uri remote, Uri defaultInternal) async {
    String relativePath = local.path.replaceFirst(_appendLocalMappingFolder(defaultInternal.path), "");
    return UriUtils.fromUri(uri: remote, path: relativePath);
  }
}