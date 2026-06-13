import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/access_control_models.dart';
import '../../shared/models/calendar_event_model.dart';
import 'event_type_config.dart';

class CalendarGroupInfo {
  final String id;
  final String label;

  const CalendarGroupInfo({required this.id, required this.label});
}

const calendarGroups = [
  CalendarGroupInfo(id: 'family', label: 'Famille'),
  CalendarGroupInfo(id: 'club', label: 'Club'),
];

class CalendarNotifier extends StateNotifier<List<CalendarEventModel>> {
  CalendarNotifier(this._ref) : super(List.from(MockEcosystem.allCalendarEvents));

  final Ref _ref;

  ConfidiaPalette get _palette => ConfidiaPalette.byId(_ref.watch(colorPaletteProvider));

  List<CalendarEventModel> eventsForDay(DateTime day, {Set<String>? groups}) {
    return _filtered(groups: groups).where((e) =>
        e.start.year == day.year && e.start.month == day.month && e.start.day == day.day).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<CalendarEventModel> filtered({EventType? type, Set<String>? groups}) {
    var list = _filtered(groups: groups);
    if (type != null) list = list.where((e) => e.eventType == type).toList();
    return list;
  }

  List<CalendarEventModel> _filtered({Set<String>? groups}) {
    if (groups == null || groups.isEmpty) return List.from(state);
    return state.where((e) => groups.contains(e.calendarGroup)).toList();
  }

  void add(CalendarEventModel event) => state = [...state, event];

  void update(CalendarEventModel event) {
    state = [for (final e in state) if (e.id == event.id) event else e];
  }

  void delete(String id) => state = state.where((e) => e.id != id).toList();

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

final calendarProvider = StateNotifierProvider<CalendarNotifier, List<CalendarEventModel>>((ref) {
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
    state = state.copyWith(loading: false, proposal: _proposalFor(0));
  }

  Future<void> regenerate() async {
    final next = (state.variantIndex + 1) % _variantCount;
    state = state.copyWith(loading: true, variantIndex: next, clearProposal: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(loading: false, proposal: _proposalFor(next));
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

  PlanningProposal _proposalFor(int index) {
    final events = _visibleEvents;
    final groups = _ref.read(activeCalendarGroupsProvider);
    final multi = groups.length > 1;

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
              'Analyse multi-agendas ($_groupsLabel) : la journée J+3 concentre des événements familiaux le matin '
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
              'Alternative : regrouper les déplacements famille le matin et bloquer 17h30-19h30 pour le club, '
              'avec notification automatique aux deux agendas.',
          alternatives: ['Synchroniser les rappels CONFIDIA', 'Exporter le planning partagé'],
        ),
        PlanningProposal(
          conflicts: const [],
          proposal:
              'Aucun conflit bloquant détecté entre les agendas sélectionnés sur les 7 prochains jours. '
              'Surveillance recommandée le mercredi soir (créneau club récurrent).',
          alternatives: ['Planifier une analyse hebdomadaire'],
        ),
      ];
      return variants[index % variants.length];
    }

    if (groups.contains('club')) {
      final clubVariants = [
        const PlanningProposal(
          conflicts: [
            PlanningConflict(id: 'c1', title: 'Double réservation terrain', severity: 'high', events: ['Entraînement U17 · 18h00', 'Réunion staff · 18h00']),
          ],
          proposal: 'Chevauchement sur le terrain synthétique à 18h00. Proposition : décaler la réunion staff à 19h30.',
          alternatives: ['Réunion staff → 19h30', 'Entraînement → 16h30'],
        ),
        const PlanningProposal(
          conflicts: [
            PlanningConflict(id: 'c1', title: 'Double réservation terrain', severity: 'high', events: ['Entraînement U17 · 18h00', 'Réunion staff · 18h00']),
          ],
          proposal: 'Alternative : déplacer l\'entraînement U17 au créneau 16h30 et conserver la réunion staff à 18h00.',
          alternatives: ['Prévenir les parents par notification', 'Réserver le terrain annexe'],
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
            'L\'agenda famille affiche ${events.length} événement(s) sur la période visible. '
            'La journée J+3 est particulièrement chargée (échéance, RDV, réunion, rappel).\n\n'
            'Proposition : regrouper les rappels administratifs en une session de 30 min le matin.',
        alternatives: ['Décaler le RDV médical', 'Activer les rappels CONFIDIA groupés'],
      ),
      PlanningProposal(
        conflicts: const [
          PlanningConflict(id: 'c2', title: 'Échéances proches', severity: 'low', events: ['Paiement EDF · J+5', 'Déclaration CAF · J+5']),
        ],
        proposal:
            'Deux démarches administratives tombent le même jour (J+5). '
            'Proposition : traiter EDF et CAF dans un bloc unique à 18h00.',
        alternatives: ['Programmer un rappel la veille', 'Partager la tâche entre parents'],
      ),
    ];
    return familyVariants[index % familyVariants.length];
  }

  String get analyzeLabel {
    final groups = _ref.read(activeCalendarGroupsProvider);
    if (groups.length > 1) return 'Analyser les agendas ($_groupsLabel)';
    final label = calendarGroups.firstWhere((g) => groups.contains(g.id), orElse: () => calendarGroups.first).label;
    return 'Analyser l\'agenda $label';
  }
}

final calendarPlanningProvider = StateNotifierProvider<CalendarPlanningNotifier, CalendarPlanningState>(
  (ref) => CalendarPlanningNotifier(ref),
);
