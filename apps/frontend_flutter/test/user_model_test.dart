import 'package:confidia/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserModel(
    id: '1',
    email: 'a@b.c',
    firstName: 'Ada',
    lastName: 'Lovelace',
    roles: ['ADMIN', 'MANAGER'],
    phone: '+33 6 00 00 00 00',
    organization: 'Analytical Engine',
    locale: 'fr_FR',
    timezone: 'Europe/Paris',
  );

  test('fullName and initials', () {
    expect(user.fullName, 'Ada Lovelace');
    expect(user.initials, 'AL');
  });

  test('role helpers and roleLabel', () {
    expect(user.isAdmin, isTrue);
    expect(user.isManager, isTrue);
    expect(user.roleLabel, 'Administrateur');
    expect(
      const UserModel(id: '2', email: 'x', firstName: 'X', lastName: 'Y').isAdmin,
      isFalse,
    );
    expect(
      const UserModel(id: '3', email: 'x', firstName: 'X', lastName: 'Y', roles: ['MANAGER']).roleLabel,
      'Manager',
    );
    expect(
      const UserModel(id: '4', email: 'x', firstName: 'X', lastName: 'Y').roleLabel,
      'Membre',
    );
  });

  test('localeLabel and timezoneLabel', () {
    expect(user.localeLabel, 'Français');
    expect(user.timezoneLabel, 'Europe/Paris');
    expect(
      user.copyWith(locale: 'en_US', timezone: 'America/New_York').localeLabel,
      'English (US)',
    );
    expect(
      user.copyWith(timezone: 'America/New_York').timezoneLabel,
      'America/New York',
    );
  });

  test('empty name initials stay empty', () {
    const empty = UserModel(id: '3', email: 'e', firstName: '', lastName: '');
    expect(empty.initials, '');
  });

  test('copyWith updates and clears optional fields', () {
    final updated = user.copyWith(
      firstName: 'Augusta',
      phone: '+1 555',
      organization: 'Babbage Lab',
      locale: 'en_US',
      timezone: 'Europe/Brussels',
    );
    expect(updated.firstName, 'Augusta');
    expect(updated.lastName, 'Lovelace');
    expect(updated.phone, '+1 555');
    expect(updated.organization, 'Babbage Lab');
    expect(updated.locale, 'en_US');
    expect(updated.timezone, 'Europe/Brussels');

    final cleared = user.copyWith(clearPhone: true, clearOrganization: true, clearAvatarUrl: true);
    expect(cleared.phone, isNull);
    expect(cleared.organization, isNull);
    expect(cleared.avatarUrl, isNull);
    expect(cleared.email, user.email);
  });

  test('fromJson and toJson round-trip profile fields', () {
    final json = {
      'id': 'u1',
      'email': 'jean@confidia.local',
      'first_name': 'Jean',
      'last_name': 'Dupont',
      'roles': ['USER'],
      'phone': '+33 6 12 34 56 78',
      'organization': 'Particulier',
      'locale': 'fr_FR',
      'timezone': 'Europe/Paris',
      'avatar_url': 'https://example.com/a.png',
    };
    final parsed = UserModel.fromJson(json);
    expect(parsed.id, 'u1');
    expect(parsed.firstName, 'Jean');
    expect(parsed.lastName, 'Dupont');
    expect(parsed.phone, '+33 6 12 34 56 78');
    expect(parsed.organization, 'Particulier');
    expect(parsed.locale, 'fr_FR');
    expect(parsed.timezone, 'Europe/Paris');
    expect(parsed.avatarUrl, 'https://example.com/a.png');
    expect(parsed.roleLabel, 'Membre');

    final out = parsed.toJson();
    expect(out['first_name'], 'Jean');
    expect(out['phone'], '+33 6 12 34 56 78');
    expect(out['organization'], 'Particulier');
    expect(out['locale'], 'fr_FR');
    expect(out['timezone'], 'Europe/Paris');
  });

  test('fromJson defaults locale and timezone', () {
    final parsed = UserModel.fromJson({
      'id': 'x',
      'email': 'x@y.z',
      'first_name': 'A',
      'last_name': 'B',
    });
    expect(parsed.locale, 'fr_FR');
    expect(parsed.timezone, 'Europe/Paris');
  });

  test('ProfileMembership fromJson', () {
    final m = ProfileMembership.fromJson({
      'structure_id': 'family',
      'label': 'Famille',
      'role_label': 'Administrateur',
      'icon': 'family_restroom',
    });
    expect(m.structureId, 'family');
    expect(m.label, 'Famille');
    expect(m.roleLabel, 'Administrateur');
    expect(m.iconName, 'family_restroom');
  });
}
