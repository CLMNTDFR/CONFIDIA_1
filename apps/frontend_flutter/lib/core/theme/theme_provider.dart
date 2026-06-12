import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'palette.dart';

/// `true` = mode sombre.
final themeModeProvider = StateProvider<bool>((ref) => true);

/// Thème couleur de marque (bleu par défaut).
final colorPaletteProvider = StateProvider<ConfidiaPaletteId>((ref) => ConfidiaPaletteId.blue);

ConfidiaPalette watchPalette(WidgetRef ref) =>
    ConfidiaPalette.byId(ref.watch(colorPaletteProvider));
