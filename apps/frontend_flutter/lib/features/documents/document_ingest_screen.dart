import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/confidia_dropdown_field.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import 'document_categories.dart';
import 'documents_provider.dart';
import 'widgets/document_ingest_widgets.dart';
import 'widgets/document_type_field.dart';

/// Single add screen: camera photo or device files.
/// [mode]: `camera` | `files` (default if null / unknown).
class DocumentIngestScreen extends ConsumerStatefulWidget {
  final String? mode;

  const DocumentIngestScreen({super.key, this.mode});

  @override
  ConsumerState<DocumentIngestScreen> createState() => _DocumentIngestScreenState();
}

class _DocumentIngestScreenState extends ConsumerState<DocumentIngestScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageName;
  final List<PlatformFile> _files = [];
  String _category = DocumentCategories.values.first;
  String? _documentType;
  bool _busy = false;
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _titles = [];

  bool get _isCamera => widget.mode == 'camera';
  bool get _hasContent => _imageBytes != null || _files.isNotEmpty;

  /// Native camera is reliable only on iOS / Android.
  bool get _canAutoLaunchCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  void initState() {
    super.initState();
    // Never auto FilePicker. Auto camera only on mobile.
    if (_isCamera && _canAutoLaunchCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _captureCamera();
      });
    }
  }

  @override
  void dispose() {
    _disposeTitles();
    super.dispose();
  }

  void _disposeTitles() {
    for (final controller in _titles) {
      controller.dispose();
    }
    _titles.clear();
  }

  void _setTitles(List<String> filenames) {
    _disposeTitles();
    for (final name in filenames) {
      _titles.add(TextEditingController(text: documentTitleFromFilename(name)));
    }
  }

  void _addTitles(Iterable<String> filenames) {
    for (final name in filenames) {
      _titles.add(TextEditingController(text: documentTitleFromFilename(name)));
    }
  }

  Future<void> _captureCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _files.clear();
        _setTitles([file.name]);
      });
    } catch (e) {
      if (!mounted) return;
      context.showConfidiaSnack(
        'Impossible d\'ouvrir la caméra. Sur ordinateur, utilisez Importer pour ajouter un fichier.',
        type: ConfidiaSnackType.error,
      );
    }
  }

  Future<void> _pickFiles({bool append = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'xlsx'],
    );
    if (result == null || !mounted) return;
    setState(() {
      _imageBytes = null;
      _imageName = null;
      if (!append) {
        _files.clear();
        _disposeTitles();
      }
      _files.addAll(result.files);
      _addTitles(result.files.map((file) => file.name));
    });
  }

  void _resetContent() {
    _imageBytes = null;
    _imageName = null;
    _files.clear();
    _disposeTitles();
  }

  void _clear() => setState(_resetContent);

  Future<void> _submit() async {
    if (!_hasContent || _busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final notifier = ref.read(documentsProvider.notifier);
      DocumentModel? last;
      if (_imageBytes != null) {
        last = await notifier.upload(
          filename: _imageName ?? 'scan.jpg',
          bytes: _imageBytes!,
          title: _titles.single.text.trim(),
          category: _category,
          documentType: _documentType,
        );
      } else {
        for (var i = 0; i < _files.length; i++) {
          final file = _files[i];
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) continue;
          last = await notifier.upload(
            filename: file.name,
            bytes: bytes,
            title: _titles[i].text.trim(),
            category: _category,
            documentType: _documentType,
          );
        }
      }
      if (!mounted) return;
      if (last == null) {
        final err = ref.read(documentsProvider).error;
        context.showConfidiaSnack(
          err ?? "Impossible d'envoyer le document",
          type: ConfidiaSnackType.error,
        );
        return;
      }
      setState(_resetContent);
      context.showConfidiaSnack('Document enregistré', type: ConfidiaSnackType.success);
      context.go('/documents/${last.id}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    final zoneHeight = isWide ? 320.0 : 240.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _isCamera ? 'Scanner un document' : 'Importer un document';
    final subtitle = _isCamera
        ? 'Capturez factures, contrats et pièces d\'identité'
        : 'PDF, images, Word ou Excel depuis votre appareil';
    final emptyTitle = _isCamera ? 'Cadrez votre document' : 'Glissez vos fichiers ici';
    final emptySubtitle = _isCamera
        ? 'Éclairage uniforme recommandé'
        : 'ou cliquez pour parcourir · PDF, images, Word, Excel';
    final submitLabel = _busy
        ? 'Envoi…'
        : (_isCamera ? 'Envoyer le scan' : 'Importer');

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
                  DocumentIngestHeader(
                    icon: _isCamera ? Icons.document_scanner_rounded : Icons.upload_rounded,
                    title: title,
                    subtitle: subtitle,
                  ),
                  const SizedBox(height: ConfidiaSpacing.lg),
                  DocumentIngestPreviewZone(
                    height: zoneHeight,
                    emptyIcon: _isCamera ? Icons.camera_alt_rounded : Icons.cloud_upload_outlined,
                    emptyTitle: emptyTitle,
                    emptySubtitle: emptySubtitle,
                    onTap: _hasContent
                        ? null
                        : (_isCamera ? _captureCamera : () => _pickFiles()),
                    child: _buildPreview(zoneHeight),
                  ),
                  if (_hasContent) ...[
                    const SizedBox(height: ConfidiaSpacing.lg),
                    if (_imageName != null) ...[
                      Text(
                        _imageName!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ConfidiaColors.textSecondary(isDark),
                            ),
                      ),
                      const SizedBox(height: ConfidiaSpacing.md),
                    ],
                    Form(
                      key: _formKey,
                      child: DocumentIngestTitleFields(
                        controllers: _titles,
                        filenames: _imageName != null ? [_imageName!] : _files.map((file) => file.name).toList(),
                        enabled: !_busy,
                      ),
                    ),
                    const SizedBox(height: ConfidiaSpacing.md),
                    ConfidiaDropdownField<String>(
                      value: _category,
                      labelText: 'Catégorie',
                      prefixIcon: Icons.folder_outlined,
                      items: DocumentCategories.values,
                      itemLabel: (c) => c,
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                    const SizedBox(height: ConfidiaSpacing.md),
                    DocumentTypeField(
                      onChanged: (value) => _documentType = value,
                    ),
                    const SizedBox(height: ConfidiaSpacing.lg),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ConfidiaGlowButton(
                          label: 'Reprendre',
                          icon: Icons.refresh_rounded,
                          primary: false,
                          onPressed: _busy
                              ? null
                              : () {
                                  _clear();
                                  if (_isCamera) {
                                    _captureCamera();
                                  } else {
                                    _pickFiles();
                                  }
                                },
                        ),
                        ConfidiaGlowButton(
                          label: submitLabel,
                          icon: Icons.cloud_done_rounded,
                          onPressed: _busy ? null : _submit,
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: ConfidiaSpacing.lg),
                    Center(
                      child: ConfidiaGlowButton(
                        label: _isCamera ? 'Ouvrir la caméra' : 'Choisir des fichiers',
                        icon: _isCamera ? Icons.photo_camera_rounded : Icons.folder_open_rounded,
                        onPressed: _isCamera ? _captureCamera : () => _pickFiles(),
                      ),
                    ),
                  ],
                  if (_isCamera && !_canAutoLaunchCamera) ...[
                    const SizedBox(height: ConfidiaSpacing.md),
                    Text(
                      kIsWeb
                          ? 'Sur le web, la caméra nécessite HTTPS.'
                          : 'Sur ordinateur, la caméra peut être indisponible. Préférez Importer pour un fichier.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ConfidiaColors.textSecondary(isDark),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildPreview(double height) {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
    }
    if (_files.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_files.length} fichier(s) sélectionné(s)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final f in _files)
                  DocumentFileRow(
                    name: f.name,
                    sizeLabel: '${(f.size / 1024).toStringAsFixed(1)} Ko',
                    onRemove: () => setState(() {
                      final index = _files.indexOf(f);
                      if (index < 0) return;
                      _files.removeAt(index);
                      if (index < _titles.length) {
                        _titles.removeAt(index).dispose();
                      }
                      if (_files.isEmpty) _resetContent();
                    }),
                  ),
              ],
            ),
          ),
          Center(
            child: ConfidiaGlowButton(
              label: 'Ajouter des fichiers',
              icon: Icons.add_rounded,
              primary: false,
              onPressed: _busy ? null : () => _pickFiles(append: true),
            ),
          ),
        ],
      ),
    );
  }
}
