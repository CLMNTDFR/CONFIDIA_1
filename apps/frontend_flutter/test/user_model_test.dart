import 'package:confidia/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserModel(
    id: '1',
    email: 'a@b.c',
    firstName: 'Ada',
    lastName: 'Lovelace',
    roles: ['ADMIN', 'MANAGER'],
  );

  test('fullName and initials', () {
    expect(user.fullName, 'Ada Lovelace');
    expect(user.initials, 'AL');
  });

  test('role helpers', () {
    expect(user.isAdmin, isTrue);
    expect(user.isManager, isTrue);
    expect(
      const UserModel(id: '2', email: 'x', firstName: 'X', lastName: 'Y').isAdmin,
      isFalse,
    );
  });

  test('empty name initials stay empty', () {
    const empty = UserModel(id: '3', email: 'e', firstName: '', lastName: '');
    expect(empty.initials, '');
  });
}
