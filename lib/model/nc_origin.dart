class NcOrigin {
  /// This uri represents the original server uri with port and path if specified.
  /// Only the scheme is changed to 'nc'.
  ///
  /// In case of a local file: file://device.local
  ///
  /// Examples for valid [uri] values:
  /// * cloud.com: Domain
  /// * nc.cloud.com: Subdomain
  /// * www.cloud.com: Equal to subdomain.
  /// * www.cloud.com/nc: Nextcloud root behind subpath.
  /// * www.cloud.com:7443: Nextcloud root behind different port.
  final Uri uri;

  /// Examples for valid [username] values:
  /// * xyz: Simple username.
  /// * xyz@email.com: Username with special characters.
  final String username;

  NcOrigin(this.uri, this.username);

  String get domain => uri.host;
  //todo: when refactoring, how will we handle subpaths in origin for user home folder in app directory?
  String get userDomain => "$username@${uri.host}";

  /// This is the old representation of root. Still needed for the [MappingManager] to work properly.
  /// Returns uri in form: nc://user@host/
  /// With user being encoded.
  Uri get userEncodedDomainRoot => Uri(
        scheme: this.uri.scheme,
        userInfo: Uri.encodeComponent(this.username),
        host: this.uri.host,
        path: "/",
      );
}
