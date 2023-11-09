import 'package:yaga/views/screens/browse_view.dart';

class FavoritesView extends BrowseView {
  @override
  String get pref => "favorites";

  const FavoritesView() : super(favorites: true);
}
