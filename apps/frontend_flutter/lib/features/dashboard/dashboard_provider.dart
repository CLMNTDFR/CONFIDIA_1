import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardWidgetType {
  greeting,
  serenityBriefing,
  weekOverview,
  stats,
  expensesTrend,
  paymentsOverview,
  documentsBreakdown,
  hubActivity,
  quickActions,
  pendingPayments,
  recentDocs,
  deadlines,
  importantDocs,
  activity,
  connectedAccounts,
  aiAnalyzed,
}

/// Widgets hidden by default (redundant with the nav, the banner, or other pages).
const Set<DashboardWidgetType> kDefaultHiddenDashboardWidgets = {
  DashboardWidgetType.stats,
  DashboardWidgetType.quickActions,
  DashboardWidgetType.importantDocs,
  DashboardWidgetType.aiAnalyzed,
  DashboardWidgetType.activity,
};

/// Default order: visible first, then hidden ones (restorable in customize mode).
const List<DashboardWidgetType> kDefaultDashboardOrder = [
  DashboardWidgetType.serenityBriefing,
  DashboardWidgetType.weekOverview,
  DashboardWidgetType.expensesTrend,
  DashboardWidgetType.paymentsOverview,
  DashboardWidgetType.documentsBreakdown,
  DashboardWidgetType.hubActivity,
  DashboardWidgetType.pendingPayments,
  DashboardWidgetType.recentDocs,
  DashboardWidgetType.deadlines,
  DashboardWidgetType.connectedAccounts,
  // Hidden by default (end of list for customize mode).
  DashboardWidgetType.stats,
  DashboardWidgetType.quickActions,
  DashboardWidgetType.importantDocs,
  DashboardWidgetType.aiAnalyzed,
  DashboardWidgetType.activity,
];

extension DashboardWidgetTypeX on DashboardWidgetType {
  String get label => switch (this) {
        DashboardWidgetType.greeting => 'Bienvenue',
        DashboardWidgetType.serenityBriefing => 'Indice de sérénité',
        DashboardWidgetType.weekOverview => 'Ma semaine en un coup d\'œil',
        DashboardWidgetType.stats => 'Statistiques',
        DashboardWidgetType.expensesTrend => 'Évolution des dépenses',
        DashboardWidgetType.paymentsOverview => 'Vue des paiements',
        DashboardWidgetType.documentsBreakdown => 'Répartition documentaire',
        DashboardWidgetType.hubActivity => 'Activité du hub',
        DashboardWidgetType.quickActions => 'Actions rapides',
        DashboardWidgetType.pendingPayments => 'Paiements en attente',
        DashboardWidgetType.recentDocs => 'Documents récents',
        DashboardWidgetType.deadlines => 'Échéances importantes',
        DashboardWidgetType.importantDocs => 'Documents importants',
        DashboardWidgetType.activity => 'Activité récente',
        DashboardWidgetType.connectedAccounts => 'Comptes connectés',
        DashboardWidgetType.aiAnalyzed => 'Documents analysés par Cofid-IA',
      };

  bool get isHalfWidth => switch (this) {
        DashboardWidgetType.connectedAccounts => true,
        DashboardWidgetType.recentDocs => true,
        DashboardWidgetType.importantDocs => true,
        DashboardWidgetType.paymentsOverview => true,
        DashboardWidgetType.expensesTrend => true,
        _ => false,
      };

  double? get fixedHeight => switch (this) {
        DashboardWidgetType.connectedAccounts => 228,
        DashboardWidgetType.recentDocs => 228,
        DashboardWidgetType.importantDocs => 228,
        DashboardWidgetType.paymentsOverview => 292,
        DashboardWidgetType.expensesTrend => 292,
        _ => null,
      };

  bool get isDemo => switch (this) {
        DashboardWidgetType.serenityBriefing => true,
        DashboardWidgetType.stats => true,
        DashboardWidgetType.expensesTrend => true,
        DashboardWidgetType.paymentsOverview => true,
        DashboardWidgetType.hubActivity => true,
        DashboardWidgetType.quickActions => true,
        DashboardWidgetType.pendingPayments => true,
        DashboardWidgetType.connectedAccounts => true,
        DashboardWidgetType.aiAnalyzed => true,
        _ => false,
      };

  String get iconName => switch (this) {
        DashboardWidgetType.greeting => 'waving_hand',
        DashboardWidgetType.serenityBriefing => 'psychology',
        DashboardWidgetType.weekOverview => 'calendar_view_week',
        DashboardWidgetType.stats => 'analytics',
        DashboardWidgetType.expensesTrend => 'trending_up',
        DashboardWidgetType.paymentsOverview => 'bar_chart',
        DashboardWidgetType.documentsBreakdown => 'pie_chart',
        DashboardWidgetType.hubActivity => 'stacked_bar',
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

  List<DashboardWidgetType> get visible =>
      order.where((w) => !hidden.contains(w) && w != DashboardWidgetType.greeting).toList();

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
          order: kDefaultDashboardOrder,
          hidden: kDefaultHiddenDashboardWidgets,
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
    if (newIndex > oldIndex) newIndex -= 1;
    moveVisible(oldIndex, newIndex);
  }

  void moveVisible(int from, int to) {
    if (from == to) return;
    final visible = List<DashboardWidgetType>.from(state.visible);
    final item = visible.removeAt(from);
    visible.insert(to, item);
    _commitVisibleOrder(visible);
  }

  void setVisibleOrder(List<DashboardWidgetType> visible) => _commitVisibleOrder(visible);

  void reorderSegments(int oldIndex, int newIndex, List<List<DashboardWidgetType>> segments) {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<List<DashboardWidgetType>>.from(segments);
    final segment = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, segment);
    setVisibleOrder(reordered.expand((group) => group).toList());
  }

  void _commitVisibleOrder(List<DashboardWidgetType> visible) {
    final hiddenItems = state.order.where((w) => state.hidden.contains(w)).toList();
    state = state.copyWith(order: [...visible, ...hiddenItems]);
  }

  void reset() {
    state = const DashboardLayout(
      order: kDefaultDashboardOrder,
      hidden: kDefaultHiddenDashboardWidgets,
    );
  }
}

final dashboardLayoutProvider = StateNotifierProvider<DashboardLayoutNotifier, DashboardLayout>((ref) {
  return DashboardLayoutNotifier();
});
