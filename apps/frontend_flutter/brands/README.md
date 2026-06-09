# Logos des services connectés

Déposez les PNG ici (64×64 px recommandé, fond transparent).

Après ajout :
1. Ajoutez le fichier dans `pubspec.yaml` → section `assets:`
2. Ajoutez le chemin dans `lib/shared/brands/brand_assets.dart` → ensemble `bundled`
3. Relancez complètement : `flutter run -d chrome --web-port=8082`

## Fichiers actuels

- `gmail.png`, `proton.png`, `googlecalendar.png`
- `nextcloud.png`, `paperlessngx.png`
- `googledocs.png`, `googlepay.png`

Pour redimensionner un nouveau logo :

```bash
sips -z 64 64 votre_logo.png --out brands/votre_logo.png
```
