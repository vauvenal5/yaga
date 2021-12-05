import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';

class NavigationManager {
  RxCommand<DirectoryNavigationScreenArguments?,
          DirectoryNavigationScreenArguments?> showDirectoryNavigation =
      RxCommand.createSync((param) => param, initialLastResult: null);
}
