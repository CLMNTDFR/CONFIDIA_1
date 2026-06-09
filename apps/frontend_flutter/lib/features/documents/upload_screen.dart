import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/mobile_shell_insets.dart';

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
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents uploadés avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ConfidiaPageReveal(
            index: 0,
            staggerCount: 1,
            child: GlassCard(
            child: Column(
              children: [
                  InkWell(
                      onTap: _pickFiles,
                      borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
                      child: Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ConfidiaColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: ConfidiaColors.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: ConfidiaSpacing.md),
                            Text(
                              'Glissez vos fichiers ici',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: ConfidiaSpacing.sm),
                            Text(
                              'ou cliquez pour parcourir',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: ConfidiaSpacing.sm),
                            Text(
                              'PDF, images, Word, Excel · max 50 Mo',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_files.isNotEmpty) ...[
                    const SizedBox(height: ConfidiaSpacing.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${_files.length} fichier(s) sélectionné(s)',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: ConfidiaSpacing.sm),
                    ..._files.map((f) => ListTile(
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(f.name),
                          subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _files.remove(f)),
                          ),
                        )),
                  ],
                  const SizedBox(height: ConfidiaSpacing.lg),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    value: _selectedCategory,
                    items: ['Énergie', 'Assurance', 'Fiscal', 'Emploi', 'Identité', 'Banque']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: ConfidiaSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _files.isEmpty || _isUploading ? null : _upload,
                      child: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Uploader'),
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
