import 'package:confidia/features/auth/register_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email confirmation must match', () {
    expect(RegisterValidators.email('ada@confidia.local'), isNull);
    expect(RegisterValidators.emailConfirm('ada@confidia.local', 'ada@confidia.local'), isNull);
    expect(
      RegisterValidators.emailConfirm('other@confidia.local', 'ada@confidia.local'),
      'Les adresses e-mail ne correspondent pas',
    );
  });

  test('email errors name the actual problem', () {
    expect(RegisterValidators.email(''), 'L\'adresse e-mail est requise');
    expect(RegisterValidators.email('ada.confidia.local'), contains('@'));
    expect(RegisterValidators.email('ada@confidia'), contains('point'));
    expect(RegisterValidators.email('ada@@confidia.local'), contains('un seul @'));
  });

  test('username allows accents and names the illegal character', () {
    expect(RegisterValidators.username(''), 'Le nom d\'utilisateur est requis');
    expect(RegisterValidators.username('ab'), contains('Trop court'));
    expect(RegisterValidators.username('ok_user.1'), isNull);
    expect(RegisterValidators.username('clément'), isNull);
    expect(RegisterValidators.username('Jean-Élie'), isNull);
    expect(RegisterValidators.username('jean pierre'), contains('espaces'));
    expect(RegisterValidators.username('user@mail'), contains('« @ »'));
    expect(RegisterValidators.username('user!name'), contains('« ! »'));
  });

  test('password policy matches the API with specific messages', () {
    expect(RegisterValidators.password(''), 'Le mot de passe est requis');
    expect(RegisterValidators.password('short'), contains('trop court'));
    expect(RegisterValidators.password('nouppercase1!'), contains('majuscule'));
    expect(RegisterValidators.password('NoDigitHere!!'), contains('chiffre'));
    expect(RegisterValidators.password('NoSpecialChar1'), contains('spécial'));
    expect(RegisterValidators.password('ValidPassw0rd!'), isNull);
    expect(RegisterValidators.passwordConfirm('', 'ValidPassw0rd!'), contains('confirmation'));
    expect(
      RegisterValidators.passwordConfirm('ValidPassw0rd!', 'ValidPassw0rd!'),
      isNull,
    );
    expect(
      RegisterValidators.passwordConfirm('other', 'ValidPassw0rd!'),
      'Les mots de passe ne correspondent pas',
    );
  });
}
