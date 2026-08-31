/// Périmètre Holberton : tout l'UI reste visible, le hors-MVP est marqué « Démo ».
///
/// IN : auth, dashboard, calendrier fusionné (interne), documents, profil, paramètres de base.
/// OUT : messagerie, paiements, gouvernance, IA production, sync calendriers tiers.
abstract final class ConfidiaMvpScope {
  static const demoTooltip = 'Hors MVP Holberton · aperçu du produit final';

  static bool isDemoPath(String path) {
    return path.startsWith('/messaging') ||
        path.startsWith('/payments') ||
        path.startsWith('/access-control') ||
        path.startsWith('/admin');
  }
}
