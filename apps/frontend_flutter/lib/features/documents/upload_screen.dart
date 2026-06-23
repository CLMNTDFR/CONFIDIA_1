import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/spacing.dart';
import '../../shared/widgets/confidia_dropdown_field.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import 'document_categories.dart';
import 'widgets/document_ingest_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<PlatformFile> _files = [];
  String? _selectedCategory;
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'xlsx'],
    );
    if (result != null) {
      setState(() => _files.addAll(result.files));
    }
  }

  Future<void> _upload() async {
    if (_files.isEmpty) return;
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isUploading = false;
      _files.clear();
      _selectedCategory = null;
    });
    if (mounted) {
      context.showConfidiaSnack('Documents uploadés avec succès', type: ConfidiaSnackType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final zoneHeight = isWide ? 300.0 : 240.0;

    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ConfidiaPageReveal(
            index: 0,
            staggerCount: 1,
            child: GlassCard(
              child: Column(
                children: [
                  const DocumentIngestHeader(
                    icon: Icons.upload_rounded,
                    title: 'Importer un document',
                    subtitle: 'Ajoutez PDF, images, Word ou Excel depuis votre appareil',
                  ),
                  const SizedBox(height: ConfidiaSpacing.lg),
                  DocumentIngestPreviewZone(
                    height: zoneHeight,
                    emptyIcon: Icons.cloud_upload_outlined,
                    emptyTitle: 'Glissez vos fichiers ici',
                    emptySubtitle: 'ou cliquez pour parcourir · max 50 Mo',
                    onTap: _pickFiles,
                    child: _files.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${_files.length} fichier(s) sélectionné(s)',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: ListView(
                                    children: _files
                                        .map(
                                          (f) => DocumentFileRow(
                                            name: f.name,
                                            sizeLabel: '${(f.size / 1024).toStringAsFixed(1)} Ko',
                                            onRemove: () => setState(() => _files.remove(f)),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                Center(
                                  child: ConfidiaGlowButton(
                                    label: 'Ajouter des fichiers',
                                    icon: Icons.add_rounded,
                                    primary: false,
                                    onPressed: _pickFiles,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: ConfidiaSpacing.lg),
                  ConfidiaDropdownField<String>(
                    value: _selectedCategory,
                    labelText: 'Catégorie',
                    hintText: 'Choisir une catégorie',
                    prefixIcon: Icons.folder_outlined,
                    items: DocumentCategories.values,
                    itemLabel: (c) => c,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: ConfidiaSpacing.lg),
                  Center(
                    child: ConfidiaGlowButton(
                      label: _isUploading ? 'Envoi…' : 'Importer',
                      icon: Icons.cloud_done_rounded,
                      onPressed: _files.isEmpty || _isUploading ? null : _upload,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
