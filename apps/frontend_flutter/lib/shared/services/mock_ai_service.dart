import '../data/mock_ecosystem.dart';
import '../models/ai_insight_model.dart';
import '../models/document_model.dart';
import '../models/email_model.dart';

/// Couche IA simulée pour la démo investisseurs.
class MockAiService {
  const MockAiService();

  AiInsightModel? insightForEmail(String emailId) => MockEcosystem.emailInsights[emailId];

  AiInsightModel? insightForDocument(int documentId) => MockEcosystem.documentInsights[documentId];

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
}
