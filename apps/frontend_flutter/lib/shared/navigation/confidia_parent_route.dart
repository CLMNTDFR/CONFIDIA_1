/// Route parente pour les écrans secondaires (bouton retour).
String? confidiaParentRoute(String path) {
  if (path == '/access-control' || path == '/admin') return '/settings';
  // Couvre /documents/add et /documents/:id
  if (path.startsWith('/documents/') && path != '/documents') return '/documents';
  if (path.startsWith('/payments/') && path != '/payments') return '/payments';
  if (path.startsWith('/messaging/') && path != '/messaging') return '/messaging';
  if (path == '/profile' || path == '/notifications') return '/dashboard';
  return null;
}

bool confidiaShowsBackButton(String path) => confidiaParentRoute(path) != null;
