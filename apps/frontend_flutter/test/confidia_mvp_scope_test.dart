import 'package:confidia/core/mvp/confidia_mvp_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo tooltip is stable copy for the Holberton badge', () {
    expect(
      ConfidiaMvpScope.demoTooltip,
      'Hors MVP Holberton · aperçu du produit final',
    );
  });

  test('in-MVP routes are not marked demo', () {
    for (final path in [
      '/',
      '/dashboard',
      '/calendar',
      '/documents',
      '/documents/42',
      '/profile',
      '/settings',
      '/notifications',
      '/access-control',
    ]) {
      expect(ConfidiaMvpScope.isDemoPath(path), isFalse, reason: path);
    }
  });

  test('out-of-MVP routes are marked demo', () {
    for (final path in [
      '/messaging',
      '/messaging/inbox',
      '/payments',
      '/payments/42',
      '/admin',
      '/admin/health',
    ]) {
      expect(ConfidiaMvpScope.isDemoPath(path), isTrue, reason: path);
    }
  });
}
