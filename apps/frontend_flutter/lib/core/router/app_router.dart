import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../animations/page_transitions.dart';
import '../auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/welcome_splash_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/documents/documents_screen.dart';
import '../../features/documents/document_detail_screen.dart';
import '../../features/documents/upload_screen.dart';
import '../../features/documents/scan_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/payments/payment_detail_screen.dart';
import '../../features/messaging/messaging_screen.dart';
import '../../features/messaging/email_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../shared/widgets/app_shell.dart';

/// Notifie GoRouter sans recréer l'instance (évite de couper l'animation d'accueil).
class _RouterRefresh extends ChangeNotifier {
  void notifyRouter() => notifyListeners();
}

final _routerRefresh = _RouterRefresh();

final routerProvider = Provider<GoRouter>((ref) {
  ref.listen<AuthState>(authStateProvider, (_, __) => _routerRefresh.notifyRouter());

  final router = GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _routerRefresh,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
      final loc = state.matchedLocation;
      final isPublicRoute = loc == '/login' || loc == '/welcome';

      if (!isLoggedIn && !isPublicRoute) return '/login';
      // Après connexion : passer par l'écran d'accueil animé, pas le dashboard directement.
      if (isLoggedIn && loc == '/login') return '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => fadeSlidePage(child: const LoginScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => fadeSlidePage(child: const WelcomeSplashScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => fadeSlidePage(child: const DashboardScreen()),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (context, state) => fadeSlidePage(child: const DocumentsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => fadeSlidePage(
                  child: DocumentDetailScreen(documentId: int.parse(state.pathParameters['id']!)),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/upload',
            pageBuilder: (context, state) => fadeSlidePage(child: const UploadScreen()),
          ),
          GoRoute(
            path: '/scan',
            pageBuilder: (context, state) => fadeSlidePage(child: const ScanScreen()),
          ),
          GoRoute(
            path: '/payments',
            pageBuilder: (context, state) => fadeSlidePage(child: const PaymentsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => fadeSlidePage(
                  child: PaymentDetailScreen(paymentId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/messaging',
            pageBuilder: (context, state) => fadeSlidePage(child: const MessagingScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => fadeSlidePage(
                  child: EmailDetailScreen(emailId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => fadeSlidePage(child: const CalendarScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => fadeSlidePage(child: const NotificationsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => fadeSlidePage(child: const ProfileScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => fadeSlidePage(child: const SettingsScreen()),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => fadeSlidePage(child: const AdminScreen()),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
