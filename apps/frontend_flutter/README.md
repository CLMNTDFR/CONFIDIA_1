# CONFIDIA Frontend Flutter

Application multi-plateforme (web, mobile, desktop) du hub numérique CONFIDIA.

## Démarrage rapide

```bash
cd apps/frontend_flutter
flutter pub get
flutter run -d chrome --web-port=8082
```

Le backend doit tourner sur `http://localhost:8000`. Procédure complète (Docker, API, Flutter, tests) : [README principal](../../README.md).

---

## Design system

Guide de référence pour garder une interface cohérente entre les écrans et les futurs développements.

### Philosophie visuelle

- **Premium sobre** : surfaces glass, bordures fines, glow discret (jamais agressif).
- **Hiérarchie claire** : titres compacts, labels secondaires atténués, actions primaires visibles.
- **Thème adaptatif** : mode clair/sombre + palette de marque interchangeable.
- **Mobile-first** : barre de navigation flottante, insets dédiés, scroll avec clearance FAB.

---

### Palettes de marque

Deux thèmes couleur sont disponibles (réglables dans **Paramètres → Apparence**).

| | Thème bleu (défaut) | Thème rose |
|---|---|---|
| **Primary** | `#015AAB` | `#D20050` |
| **Primary light** | `#1A7FD4` | `#FF4D8A` |
| **Secondary** | `#06E5EF` | `#AF73F7` |
| **Accent** | `#3B9AE8` | `#4B96B4` |

**Fichier source :** `lib/core/theme/palette.dart`

#### Utilisation dans le code

```dart
import 'package:confidia/core/theme/theme_context.dart';

// Dans un widget :
final palette = context.palette;
palette.primary
palette.secondary
palette.brandGradient
palette.chartColors
```

> Ne jamais hardcoder les couleurs de marque. Toujours passer par `context.palette` ou `Theme.of(context).colorScheme.primary` (injecté depuis la palette active).

**Provider Riverpod :** `colorPaletteProvider` (`lib/core/theme/theme_provider.dart`)

---

### Couleurs sémantiques

Indépendantes de la palette de marque : `lib/core/theme/colors.dart`

| Token | Hex | Usage |
|---|---|---|
| `success` | `#10B981` | Statuts positifs, connecté |
| `warning` | `#F59E0B` | Alertes modérées |
| `error` | `#EF4444` | Erreurs, suppression |
| `info` | `#3B82F6` | Informations neutres |

#### Surfaces (dark / light)

| Token | Dark | Light |
|---|---|---|
| Background | `#06060B` | `#F5F5FA` |
| Surface | `#0E0E16` | `#FFFFFF` |
| Surface elevated | `#161622` | `#FAFAFE` |
| Border | `#2A2A3C` | `#E4E4EE` |
| Text primary | `#F4F4F8` | `#12121E` |
| Text secondary | `#9B9BAB` | `#5C5C6E` |

---

### Typographie

- **Police :** Inter (via `google_fonts`)
- **Fichier :** `lib/core/theme/typography.dart`

| Style | Taille | Poids | Usage |
|---|---|---|---|
| `displayLarge` | 48 | 700 | Hero landing |
| `headlineMedium` | 20 | 600 | Titres de section |
| `titleMedium` | 14 | 500 | Sous-titres, cartes |
| `bodyMedium` | 14 | 400 | Corps de texte |
| `labelSmall` | 10 | 500 | Métadonnées, chips |

**Champs de formulaire :** texte saisi à **13 px** (`ConfidiaTextFormField`).

---

### Espacements & rayons

`lib/core/theme/spacing.dart`

| Token | Valeur |
|---|---|
| `xs` | 4 px |
| `sm` | 8 px |
| `md` | 16 px |
| `lg` | 24 px |
| `xl` | 32 px |

| Rayon | Valeur |
|---|---|
| `radiusSm` | 8 px |
| `radiusMd` | 12 px |
| `radiusLg` | 16 px |
| `radiusXl` | 24 px |

**Insets pages :** `ConfidiaInsets.page(context)` tient compte de la bottom bar mobile.

---

### Dégradés

Définis sur `ConfidiaPalette` :

| Nom | Composition |
|---|---|
| `primaryGradient` | primary → primaryLight |
| `brandGradient` | primary → secondary → accent |
| `accentGradient` | secondary → accent |
| `heroGradient` | Fond hero login (variante selon palette) |
| `meshGradientDark` | Orbes d'arrière-plan (mode sombre) |

---

### Composants UI

Bibliothèque partagée dans `lib/shared/widgets/`.

| Composant | Rôle |
|---|---|
| `GlassCard` | Carte glassmorphism de base |
| `MeshBackground` | Fond mesh + orbes colorés |
| `ConfidiaGlowButton` | Bouton d'action primaire/secondaire |
| `ConfidiaGlowChip` | Filtre / pill sélectionnable |
| `ConfidiaGlowSegmentedControl` | Sélecteur à onglets animé |
| `ConfidiaTextFormField` | Input formulaire premium |
| `ConfidiaSwitch` / `ConfidiaSwitchTile` | Toggle avec glow |
| `ConfidiaModalSheet` | Bottom sheet / modale |
| `ConfidiaPalettePicker` | Sélecteur thème bleu/rose |
| `ConfidiaPageReveal` | Animation d'entrée de page |
| `PremiumChartStage` | Conteneur graphiques animés |
| `ConfidiaAnimatedLogo` | Logo animé (login, splash) |

#### Règles pour nouveaux composants

1. Lire la palette via `context.palette`, jamais de hex de marque en dur.
2. Réutiliser `GlassCard`, `ConfidiaGlowButton`, `ConfidiaTextFormField` avant de créer un variant.
3. Couleurs de statut métier : `status.themeColor(context.palette)` sur les extensions de modèle.
4. Graphiques : `palette.chartColors` ou `DashboardChartData.*(palette: context.palette)`.
5. Tester en **bleu + rose**, **clair + sombre**, et en **viewport mobile**.

---

### Animations

| Profil | Durée | Usage |
|---|---|---|
| `ConfidiaPageReveal` standard | ~800 ms | Entrée des listes / pages |
| `PremiumChartMotion.entry` | 2 500 ms | Graphiques dashboard |
| Press scale (boutons/chips) | 90–200 ms | Feedback tactile |

Pages **sans** animation d'entrée : dashboard, calendrier, profil, paramètres.

---

### Structure thème Flutter

```
lib/core/theme/
├── palette.dart          # Palettes bleu/rose + ThemeExtension
├── colors.dart           # Couleurs sémantiques & surfaces
├── theme.dart            # ThemeData Material 3
├── theme_context.dart    # extension context.palette
├── theme_provider.dart   # Riverpod (mode sombre + palette)
├── typography.dart       # Inter scale
└── spacing.dart          # Grille d'espacement
```

Le `MaterialApp` injecte `ConfidiaPaletteTheme` dans `ThemeData.extensions` à chaque changement de palette.

---

### Marques tierces

Logos des services connectés : `assets/brands/` + `BrandIcon` / `BrandLabel`.

Les couleurs des providers externes (Gmail, Google Calendar, etc.) restent fixes : seule la marque CONFIDIA suit la palette active.

---

## Tests

```bash
flutter test
flutter analyze
```
