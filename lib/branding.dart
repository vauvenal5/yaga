import 'package:neon_framework/theme.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// The custom theme used in the Neon app.
const neonTheme = NeonTheme(
  branding: branding,
);

/// The custom branding used in the Neon app.
const branding = Branding(
  name: 'Nextcloud Yaga',
  logo: VectorGraphic(
    width: 100,
    height: 100,
    loader: AssetBytesLoader(
      'assets/logo_inverted.svg.vec',
    ),
  ),
  nameInsteadOfSearchBar: true,
  sourceCodeURL: 'https://github.com/vauvenal5/yaga',
  issueTrackerURL: 'https://github.com/vauvenal5/yaga/issues',
  legalese: 'Copyright © 2026, vauvenal5\nUnder AGPLv3 license',
);
