import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/glass_card.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  XFile? _captured;
  Uint8List? _bytes;
  bool _isProcessing = false;
  String? _selectedCategory = 'Administratif';

  Future<void> _capture(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _captured = file;
        _bytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'accéder à la caméra : $e')),
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_captured == null) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isProcessing = false;
      _captured = null;
      _bytes = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document scanné et envoyé avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: ConfidiaColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: ConfidiaSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scanner un document', style: Theme.of(context).textTheme.titleLarge),
                              Text(
                                'Capturez factures, contrats et pièces d\'identité',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ConfidiaSpacing.lg),
                    if (_bytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
                        child: Image.memory(_bytes!, height: isWide ? 400 : 260, width: double.infinity, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        height: isWide ? 360 : 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
                          border: Border.all(color: ConfidiaColors.primary.withValues(alpha: 0.25), width: 2),
                          gradient: LinearGradient(
                            colors: [
                              ConfidiaColors.primary.withValues(alpha: 0.05),
                              ConfidiaColors.secondary.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 56, color: ConfidiaColors.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: ConfidiaSpacing.md),
                            Text('Cadrez votre document', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: ConfidiaSpacing.xs),
                            Text('Éclairage uniforme recommandé', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    const SizedBox(height: ConfidiaSpacing.lg),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(child: _CaptureButton(icon: Icons.photo_camera_rounded, label: 'Appareil photo', onTap: () => _capture(ImageSource.camera))),
                          const SizedBox(width: ConfidiaSpacing.md),
                          Expanded(child: _CaptureButton(icon: Icons.photo_library_rounded, label: 'Galerie', onTap: () => _capture(ImageSource.gallery), outlined: true)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _CaptureButton(icon: Icons.photo_camera_rounded, label: 'Prendre une photo', onTap: () => _capture(ImageSource.camera)),
                          const SizedBox(height: ConfidiaSpacing.sm),
                          _CaptureButton(icon: Icons.photo_library_rounded, label: 'Choisir depuis la galerie', onTap: () => _capture(ImageSource.gallery), outlined: true),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              if (_captured != null) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Options d\'import', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: ConfidiaSpacing.md),
                      Text('Fichier · ${_captured!.name}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: ConfidiaSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Catégorie'),
                        items: ['Administratif', 'Énergie', 'Assurance', 'Fiscal', 'Identité', 'Banque']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: ConfidiaSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() { _captured = null; _bytes = null; }),
                              child: const Text('Reprendre'),
                            ),
                          ),
                          const SizedBox(width: ConfidiaSpacing.md),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _upload,
                              icon: _isProcessing
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.cloud_upload_rounded, size: 18),
                              label: Text(_isProcessing ? 'Envoi...' : 'Envoyer le scan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: ConfidiaSpacing.md),
                  child: Text(
                    'Sur le web, la galerie est utilisée par défaut. La caméra nécessite HTTPS.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    if (outlined) {
      return OutlinedButton(onPressed: onTap, child: child);
    }
    return ElevatedButton(onPressed: onTap, child: child);
  }
}
