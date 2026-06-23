import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/widgets/confidia_dropdown_field.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import 'document_categories.dart';
import 'widgets/document_ingest_widgets.dart';

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
  String _selectedCategory = DocumentCategories.values.first;

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
        context.showConfidiaSnack('Impossible d\'accéder à la caméra : $e', type: ConfidiaSnackType.error);
      }
    }
  }

  void _reset() => setState(() {
        _captured = null;
        _bytes = null;
      });

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
      context.showConfidiaSnack('Document scanné et envoyé avec succès', type: ConfidiaSnackType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final previewHeight = isWide ? 360.0 : 260.0;

    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              ConfidiaPageReveal(
                index: 0,
                staggerCount: _captured != null ? 2 : 1,
                child: GlassCard(
                  child: Column(
                    children: [
                      const DocumentIngestHeader(
                        icon: Icons.document_scanner_rounded,
                        title: 'Scanner un document',
                        subtitle: 'Capturez factures, contrats et pièces d\'identité',
                      ),
                      const SizedBox(height: ConfidiaSpacing.lg),
                      DocumentIngestPreviewZone(
                        height: previewHeight,
                        emptyIcon: Icons.camera_alt_rounded,
                        emptyTitle: 'Cadrez votre document',
                        emptySubtitle: 'Éclairage uniforme recommandé',
                        child: _bytes != null
                            ? Image.memory(_bytes!, width: double.infinity, height: previewHeight, fit: BoxFit.cover)
                            : null,
                      ),
                      const SizedBox(height: ConfidiaSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ConfidiaGlowButton(
                            label: isWide ? 'Appareil photo' : 'Prendre une photo',
                            icon: Icons.photo_camera_rounded,
                            onPressed: () => _capture(ImageSource.camera),
                          ),
                          ConfidiaGlowButton(
                            label: isWide ? 'Galerie' : 'Depuis la galerie',
                            icon: Icons.photo_library_rounded,
                            primary: false,
                            onPressed: () => _capture(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_captured != null) ...[
                const SizedBox(height: ConfidiaSpacing.md),
                ConfidiaPageReveal(
                  index: 1,
                  staggerCount: 2,
                  child: GlassCard(
                    child: Column(
                      children: [
                        Text(
                          'Options d\'import',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _captured!.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.palette.primary,
                              ),
                        ),
                        const SizedBox(height: ConfidiaSpacing.md),
                        ConfidiaDropdownField<String>(
                          value: _selectedCategory,
                          labelText: 'Catégorie',
                          prefixIcon: Icons.folder_outlined,
                          items: DocumentCategories.values,
                          itemLabel: (c) => c,
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedCategory = v);
                          },
                        ),
                        const SizedBox(height: ConfidiaSpacing.lg),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ConfidiaGlowButton(
                              label: 'Reprendre',
                              icon: Icons.refresh_rounded,
                              primary: false,
                              onPressed: _reset,
                            ),
                            ConfidiaGlowButton(
                              label: _isProcessing ? 'Envoi…' : 'Envoyer le scan',
                              icon: Icons.cloud_upload_rounded,
                              onPressed: _isProcessing ? null : _upload,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (kIsWeb) ...[
                const SizedBox(height: ConfidiaSpacing.md),
                Text(
                  'Sur le web, la galerie est utilisée par défaut. La caméra nécessite HTTPS.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
