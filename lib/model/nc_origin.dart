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
  /// * Simple username: xyz
  /// * Username with special characters: xyz@email.com
  /// * LDAP UUID: 2522ba7c2-xxxxxxxx-yyyyyy
  final String username;

  /// Display name, username, loign name can be different things in Nextcloud.
  /// Display name can be equal to the username or anything else like: Forename Lastname
  final String displayName;

  /// Can be an email or an username.
  final String loginName;

  NcOrigin(
    this.uri,
    this.username,
    this.displayName,
    this.loginName,
  );

  String get domain => uri.host;
  //todo: when refactoring, how will we handle subpaths in origin for user home folder in app directory?
  /// We are using the login name for backwards compability however if a user logs out and in again with different login names
  /// then this user will not be mapped back to the right data folder.
  String get userDomain => "$loginName@${uri.host}";

  /// This is the old representation of root. Still needed for the [MappingManager] to work properly.
  /// Returns uri in form: nc://user@host/
  /// With user being encoded.
  /// We are using the login name for backwards compability however if a user logs out and in again with different login names
  /// then this user will not be mapped back to the right data folder.
  Uri get userEncodedDomainRoot => Uri(
        scheme: uri.scheme,
        userInfo: Uri.encodeComponent(loginName),
        host: uri.host,
        path: "/",
      );
}
