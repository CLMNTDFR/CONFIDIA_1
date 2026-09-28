import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Light bridge between the guided tour and [AccessControlScreen].
final accessTourHeaderExpandedProvider = StateProvider<bool?>((ref) => null);
final accessTourTabIndexProvider = StateProvider<int?>((ref) => null);

void clearAccessTourBridge(WidgetRef ref) {
  ref.read(accessTourHeaderExpandedProvider.notifier).state = null;
  ref.read(accessTourTabIndexProvider.notifier).state = null;
}
