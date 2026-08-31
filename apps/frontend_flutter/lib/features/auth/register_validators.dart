/// Règles d'inscription alignées sur l'API FastAPI, avec messages précis.
abstract final class RegisterValidators {
  static final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final uppercase = RegExp(r'[A-Z]');
  static final digit = RegExp(r'\d');
  static final special = RegExp(r'[^A-Za-z0-9]');
  static final usernameAllowed = RegExp(r'^[\p{L}\p{N}._-]+$', unicode: true);
  static final usernameChar = RegExp(r'[\p{L}\p{N}._-]', unicode: true);

  static const minPasswordLength = 12;
  static const minUsernameLength = 3;
  static const maxUsernameLength = 32;
  static const maxNameLength = 80;

  static String? email(String? value) {
    final raw = value ?? '';
    final v = raw.trim();
    if (raw.isEmpty) return 'L\'adresse e-mail est requise';
    if (v.isEmpty) return 'L\'adresse e-mail ne peut pas contenir uniquement des espaces';
    if (RegExp(r'\s').hasMatch(v)) {
      return 'Les espaces ne sont pas autorisés dans l\'adresse e-mail';
    }
    if (!v.contains('@')) {
      return 'Il manque le caractère @. Exemple : prenom@domaine.fr';
    }
    if ('@'.allMatches(v).length > 1) {
      return 'Une adresse e-mail ne peut contenir qu\'un seul @';
    }
    final at = v.indexOf('@');
    final local = v.substring(0, at);
    final domain = v.substring(at + 1);
    if (local.isEmpty) {
      return 'Indiquez la partie avant @ (exemple : prenom@domaine.fr)';
    }
    if (domain.isEmpty) {
      return 'Indiquez le domaine après @ (exemple : prenom@domaine.fr)';
    }
    if (!domain.contains('.')) {
      return 'Le domaine doit contenir un point (exemple : domaine.fr)';
    }
    if (domain.startsWith('.') || domain.endsWith('.')) {
      return 'Le domaine de l\'adresse e-mail est incomplet';
    }
    if (!emailPattern.hasMatch(v)) {
      return 'Cette adresse e-mail n\'est pas reconnue. Vérifiez le format (prenom@domaine.fr).';
    }
    return null;
  }

  static String? emailConfirm(String? value, String originalEmail) {
    final raw = value ?? '';
    if (raw.isEmpty) return 'La confirmation de l\'e-mail est requise';
    final v = raw.trim();
    if (v.isEmpty) return 'La confirmation de l\'e-mail ne peut pas contenir uniquement des espaces';
    if (v.toLowerCase() != originalEmail.trim().toLowerCase()) {
      return 'Les adresses e-mail ne correspondent pas';
    }
    return email(v);
  }

  static String? username(String? value) {
    final raw = value ?? '';
    final v = raw.trim();
    if (raw.isEmpty) return 'Le nom d\'utilisateur est requis';
    if (v.isEmpty) return 'Le nom d\'utilisateur ne peut pas contenir uniquement des espaces';
    if (raw != v) return 'Retirez les espaces avant ou après le nom d\'utilisateur';
    if (RegExp(r'\s').hasMatch(v)) {
      return 'Les espaces ne sont pas autorisés dans le nom d\'utilisateur';
    }
    if (v.contains('@')) {
      return 'Le caractère « @ » n\'est pas autorisé ici. Saisissez un identifiant, pas une adresse e-mail.';
    }
    if (v.length < minUsernameLength) {
      final unit = v.length == 1 ? 'caractère' : 'caractères';
      return 'Trop court : ${v.length} $unit (minimum $minUsernameLength).';
    }
    if (v.length > maxUsernameLength) {
      return 'Trop long : ${v.length} caractères (maximum $maxUsernameLength).';
    }
    if (!usernameAllowed.hasMatch(v)) {
      String? illegal;
      for (final rune in v.runes) {
        final ch = String.fromCharCode(rune);
        if (!usernameChar.hasMatch(ch)) {
          illegal = ch;
          break;
        }
      }
      if (illegal != null && illegal.isNotEmpty) {
        return 'Le caractère « $illegal » n\'est pas autorisé. '
            'Lettres (accents compris), chiffres, point, tiret et underscore uniquement.';
      }
      return 'Lettres (accents compris), chiffres, point, tiret et underscore uniquement.';
    }
    return null;
  }

  static String? requiredName(String? value, {String label = 'Ce champ'}) {
    final raw = value ?? '';
    final v = raw.trim();
    if (raw.isEmpty) return '$label est requis';
    if (v.isEmpty) return '$label ne peut pas contenir uniquement des espaces';
    if (v.length > maxNameLength) return '$label : $maxNameLength caractères maximum';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Le mot de passe est requis';
    if (v.length < minPasswordLength) {
      final unit = v.length == 1 ? 'caractère' : 'caractères';
      return 'Le mot de passe est trop court (${v.length} $unit). Minimum : $minPasswordLength.';
    }
    if (!uppercase.hasMatch(v)) return 'Il manque au moins une lettre majuscule (A-Z).';
    if (!digit.hasMatch(v)) return 'Il manque au moins un chiffre (0-9).';
    if (!special.hasMatch(v)) {
      return 'Il manque au moins un caractère spécial (par exemple ! ? # @).';
    }
    return null;
  }

  static String? passwordConfirm(String? value, String password) {
    final v = value ?? '';
    if (v.isEmpty) return 'La confirmation du mot de passe est requise';
    if (v != password) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static bool passwordHasLength(String value) => value.length >= minPasswordLength;
  static bool passwordHasUpper(String value) => uppercase.hasMatch(value);
  static bool passwordHasDigit(String value) => digit.hasMatch(value);
  static bool passwordHasSpecial(String value) => special.hasMatch(value);
}
