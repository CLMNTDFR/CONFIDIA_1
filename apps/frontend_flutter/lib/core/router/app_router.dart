import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../animations/page_transitions.dart';
import '../auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/welcome_splash_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/documents/documents_screen.dart';
import '../../features/documents/documents_trash_screen.dart';
import '../../features/documents/document_detail_screen.dart';
import '../../features/documents/document_ingest_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/payments/payment_detail_screen.dart';
import '../../features/messaging/messaging_screen.dart';
import '../../features/messaging/email_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/access_control/access_control_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../shared/widgets/app_shell.dart';

/// Notifies GoRouter without recreating the instance (avoids cutting the welcome animation).
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
      final isPublicRoute = loc == '/login' || loc == '/welcome' || loc == '/register';

      if (!isLoggedIn && !isPublicRoute) return '/login';
      // After login: go through the animated welcome screen, not the dashboard directly.
      if (isLoggedIn && (loc == '/login' || loc == '/register')) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => fadeSlidePage(child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => fadeSlidePage(child: const RegisterScreen()),
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
            pageBuilder: (context, state) => fadeSlidePage(
              child: DocumentsScreen(
                initialCategory: state.uri.queryParameters['category'],
              ),
            ),
            routes: [
              GoRoute(
                path: 'trash',
                pageBuilder: (context, state) => fadeSlidePage(child: const DocumentsTrashScreen()),
              ),
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => fadeSlidePage(
                  child: DocumentIngestScreen(mode: state.uri.queryParameters['mode']),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => fadeSlidePage(
                  child: DocumentDetailScreen(documentId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/upload',
            redirect: (_, __) => '/documents/add?mode=files',
          ),
          GoRoute(
            path: '/scan',
            redirect: (_, __) => '/documents/add?mode=camera',
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
            path: '/access-control',
            pageBuilder: (context, state) => fadeSlidePage(child: const AccessControlScreen()),
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
