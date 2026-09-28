import '../data/mock_ecosystem.dart';
import '../models/ai_insight_model.dart';
import '../models/document_model.dart';
import '../models/email_model.dart';

/// Simulated AI layer for the investor demo.
class MockAiService {
  const MockAiService();

  AiInsightModel? insightForEmail(String emailId) => MockEcosystem.emailInsights[emailId];

  AiInsightModel? insightForDocument(String documentId) {
    final n = int.tryParse(documentId);
    if (n == null) return null;
    return MockEcosystem.documentInsights[n];
  }

  AiInsightModel analyzeEmail(EmailModel email) {
    return insightForEmail(email.id) ??
        AiInsightModel(
          summary: 'Email de ${email.sender} : ${email.preview}',
          recommendedActions: const ['Archiver', 'Marquer comme traité'],
          priority: AiPriority.low,
          tags: const ['non classé'],
        );
  }

  AiInsightModel analyzeDocument(DocumentModel doc) {
    return insightForDocument(doc.id) ??
        AiInsightModel(
          summary: '${doc.documentType ?? 'Document'} · ${doc.correspondent ?? doc.title}',
          recommendedActions: const ['Analyser avec l\'IA', 'Archiver'],
          priority: AiPriority.medium,
          tags: doc.tags,
        );
  }

  String generatePaymentConfirmation(String creditor, double amount) =>
      'Paiement de ${amount.toStringAsFixed(2)} € à $creditor traité avec succès. Reçu archivé dans votre coffre-fort numérique.';

  /// Narration for the "Commencer ma journée" ritual (streaming UI).
  String composeDayNarrative({
    required String firstName,
    required int currentScore,
    required int projectedScore,
    required int priorityCount,
    required int urgentPaymentCount,
    required int appointmentCount,
    required int newDocCount,
  }) {
    final empty = priorityCount == 0 &&
        urgentPaymentCount == 0 &&
        appointmentCount == 0 &&
        newDocCount == 0;
    final who = firstName.trim().isEmpty ? 'Voici' : '$firstName, voici';
    if (empty) {
      return '$who votre espace encore vide. Importez un document ou ajoutez un rendez-vous, '
          'et je préparerai votre journée.';
    }
    final parts = <String>[
      '$who votre journée en quelques secondes.',
      'Votre indice de sérénité est à $currentScore/100.',
    ];
    if (priorityCount > 0) {
      parts.add('Je retiens $priorityCount priorité(s) pour rester serein.');
    }
    if (urgentPaymentCount > 0) {
      parts.add('$urgentPaymentCount paiement(s) mérite(nt) une attention rapide.');
    }
    if (appointmentCount > 0) {
      parts.add('Vous avez $appointmentCount rendez-vous aujourd\'hui.');
    }
    if (newDocCount > 0) {
      parts.add('$newDocCount nouveau(x) document(s) sont arrivés récemment.');
    }
    if (projectedScore > currentScore) {
      parts.add(
        'Si vous traitez l\'essentiel, votre indice peut monter à $projectedScore/100.',
      );
    } else {
      parts.add('La journée est déjà bien engagée. Continuez sur cette lancée.');
    }
    return parts.join(' ');
  }
}
