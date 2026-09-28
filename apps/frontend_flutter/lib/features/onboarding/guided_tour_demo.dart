import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access_control/access_control_provider.dart';
import 'guided_tour_access_bridge.dart';
import 'guided_tour_provider.dart';

/// Light automatic actions during some tutorial steps.
class GuidedTourDemo {
  GuidedTourDemo._();

  static Future<void> run(WidgetRef ref, GuidedTourDemoAction action) async {
    switch (action) {
      case GuidedTourDemoAction.none:
      case GuidedTourDemoAction.initThemes:
        // Themes are initialized explicitly before the spotlight.
        return;
      case GuidedTourDemoAction.prepareAccess:
        await _prepareAccess(ref, tabIndex: 0);
      case GuidedTourDemoAction.prepareMembers:
        await _prepareAccess(ref, tabIndex: 1);
      case GuidedTourDemoAction.demoStructures:
        await _demoStructures(ref);
    }
  }

  static Future<void> _prepareAccess(WidgetRef ref, {required int tabIndex}) async {
    ref.read(accessTourHeaderExpandedProvider.notifier).state = true;
    ref.read(accessTourTabIndexProvider.notifier).state = tabIndex;
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> _demoStructures(WidgetRef ref) async {
    final notifier = ref.read(accessControlProvider.notifier);
    final state = ref.read(accessControlProvider);
    final profiles = state.allProfiles;
    if (profiles.length < 2) return;

    final first = profiles[0].id;
    final second = profiles[1].id;
    notifier.setStructure(second);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!ref.read(guidedTourProvider).active) return;
    notifier.setStructure(first);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  static void onTourEnded(WidgetRef ref) {
    clearAccessTourBridge(ref);
  }
}
