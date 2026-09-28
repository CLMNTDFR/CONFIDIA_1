import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'palette.dart';

/// `true` = dark mode.
final themeModeProvider = StateProvider<bool>((ref) => true);

/// Brand color theme (blue by default).
final colorPaletteProvider = StateProvider<ConfidiaPaletteId>((ref) => ConfidiaPaletteId.blue);

ConfidiaPalette watchPalette(WidgetRef ref) =>
    ConfidiaPalette.byId(ref.watch(colorPaletteProvider));
