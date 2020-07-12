import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sticky_infinite_list/sticky_infinite_list.dart';
import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preference.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/preferences/BoolPreferenceWidget.dart';
import 'package:yaga/views/widgets/remote_image_widget.dart';

class CategoryWidget extends StatefulWidget {
  final Uri _uri;
  final BoolPreference _experimental;

  CategoryWidget(this._uri, this._experimental);

  @override
  State<StatefulWidget> createState() => CategoryWidgetState();
}

class CategoryWidgetState extends State<CategoryWidget> {
  List<DateTime> _dates = [];
  Map<String, List<NcFile>> _sortedFiles = Map();
  
  StreamSubscription<NcFile> _updateFilesListCommandSubscription;
  StreamSubscription<MappingPreference> _updatedMappingPreferenceCommandSubscription;
  StreamSubscription<NcFile> _updateFileListSubscripton;
  bool _loading;

  @override
  void dispose() {
    this._updateFilesListCommandSubscription.cancel();
    this._updatedMappingPreferenceCommandSubscription.cancel();
    this._updateFileListSubscripton.cancel();
    super.dispose();
  }

  void _updateFilesAndFolders() {
    this._dates = [];
    this._sortedFiles = Map();

    setState(() {
      _loading = true;
    });

    //cancel old subscription
    this._updateFilesListCommandSubscription?.cancel();
    
    this._updateFilesListCommandSubscription = getIt.get<FileManager>().listFiles(widget._uri)
    .where((event) => !event.isDirectory)
    .listen(
      (file) {
        DateTime lastModified = file.lastModified;
        DateTime date = DateTime(lastModified.year, lastModified.month, lastModified.day);
        
        setState(() {
          if(!this._dates.contains(date)) {
            this._dates.add(date);
            this._dates.sort((date1, date2) => date2.compareTo(date1));
          }

          String key = this._createKey(date);
          _sortedFiles.putIfAbsent(key, () => []);
          //todo-sv: this has to be solved in a better way... double calling happens for example when in path selector screen navigating to same path
          //todo-sv: dart magic matches the files properly however it will be better to add a custom equals --> how does dart runtime hashcode work? Oo
          if(!_sortedFiles[key].contains(file)) {
            _sortedFiles[key].add(file);
            _sortedFiles[key].sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          }
        });
      },
      onDone: () => setState((){
        _loading=false;
      })
    );
  }

  @override
  void initState() {
    this._updateFilesAndFolders();
    this._updatedMappingPreferenceCommandSubscription = getIt.get<MappingManager>().mappingUpdatedCommand
      .listen((value) => this._updateFilesAndFolders());
    this._updateFileListSubscripton = getIt.get<FileManager>().updateFileList.listen((file) {
      DateTime lastModified = file.lastModified;
      DateTime date = DateTime(lastModified.year, lastModified.month, lastModified.day);
      String key = this._createKey(date);
      setState(() {
        this._sortedFiles[key].remove(file);
        if(this._sortedFiles[key].isEmpty) {
          this._dates.remove(date);
          this._sortedFiles.remove(key);
        }
      });
    });
    super.initState();
  }
  

  @override
  void didUpdateWidget(CategoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._updateFilesAndFolders();
  }

  String _createKey(DateTime date) => date.toString().split(" ")[0];


  Widget _buildHeader(String key) {
    return Container(
      height: 30.0,
      color: Theme.of(context).accentColor,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        key,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  SliverStickyHeader _buildCategory(String key) {
    return SliverStickyHeader(
      key: ValueKey(key),
      header: _buildHeader(key),
      sliver: SliverGrid(
        key: ValueKey(key+"_grid"),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _buildImage(key, index);
            //return Image.file(_sortedFiles[key][index].localFile, cacheWidth: 64, key: ValueKey(_sortedFiles[key][index].uri.path),);
          },
          childCount: _sortedFiles[key].length
        ), 
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        )
      )
    );
  }

  Widget _buildImage(String key, int itemIndex) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, ImageScreen.route, arguments: ImageScreenArguments(_sortedFiles[key], itemIndex, title: key)),
      child: RemoteImageWidget(_sortedFiles[key][itemIndex], key: ValueKey(_sortedFiles[key][itemIndex].uri.path), cacheWidth: 512, ),
    );
  }

  Widget _buildExperimental() {
    ScrollController scrollController = ScrollController();

    InfiniteList infiniteList = InfiniteList(
      posChildCount: _dates.length,
      controller: scrollController,
      builder: (BuildContext context, int indexCategory) {
        String key = this._createKey(_dates[indexCategory]);
        /// Builder requires [InfiniteList] to be returned
        return InfiniteListItem(
          /// Header builder
          headerBuilder: (BuildContext context) {
            return _buildHeader(key);
          },
          /// Content builder
          contentBuilder: (BuildContext context) {
            return GridView.builder(
              key: ValueKey(key+"_grid"),
              controller: scrollController,
              shrinkWrap: true,
              itemCount: _sortedFiles[key].length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ), 
              itemBuilder: (context, itemIndex) {
                return _buildImage(key, itemIndex);
              }
            );
          },
        );
      }
    );

    return infiniteList;
  }

  Widget _buildStickyList() {
    List<Widget> slivers = [];

    //todo: the actual issue behind the performance problems is that for many categorise we are keepint all headers in memory at once and also a tone of images
    //--> it seems the headerSliver is not cleaning up properly
    //--> long terme we need to find a solution for this!
    _dates.forEach((element) {
      print("rebuilding list");
      String key = this._createKey(element);
      slivers.add(_buildCategory(key));
    });

    DefaultStickyHeaderController sticky = DefaultStickyHeaderController(
      key: ValueKey("mainGrid"),
      child: CustomScrollView(
        key: ValueKey("mainGridView"),
        slivers: slivers,
    ));

    return sticky;
  }

  @override
  Widget build(BuildContext context) {
    print("drawing list");
    
    //todo: generalize stream builder for preferences
    return Stack(
      children: [
        StreamBuilder<BoolPreference>(
          initialData: getIt.get<SharedPreferencesService>().loadBoolPreference(widget._experimental),
          stream: getIt.get<SettingsManager>().updateSettingCommand
            .where((event) => event.key == widget._experimental.key)
            .map((event) => event as BoolPreference),
          builder: (context, snapshot) => snapshot.data.value ? _buildExperimental() : _buildStickyList()
        ),
        _loading ? LinearProgressIndicator() : Container()
      ]
    );
  }
}