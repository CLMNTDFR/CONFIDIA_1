import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardWidgetType {
  greeting,
  stats,
  quickActions,
  pendingPayments,
  recentDocs,
  deadlines,
  importantDocs,
  activity,
  connectedAccounts,
  aiAnalyzed,
}

extension DashboardWidgetTypeX on DashboardWidgetType {
  String get label => switch (this) {
        DashboardWidgetType.greeting => 'Bienvenue',
        DashboardWidgetType.stats => 'Statistiques',
        DashboardWidgetType.quickActions => 'Actions rapides',
        DashboardWidgetType.pendingPayments => 'Paiements en attente',
        DashboardWidgetType.recentDocs => 'Documents récents',
        DashboardWidgetType.deadlines => 'Échéances importantes',
        DashboardWidgetType.importantDocs => 'Documents importants',
        DashboardWidgetType.activity => 'Activité récente',
        DashboardWidgetType.connectedAccounts => 'Comptes connectés',
        DashboardWidgetType.aiAnalyzed => 'Documents analysés par IA',
      };

  String get iconName => switch (this) {
        DashboardWidgetType.greeting => 'waving_hand',
        DashboardWidgetType.stats => 'analytics',
        DashboardWidgetType.quickActions => 'bolt',
        DashboardWidgetType.pendingPayments => 'payment',
        DashboardWidgetType.recentDocs => 'folder',
        DashboardWidgetType.deadlines => 'event',
        DashboardWidgetType.importantDocs => 'star',
        DashboardWidgetType.activity => 'history',
        DashboardWidgetType.connectedAccounts => 'link',
        DashboardWidgetType.aiAnalyzed => 'ai',
      };
}

class DashboardLayout {
  final List<DashboardWidgetType> order;
  final Set<DashboardWidgetType> hidden;
  final bool editMode;

  const DashboardLayout({
    required this.order,
    this.hidden = const {},
    this.editMode = false,
  });

  List<DashboardWidgetType> get visible => order.where((w) => !hidden.contains(w)).toList();

  DashboardLayout copyWith({
    List<DashboardWidgetType>? order,
    Set<DashboardWidgetType>? hidden,
    bool? editMode,
  }) {
    return DashboardLayout(
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
      editMode: editMode ?? this.editMode,
    );
  }
}

class DashboardLayoutNotifier extends StateNotifier<DashboardLayout> {
  DashboardLayoutNotifier()
      : super(const DashboardLayout(
          order: [
            DashboardWidgetType.greeting,
            DashboardWidgetType.stats,
            DashboardWidgetType.pendingPayments,
            DashboardWidgetType.quickActions,
            DashboardWidgetType.recentDocs,
            DashboardWidgetType.deadlines,
            DashboardWidgetType.aiAnalyzed,
            DashboardWidgetType.connectedAccounts,
            DashboardWidgetType.activity,
            DashboardWidgetType.importantDocs,
          ],
        ));

  void toggleEditMode() => state = state.copyWith(editMode: !state.editMode);

  void toggleWidget(DashboardWidgetType type) {
    final hidden = Set<DashboardWidgetType>.from(state.hidden);
    if (hidden.contains(type)) {
      hidden.remove(type);
    } else {
      hidden.add(type);
    }
    state = state.copyWith(hidden: hidden);
  }

  void reorderVisible(int oldIndex, int newIndex) {
    final visible = List<DashboardWidgetType>.from(state.visible);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = visible.removeAt(oldIndex);
    visible.insert(newIndex, item);
    final hiddenItems = state.order.where((w) => state.hidden.contains(w)).toList();
    state = state.copyWith(order: [...visible, ...hiddenItems]);
  }

  void reset() {
    state = const DashboardLayout(
      order: [
        DashboardWidgetType.greeting,
        DashboardWidgetType.stats,
        DashboardWidgetType.pendingPayments,
        DashboardWidgetType.quickActions,
        DashboardWidgetType.recentDocs,
        DashboardWidgetType.deadlines,
        DashboardWidgetType.aiAnalyzed,
        DashboardWidgetType.connectedAccounts,
        DashboardWidgetType.activity,
        DashboardWidgetType.importantDocs,
      ],
    );
  }
}

final dashboardLayoutProvider = StateNotifierProvider<DashboardLayoutNotifier, DashboardLayout>((ref) {
  return DashboardLayoutNotifier();
});
