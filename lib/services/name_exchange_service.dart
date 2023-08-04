import 'package:yaga/services/media_file_service.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/services/uri_name_resolver.dart';

class NameExchangeService extends Service<NameExchangeService> {

  Map<String, UriNameResolver> resolvers = {};

  NameExchangeService(MediaFileService mediaFileService) {
    resolvers[mediaFileService.scheme] = mediaFileService;
  }

  Uri convertUriToHumanReadableUri(Uri uri) {
    if(resolvers.containsKey(uri.scheme)) {
      return resolvers[uri.scheme]!.getHumanReadableForm(uri);
    }
    return uri;
  }
}