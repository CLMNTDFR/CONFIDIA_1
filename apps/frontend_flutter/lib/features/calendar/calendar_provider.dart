import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error_message.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/workspace_session.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/access_control_models.dart';
import '../../shared/models/calendar_event_model.dart';
import 'event_type_config.dart';

enum CalendarView { month, week, day }

final calendarViewProvider = StateProvider<CalendarView>((ref) => CalendarView.month);

class CalendarGroupInfo {
  final String id;
  final String label;

  const CalendarGroupInfo({required this.id, required this.label});
}

const calendarGroups = [
  CalendarGroupInfo(id: 'family', label: 'Famille'),
  CalendarGroupInfo(id: 'club', label: 'Club'),
];

class CalendarState {
  final List<CalendarEventModel> items;
  final bool loading;
  final String? error;

  const CalendarState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  CalendarState copyWith({
    List<CalendarEventModel>? items,
    bool? loading,
    String? error,
  }) {
    return CalendarState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier(this._ref) : super(const CalendarState()) {
    _bind(_ref.read(authStateProvider));
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (!workspaceSessionChanged(prev, next)) return;
      _bind(next);
    });
  }

  final Ref _ref;
  int _loadGen = 0;

  bool get _demo => _ref.read(authStateProvider).isDemoSession;

  /// Use [read] so palette changes do not rebuild the whole calendar event list.
  ConfidiaPalette get _palette => ConfidiaPalette.byId(_ref.read(colorPaletteProvider));

  void _bind(AuthState auth) {
    if (!auth.isAuthenticated) {
      state = const CalendarState();
      return;
    }
    if (auth.isDemoSession) {
      state = CalendarState(items: List.of(MockEcosystem.allCalendarEvents));
      return;
    }
    refresh();
  }

  Future<void> refresh() async {
    if (_demo) {
      state = CalendarState(items: List.of(MockEcosystem.allCalendarEvents));
      return;
    }
    if (!_ref.read(authStateProvider).isAuthenticated) {
      state = const CalendarState();
      return;
    }
    final gen = ++_loadGen;
    state = state.copyWith(loading: true, error: null);
    try {
      await _ref.read(apiClientProvider).ensureConfigured();
      final items = await _ref.read(calendarApiServiceProvider).listEvents();
      if (gen != _loadGen) return;
      state = CalendarState(items: items);
    } catch (e) {
      if (gen != _loadGen) return;
      state = state.copyWith(
        loading: false,
        error: apiErrorMessage(e, fallback: 'Impossible de charger le calendrier'),
      );
    }
  }

  List<CalendarEventModel> eventsForDay(DateTime day, {Set<String>? groups}) {
    return _filtered(groups: groups)
        .where((e) => e.start.year == day.year && e.start.month == day.month && e.start.day == day.day)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<CalendarEventModel> filtered({EventType? type, Set<String>? groups}) {
    var list = _filtered(groups: groups);
    if (type != null) list = list.where((e) => e.eventType == type).toList();
    return list;
  }

  List<CalendarEventModel> _filtered({Set<String>? groups}) {
    if (groups == null || groups.isEmpty) return List.from(state.items);
    return state.items.where((e) => groups.contains(e.calendarGroup)).toList();
  }

  Future<void> add(CalendarEventModel event) async {
    if (_demo) {
      state = CalendarState(items: [...state.items, event]);
      return;
    }
    _loadGen++;
    try {
      await _ref.read(apiClientProvider).ensureConfigured();
      final saved = await _ref.read(calendarApiServiceProvider).create(event);
      _revealFamilyAgenda();
      state = CalendarState(items: [...state.items, saved]);
    } catch (e) {
      state = state.copyWith(
        error: apiErrorMessage(e, fallback: 'Impossible de créer l\'événement'),
      );
      rethrow;
    }
  }

  Future<void> update(CalendarEventModel event) async {
    if (_demo) {
      state = CalendarState(
        items: [for (final e in state.items) if (e.id == event.id) event else e],
      );
      return;
    }
    _loadGen++;
    try {
      await _ref.read(apiClientProvider).ensureConfigured();
      final saved = await _ref.read(calendarApiServiceProvider).update(event);
      state = CalendarState(
        items: [for (final e in state.items) if (e.id == saved.id) saved else e],
      );
    } catch (e) {
      state = state.copyWith(
        error: apiErrorMessage(e, fallback: 'Impossible d\'enregistrer l\'événement'),
      );
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    if (_demo) {
      state = CalendarState(items: state.items.where((e) => e.id != id).toList());
      return;
    }
    _loadGen++;
    try {
      await _ref.read(apiClientProvider).ensureConfigured();
      await _ref.read(calendarApiServiceProvider).delete(id);
      state = CalendarState(items: state.items.where((e) => e.id != id).toList());
    } catch (e) {
      state = state.copyWith(
        error: apiErrorMessage(e, fallback: 'Impossible de supprimer l\'événement'),
      );
      rethrow;
    }
  }

  void _revealFamilyAgenda() {
    final active = _ref.read(activeCalendarGroupsProvider);
    if (active.contains('family')) return;
    _ref.read(activeCalendarGroupsProvider.notifier).state = {...active, 'family'};
  }

  String nextId() => 'evt-${DateTime.now().millisecondsSinceEpoch}';

  CalendarEventModel buildEvent({
    String? id,
    required String title,
    String? description,
    required DateTime start,
    required DateTime end,
    required EventType eventType,
    String? location,
    bool allDay = false,
    int? documentId,
    String calendarGroup = 'family',
  }) {
    return CalendarEventModel(
      id: id ?? nextId(),
      title: title,
      description: description,
      start: start,
      end: end,
      eventType: eventType,
      location: location,
      allDay: allDay,
      color: colorForEventType(eventType, _palette),
      documentId: documentId,
      calendarGroup: calendarGroup,
    );
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(ref);
});

final calendarFilterProvider = StateProvider<EventType?>((ref) => null);

final activeCalendarGroupsProvider = StateProvider<Set<String>>((ref) => {'family'});

class CalendarPlanningState {
  final PlanningProposal? proposal;
  final bool loading;
  final int variantIndex;

  const CalendarPlanningState({this.proposal, this.loading = false, this.variantIndex = 0});

  CalendarPlanningState copyWith({PlanningProposal? proposal, bool? loading, int? variantIndex, bool clearProposal = false}) =>
      CalendarPlanningState(
        proposal: clearProposal ? null : (proposal ?? this.proposal),
        loading: loading ?? this.loading,
        variantIndex: variantIndex ?? this.variantIndex,
      );
}

class CalendarPlanningNotifier extends StateNotifier<CalendarPlanningState> {
  CalendarPlanningNotifier(this._ref) : super(const CalendarPlanningState());

  final Ref _ref;

  List<CalendarEventModel> get _visibleEvents {
    final groups = _ref.read(activeCalendarGroupsProvider);
    final typeFilter = _ref.read(calendarFilterProvider);
    return _ref.read(calendarProvider.notifier).filtered(type: typeFilter, groups: groups);
  }

  Future<void> analyze() async {
    state = state.copyWith(loading: true, clearProposal: true, variantIndex: 0);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final view = _ref.read(calendarViewProvider);
    state = state.copyWith(loading: false, proposal: _proposalFor(0, view));
  }

  Future<void> regenerate() async {
    final view = _ref.read(calendarViewProvider);
    final next = (state.variantIndex + 1) % _variantCount;
    state = state.copyWith(loading: true, variantIndex: next, clearProposal: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(loading: false, proposal: _proposalFor(next, view));
  }

  Future<void> refine(String prompt) async {
    if (state.proposal == null) return;
    state = state.copyWith(loading: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final base = state.proposal!;
    state = state.copyWith(
      loading: false,
      proposal: PlanningProposal(
        conflicts: base.conflicts,
        proposal:
            '${base.proposal}\n\nAjustement demandé : « $prompt »\n\n'
            'Nouvelle proposition intégrant votre consigne.',
        alternatives: [...base.alternatives, 'Notifier les participants'],
      ),
    );
  }

  void clear() => state = state.copyWith(clearProposal: true);

  int get _variantCount => _groupsLabel.contains('Famille') && _groupsLabel.contains('Club') ? 3 : 2;

  String get _groupsLabel {
    final groups = _ref.read(activeCalendarGroupsProvider);
    return calendarGroups.where((g) => groups.contains(g.id)).map((g) => g.label).join(' + ');
  }

  PlanningProposal _proposalFor(int index, CalendarView view) {
    final events = _visibleEvents;
    final groups = _ref.read(activeCalendarGroupsProvider);
    final multi = groups.length > 1;
    final periodLabel = switch (view) {
      CalendarView.day => 'ce jour',
      CalendarView.week => 'cette semaine',
      CalendarView.month => 'ce mois',
    };

    if (events.isEmpty) {
      return PlanningProposal(
        conflicts: const [],
        proposal:
            'Aucun événement sur $periodLabel. Ajoutez un rendez-vous ou une échéance pour que Confid•IA propose un planning.',
        alternatives: const ['Créer un événement', 'Importer un document lié'],
      );
    }

    if (multi) {
      final variants = [
        PlanningProposal(
          conflicts: [
            const PlanningConflict(
              id: 'mx1',
              title: 'Conflit inter-agendas',
              severity: 'high',
              events: ['Famille · RDV pédiatre 14h00', 'Club · Réunion staff 18h00 · même soir chargé'],
            ),
          ],
          proposal:
              'Analyse multi-agendas ($_groupsLabel) sur $periodLabel : la journée J+3 concentre des événements familiaux le matin '
              'et un chevauchement club à 18h00 (entraînement U17 / réunion staff).\n\n'
              'Proposition : décaler la réunion staff à 19h30 et conserver l\'entraînement.',
          alternatives: ['Déléguer la récupération scolaire', 'Activer le mode co-parentalité'],
        ),
        PlanningProposal(
          conflicts: [
            PlanningConflict(
              id: 'mx2',
              title: 'Charge logistique élevée',
              severity: 'medium',
              events: ['${events.length} événements visibles sur la période'],
            ),
          ],
          proposal:
              'Alternative pour $periodLabel : regrouper les déplacements famille le matin et bloquer 17h30-19h30 pour le club, '
              'avec notification automatique aux deux agendas.',
          alternatives: ['Synchroniser les rappels CONFIDIA', 'Exporter le planning partagé'],
        ),
        PlanningProposal(
          conflicts: const [],
          proposal:
              'Aucun conflit bloquant détecté entre les agendas sélectionnés sur $periodLabel. '
              'Surveillance recommandée le mercredi soir (créneau club récurrent).',
          alternatives: ['Planifier une analyse hebdomadaire'],
        ),
      ];
      return variants[index % variants.length];
    }

    if (groups.contains('club')) {
      final clubVariants = [
        PlanningProposal(
          conflicts: const [
            PlanningConflict(id: 'c1', title: 'Double réservation terrain', severity: 'high', events: ['Entraînement U17 · 18h00', 'Réunion staff · 18h00']),
          ],
          proposal: 'Chevauchement sur le terrain synthétique à 18h00 ($periodLabel). Proposition : décaler la réunion staff à 19h30.',
          alternatives: const ['Réunion staff → 19h30', 'Entraînement → 16h30'],
        ),
        PlanningProposal(
          conflicts: const [
            PlanningConflict(id: 'c1', title: 'Double réservation terrain', severity: 'high', events: ['Entraînement U17 · 18h00', 'Réunion staff · 18h00']),
          ],
          proposal:
              'Alternative pour $periodLabel : déplacer l\'entraînement U17 au créneau 16h30 et conserver la réunion staff à 18h00.',
          alternatives: const ['Prévenir les parents par notification', 'Réserver le terrain annexe'],
        ),
      ];
      return clubVariants[index % clubVariants.length];
    }

    final familyVariants = [
      PlanningProposal(
        conflicts: const [
          PlanningConflict(id: 'c1', title: 'Journée dense', severity: 'medium', events: ['4 événements le même jour']),
        ],
        proposal:
            'L\'agenda famille affiche ${events.length} événement(s) sur $periodLabel. '
            'La journée J+3 est particulièrement chargée (échéance, RDV, réunion, rappel).\n\n'
            'Proposition : regrouper les rappels administratifs en une session de 30 min le matin.',
        alternatives: ['Décaler le RDV médical', 'Activer les rappels CONFIDIA groupés'],
      ),
      PlanningProposal(
        conflicts: const [
          PlanningConflict(id: 'c2', title: 'Échéances proches', severity: 'low', events: ['Paiement EDF · J+5', 'Déclaration CAF · J+5']),
        ],
        proposal:
            'Deux démarches administratives tombent le même jour (J+5) sur $periodLabel. '
            'Proposition : traiter EDF et CAF dans un bloc unique à 18h00.',
        alternatives: ['Programmer un rappel la veille', 'Partager la tâche entre parents'],
      ),
    ];
    return familyVariants[index % familyVariants.length];
  }

  String analyzeLabelFor(CalendarView view) {
    final groups = _ref.read(activeCalendarGroupsProvider);
    final period = switch (view) {
      CalendarView.day => 'du jour',
      CalendarView.week => 'de la semaine',
      CalendarView.month => 'du mois',
    };
    if (groups.length > 1) return 'Analyser les agendas ($_groupsLabel) $period';
    final label = calendarGroups.firstWhere((g) => groups.contains(g.id), orElse: () => calendarGroups.first).label;
    return 'Analyser l\'agenda $label $period';
  }

  String get analyzeLabel => analyzeLabelFor(_ref.read(calendarViewProvider));
}

final calendarPlanningProvider = StateNotifierProvider<CalendarPlanningNotifier, CalendarPlanningState>(
  (ref) => CalendarPlanningNotifier(ref),
);
