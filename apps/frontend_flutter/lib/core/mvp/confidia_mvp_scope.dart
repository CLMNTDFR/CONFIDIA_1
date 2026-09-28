/// Holberton scope: the full UI stays visible; out-of-MVP features are marked « Démo ».
///
/// IN: auth, dashboard, merged calendar (internal), documents, profile, basic settings.
/// OUT: messaging, payments, governance, production AI, third-party calendar sync.
abstract final class ConfidiaMvpScope {
  static const demoTooltip = 'Hors MVP Holberton · aperçu du produit final';

  static bool isDemoPath(String path) {
    return path.startsWith('/messaging') ||
        path.startsWith('/payments') ||
        path.startsWith('/access-control') ||
        path.startsWith('/admin');
  }
}
