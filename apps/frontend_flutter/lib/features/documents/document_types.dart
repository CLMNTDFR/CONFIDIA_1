/// Types documentaires proposés à l'import et à l'édition.
/// « Autre » ouvre une saisie libre ; la valeur vide reste autorisée (champ optionnel).
abstract final class DocumentTypes {
  static const unspecifiedKey = '__none__';
  static const otherKey = '__other__';

  static const presets = [
    'Facture',
    'Contrat',
    'Quittance',
    'Relevé bancaire',
    'Avis',
    'Attestation',
    'Justificatif',
    'Pièce d\'identité',
    'Acte',
    'Bulletin de salaire',
  ];

  static String choiceFor(String? type) {
    final trimmed = type?.trim() ?? '';
    if (trimmed.isEmpty) return unspecifiedKey;
    if (presets.contains(trimmed)) return trimmed;
    return otherKey;
  }

  static String? resolve({required String choice, String custom = ''}) {
    if (choice == unspecifiedKey) return null;
    if (choice == otherKey) {
      final trimmed = custom.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return choice;
  }
}
