import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_provider.dart';
import 'onboarding_targets.dart';

enum GuidedTourStepId {
  welcome,
  startMyDay,
  serenity,
  weekOverview,
  customize,
  navigation,
  notifications,
  settingsNav,
  appearance,
  gouvernanceTile,
  accessStructures,
  orgChart,
  memberRights,
  homeReturn,
}

enum GuidedTourDemoAction {
  none,
  initThemes,
  prepareAccess,
  prepareMembers,
  demoStructures,
}

/// The 4 theme combinations shown in the tutorial.
const guidedTourThemeCombos = <(ConfidiaPaletteId, bool, String)>[
  (ConfidiaPaletteId.blue, true, 'Bleu · Sombre'),
  (ConfidiaPaletteId.blue, false, 'Bleu · Clair'),
  (ConfidiaPaletteId.rose, false, 'Rose · Clair'),
  (ConfidiaPaletteId.rose, true, 'Rose · Sombre'),
];

class GuidedTourStep {
  final GuidedTourStepId id;
  final String message;
  final String? wideMessage;
  final GlobalKey? targetKey;
  final Alignment bubbleAlignment;
  final Alignment? wideBubbleAlignment;
  final String? route;
  final GuidedTourDemoAction demoAction;
  final String? liveMessage;

  const GuidedTourStep({
    required this.id,
    required this.message,
    this.wideMessage,
    this.targetKey,
    this.bubbleAlignment = Alignment.bottomCenter,
    this.wideBubbleAlignment,
    this.route,
    this.demoAction = GuidedTourDemoAction.none,
    this.liveMessage,
  });

  String messageFor(BuildContext context, {bool live = false}) {
    final chosen = live && liveMessage != null ? liveMessage! : message;
    return OnboardingTargets.isWideLayout(context) && wideMessage != null && !(live && liveMessage != null)
        ? wideMessage!
        : chosen;
  }

  Alignment bubbleAlignmentFor(BuildContext context) =>
      OnboardingTargets.isWideLayout(context) && wideBubbleAlignment != null
          ? wideBubbleAlignment!
          : bubbleAlignment;

  GlobalKey? targetKeyFor(BuildContext context) {
    if (id == GuidedTourStepId.navigation) {
      return OnboardingTargets.navigationFor(context);
    }
    return targetKey;
  }

  bool get isThemeBrowser => id == GuidedTourStepId.appearance;
}

final List<GuidedTourStep> guidedTourSteps = [
      const GuidedTourStep(
        id: GuidedTourStepId.welcome,
        message:
            'Bienvenue sur Confidia ! Je suis Confid•IA. Laissez-moi vous faire découvrir votre espace en quelques minutes.',
        bubbleAlignment: Alignment.center,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.startMyDay,
        message:
            'Chaque matin, démarrez avec Commencer ma journée : Confid•IA résume vos priorités en quelques secondes.',
        targetKey: OnboardingTargets.startMyDay,
        bubbleAlignment: Alignment.bottomCenter,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.serenity,
        message:
            'Voici votre Indice de sérénité : le score du moment. Le détail et les priorités du jour sont dans Commencer ma journée.',
        targetKey: OnboardingTargets.serenity,
        bubbleAlignment: Alignment.bottomCenter,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.weekOverview,
        message:
            'Votre semaine en un coup d’œil : charge, échéances et moments clés, pour anticiper sans stress.',
        targetKey: OnboardingTargets.weekOverview,
        bubbleAlignment: Alignment.bottomCenter,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.customize,
        message:
            'Personnalisez votre accueil : réorganisez ou masquez les blocs pour ne garder que l’essentiel.',
        targetKey: OnboardingTargets.customizeFab,
        bubbleAlignment: Alignment.topCenter,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.navigation,
        message:
            'Depuis cette barre, vous accédez à la messagerie, aux paiements, aux documents et au calendrier.',
        wideMessage:
            'Depuis ce menu latéral, vous accédez à la messagerie, aux paiements, aux documents et au calendrier.',
        bubbleAlignment: Alignment.topCenter,
        wideBubbleAlignment: Alignment.centerRight,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.notifications,
        message: 'Les alertes importantes se retrouvent ici, dans le centre de notifications.',
        targetKey: OnboardingTargets.notifications,
        bubbleAlignment: Alignment.bottomCenter,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.settingsNav,
        message: 'Passons aux Paramètres : c’est ici que vous affinez l’apparence et l’organisation de votre espace.',
        wideMessage: 'Passons aux Paramètres, en bas du menu : apparence, organisation et préférences s’y trouvent.',
        targetKey: OnboardingTargets.settingsNav,
        bubbleAlignment: Alignment.topCenter,
        wideBubbleAlignment: Alignment.centerRight,
        route: '/dashboard',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.appearance,
        message:
            'Deux palettes (bleu et rose) et deux modes (clair et sombre) donnent quatre ambiances. Parcourez-les avec les flèches, puis continuez.',
        targetKey: OnboardingTargets.appearanceSection,
        bubbleAlignment: Alignment.bottomCenter,
        route: '/settings',
        demoAction: GuidedTourDemoAction.initThemes,
      ),
      GuidedTourStep(
        id: GuidedTourStepId.gouvernanceTile,
        message:
            'Gouvernance & accès permet de définir qui fait partie de votre organisation, avec quels rôles et quels droits.',
        targetKey: OnboardingTargets.gouvernanceTile,
        bubbleAlignment: Alignment.bottomCenter,
        route: '/settings',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.accessStructures,
        message:
            'Choisissez une structure (famille, club…) : chaque profil adapte l’organigramme et les droits associés.',
        targetKey: OnboardingTargets.structureChips,
        bubbleAlignment: Alignment.bottomCenter,
        route: '/access-control',
        demoAction: GuidedTourDemoAction.prepareAccess,
        liveMessage:
            'Votre espace Famille est créé dès la première connexion. Le nom, le type et l\'icône se modifient ici.',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.orgChart,
        message:
            'L’organigramme se manipule par glisser-déposer. Sur mobile, le plein écran permet de zoomer confortablement.',
        targetKey: OnboardingTargets.orgChart,
        bubbleAlignment: Alignment.topCenter,
        route: '/access-control',
        demoAction: GuidedTourDemoAction.prepareAccess,
        liveMessage:
            'Vous apparaissez dans l\'organigramme, même seul. Glissez un membre pour le rattacher à un autre.',
      ),
      GuidedTourStep(
        id: GuidedTourStepId.memberRights,
        message:
            'Pour chaque membre, vous ajustez les droits accordés : documents, calendrier, paiements, et bien plus.',
        targetKey: OnboardingTargets.membersPanel,
        bubbleAlignment: Alignment.topCenter,
        route: '/access-control',
        demoAction: GuidedTourDemoAction.prepareMembers,
        liveMessage:
            'Pour chaque membre, les droits sont enregistrés : calendrier, documents, paiements, invitations.',
      ),
      const GuidedTourStep(
        id: GuidedTourStepId.homeReturn,
        message:
            'Vous êtes prêt ! Je vous ramène à l’accueil. Explorez à votre rythme, je reste disponible dans vos modules Confid•IA.',
        bubbleAlignment: Alignment.center,
        route: '/dashboard',
      ),
    ];

class GuidedTourState {
  final bool armed;
  final bool active;
  final int stepIndex;
  final int themeIndex;
  final int themesSeenMask;

  const GuidedTourState({
    this.armed = false,
    this.active = false,
    this.stepIndex = 0,
    this.themeIndex = 0,
    this.themesSeenMask = 0,
  });

  GuidedTourStep? get currentStep {
    final steps = guidedTourSteps;
    if (!active || stepIndex < 0 || stepIndex >= steps.length) return null;
    return steps[stepIndex];
  }

  bool get isLastStep => stepIndex >= guidedTourSteps.length - 1;

  int get totalSteps => guidedTourSteps.length;

  int get themesSeenCount {
    var n = 0;
    for (var i = 0; i < guidedTourThemeCombos.length; i++) {
      if ((themesSeenMask & (1 << i)) != 0) n++;
    }
    return n;
  }

  bool get allThemesSeen => themesSeenCount >= guidedTourThemeCombos.length;

  String get currentThemeLabel => guidedTourThemeCombos[themeIndex].$3;

  bool canProceedFromCurrentStep() {
    final step = currentStep;
    if (step == null) return false;
    if (step.isThemeBrowser) return allThemesSeen;
    return true;
  }

  GuidedTourState copyWith({
    bool? armed,
    bool? active,
    int? stepIndex,
    int? themeIndex,
    int? themesSeenMask,
  }) {
    return GuidedTourState(
      armed: armed ?? this.armed,
      active: active ?? this.active,
      stepIndex: stepIndex ?? this.stepIndex,
      themeIndex: themeIndex ?? this.themeIndex,
      themesSeenMask: themesSeenMask ?? this.themesSeenMask,
    );
  }
}

class GuidedTourNotifier extends StateNotifier<GuidedTourState> {
  GuidedTourNotifier(this._ref) : super(const GuidedTourState());

  final Ref _ref;
  bool? _savedDark;
  ConfidiaPaletteId? _savedPalette;

  void arm() {
    state = const GuidedTourState(armed: true, active: false, stepIndex: 0);
  }

  void startIfArmed() {
    if (!state.armed || state.active) return;
    state = state.copyWith(armed: false, active: true, stepIndex: 0);
  }

  void startNow() {
    state = const GuidedTourState(armed: false, active: true, stepIndex: 0);
  }

  void next() {
    if (!state.active) return;
    if (!state.canProceedFromCurrentStep()) return;
    if (state.isLastStep) {
      skip();
      return;
    }
    state = state.copyWith(stepIndex: state.stepIndex + 1);
  }

  void skip() {
    _restoreTheme();
    state = const GuidedTourState();
  }

  void reset() {
    _restoreTheme();
    state = const GuidedTourState();
  }

  void initThemes() {
    _savedDark ??= _ref.read(themeModeProvider);
    _savedPalette ??= _ref.read(colorPaletteProvider);
    state = state.copyWith(themeIndex: 0, themesSeenMask: 1 << 0);
    _applyTheme(0);
  }

  void previousTheme() {
    if (!state.active) return;
    final next = (state.themeIndex - 1 + guidedTourThemeCombos.length) % guidedTourThemeCombos.length;
    _selectTheme(next);
  }

  void nextTheme() {
    if (!state.active) return;
    final next = (state.themeIndex + 1) % guidedTourThemeCombos.length;
    _selectTheme(next);
  }

  void _selectTheme(int index) {
    state = state.copyWith(
      themeIndex: index,
      themesSeenMask: state.themesSeenMask | (1 << index),
    );
    _applyTheme(index);
  }

  void _applyTheme(int index) {
    final combo = guidedTourThemeCombos[index];
    _ref.read(colorPaletteProvider.notifier).state = combo.$1;
    _ref.read(themeModeProvider.notifier).state = combo.$2;
  }

  void _restoreTheme() {
    if (_savedDark != null) {
      _ref.read(themeModeProvider.notifier).state = _savedDark!;
    }
    if (_savedPalette != null) {
      _ref.read(colorPaletteProvider.notifier).state = _savedPalette!;
    }
    _savedDark = null;
    _savedPalette = null;
  }
}

final guidedTourProvider = StateNotifierProvider<GuidedTourNotifier, GuidedTourState>(
  (ref) => GuidedTourNotifier(ref),
);
