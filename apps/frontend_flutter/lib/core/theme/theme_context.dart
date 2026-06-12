import 'package:flutter/material.dart';

import 'palette.dart';

/// Accès à la palette de marque courante depuis n'importe quel [BuildContext].
extension ConfidiaThemeContext on BuildContext {
  ConfidiaPalette get palette =>
      Theme.of(this).extension<ConfidiaPaletteTheme>()?.palette ?? ConfidiaPalette.blue;
}
