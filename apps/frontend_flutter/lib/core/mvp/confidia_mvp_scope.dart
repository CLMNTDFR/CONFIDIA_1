/// Holberton scope: the full UI stays visible; out-of-MVP features are marked « Démo ».
///
/// IN: auth, dashboard, calendar, documents, profile, settings, governance.
/// OUT: messaging, payments, production AI, third-party calendar sync.
abstract final class ConfidiaMvpScope {
  static const demoTooltip = 'Hors MVP Holberton · aperçu du produit final';

  static bool isDemoPath(String path) {
    return path.startsWith('/messaging') ||
        path.startsWith('/payments') ||
        path.startsWith('/admin');
  }
}
