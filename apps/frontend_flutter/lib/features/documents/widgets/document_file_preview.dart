import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens/tokens.dart';
import '../../../shared/models/document_model.dart';
import '../../../shared/widgets/confidia_button.dart';

/// Visual file preview (image or PDF) in the detail panel.
class DocumentFilePreview extends StatelessWidget {
  final DocumentModel doc;
  final Uint8List? bytes;
  final bool loading;
  final VoidCallback onDownload;

  const DocumentFilePreview({
    super.key,
    required this.doc,
    required this.bytes,
    required this.loading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Aperçu', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        if (loading)
          _PreviewFrame(
            isDark: isDark,
            child: const SizedBox(height: 480, child: Center(child: CircularProgressIndicator())),
          )
        else if (bytes != null && doc.isPdfPreviewable)
          _PdfPagedPreview(
            key: ValueKey('pdf-${doc.id}'),
            bytes: bytes!,
            sourceName: 'confidia-doc-${doc.id}',
            title: doc.title,
            isDark: isDark,
            onDownload: onDownload,
          )
        else if (bytes != null && doc.isImagePreviewable)
          _PreviewFrame(
            isDark: isDark,
            child: SizedBox(
              height: 480,
              width: double.infinity,
              child: InteractiveViewer(child: Image.memory(bytes!, fit: BoxFit.contain)),
            ),
          )
        else
          _PreviewFrame(
            isDark: isDark,
            child: _Unavailable(
              context: context,
              isDark: isDark,
              title: bytes == null ? 'Aperçu indisponible' : doc.title,
              message: bytes == null
                  ? 'Le fichier n\'a pas pu être chargé. Réessayez le téléchargement.'
                  : 'Aperçu visuel limité pour ce type de fichier.',
              onDownload: onDownload,
            ),
          ),
      ],
    );
  }
}

/// Rounded sheet that holds the preview. The page itself does not scroll.
class _PreviewFrame extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _PreviewFrame({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? ConfidiaColors.darkSurfaceVariant : Colors.white,
        borderRadius: AppRadius.mdAll,
        border: Border.fromBorderSide(AppBorders.standard(isDark)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: child,
      ),
    );
  }
}

class _PdfPagedPreview extends StatefulWidget {
  final Uint8List bytes;
  final String sourceName;
  final String title;
  final bool isDark;
  final VoidCallback onDownload;

  const _PdfPagedPreview({
    super.key,
    required this.bytes,
    required this.sourceName,
    required this.title,
    required this.isDark,
    required this.onDownload,
  });

  @override
  State<_PdfPagedPreview> createState() => _PdfPagedPreviewState();
}

class _PdfPagedPreviewState extends State<_PdfPagedPreview> {
  PdfDocument? _doc;
  Object? _openError;
  bool _opening = true;
  int _page = 1;
  int _direction = 1;
  int _loadGen = 0;
  int _renderGen = 0;
  double? _cssWidth;
  double _dpr = 1;
  bool _layoutQueued = false;
  final Map<int, ui.Image> _images = {};
  final Map<int, Future<void>> _inflight = {};

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant _PdfPagedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) || oldWidget.sourceName != widget.sourceName) {
      _open();
    }
  }

  @override
  void dispose() {
    _loadGen++;
    _disposeImages();
    _doc?.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final gen = ++_loadGen;
    final previous = _doc;
    _doc = null;
    _disposeImages();
    if (mounted) {
      setState(() {
        _opening = true;
        _openError = null;
        _page = 1;
      });
    }
    await previous?.dispose();
    try {
      final doc = await PdfDocument.openData(widget.bytes, sourceName: widget.sourceName);
      if (!mounted || gen != _loadGen) {
        await doc.dispose();
        return;
      }
      setState(() {
        _doc = doc;
        _opening = false;
      });
    } catch (error) {
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _opening = false;
        _openError = error;
      });
    }
  }

  void _disposeImages() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _inflight.clear();
  }

  void _requestLayout(double width) {
    if (width <= 0 || !width.isFinite) return;
    final known = _cssWidth;
    final widthChanged = known == null || (width - known).abs() >= 24;
    if (!widthChanged && _images.containsKey(_page)) return;
    if (_layoutQueued) return;
    _layoutQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutQueued = false;
      if (!mounted) return;
      _applyWidth(width);
    });
  }

  void _applyWidth(double width) {
    final doc = _doc;
    if (doc == null) return;
    final changed = _cssWidth == null || (width - _cssWidth!).abs() >= 24;
    _cssWidth = width;
    _dpr = MediaQuery.devicePixelRatioOf(context);
    if (changed) {
      _renderGen++;
      _disposeImages();
    }
    _renderPage(doc, _page, prefetch: true);
  }

  Future<void> _renderPage(PdfDocument doc, int pageNumber, {required bool prefetch}) {
    if (pageNumber < 1 || pageNumber > doc.pages.length) return Future.value();
    if (_images.containsKey(pageNumber)) {
      if (prefetch) _prefetchAround(doc, pageNumber);
      return Future.value();
    }
    final pending = _inflight[pageNumber];
    if (pending != null) return pending;

    final cssWidth = _cssWidth ?? 360;
    final dpr = _dpr;
    final gen = _renderGen;
    final future = () async {
      final page = doc.pages[pageNumber - 1];
      if (page.width <= 0 || page.height <= 0) return;
      final pixelWidth = math.min(cssWidth * dpr, 1400.0);
      final pixelHeight = pixelWidth * page.height / page.width;
      final rendered = await page.render(
        fullWidth: pixelWidth,
        fullHeight: pixelHeight,
        backgroundColor: Colors.white,
      );
      if (rendered == null) return;
      final image = await rendered.createImage();
      rendered.dispose();
      if (!mounted || _doc != doc || gen != _renderGen) {
        image.dispose();
        return;
      }
      _images[pageNumber]?.dispose();
      _images[pageNumber] = image;
      if (pageNumber == _page) setState(() {});
      if (prefetch) _prefetchAround(doc, pageNumber);
    }();

    _inflight[pageNumber] = future;
    return future.whenComplete(() {
      if (identical(_inflight[pageNumber], future)) _inflight.remove(pageNumber);
    });
  }

  void _prefetchAround(PdfDocument doc, int pageNumber) {
    _renderPage(doc, pageNumber - 1, prefetch: false);
    _renderPage(doc, pageNumber + 1, prefetch: false);
  }

  Future<void> _go(int delta) async {
    final doc = _doc;
    if (doc == null) return;
    final target = _page + delta;
    if (target < 1 || target > doc.pages.length) return;
    await _renderPage(doc, target, prefetch: false);
    if (!mounted || _doc != doc || !_images.containsKey(target)) return;
    setState(() {
      _direction = delta;
      _page = target;
    });
    _prefetchAround(doc, target);
  }

  @override
  Widget build(BuildContext context) {
    if (_opening) {
      return _PreviewFrame(
        isDark: widget.isDark,
        child: const AspectRatio(aspectRatio: 1 / 1.414, child: Center(child: CircularProgressIndicator())),
      );
    }
    final doc = _doc;
    if (doc == null || doc.pages.isEmpty || _openError != null) {
      return _PreviewFrame(
        isDark: widget.isDark,
        child: SizedBox(
          height: 280,
          child: _Unavailable(
            context: context,
            isDark: widget.isDark,
            title: widget.title,
            message: 'Impossible d\'afficher ce PDF. Vous pouvez le télécharger.',
            onDownload: widget.onDownload,
          ),
        ),
      );
    }

    final page = doc.pages[_page - 1];
    final aspect = page.width > 0 && page.height > 0 ? page.width / page.height : 1 / 1.414;
    final count = doc.pages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (count > 1) ...[
          PdfPreviewPager(
            page: _page,
            pageCount: count,
            onPrevious: _page > 1 ? () => _go(-1) : null,
            onNext: _page < count ? () => _go(1) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _PreviewFrame(
          isDark: widget.isDark,
          child: AspectRatio(
            aspectRatio: aspect,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _requestLayout(constraints.maxWidth);
                return _pageStage();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageStage() {
    final image = _images[_page];
    if (image == null) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) => pdfPreviewPageTransition(
          child: child,
          animation: animation,
          activePage: _page,
          direction: _direction,
        ),
        child: SizedBox.expand(
          key: ValueKey<int>(_page),
          child: RawImage(image: image, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

/// Horizontal slide: next page enters from the right, previous page from the left.
Widget pdfPreviewPageTransition({
  required Widget child,
  required Animation<double> animation,
  required int activePage,
  required int direction,
}) {
  final incoming = child.key == ValueKey<int>(activePage);
  final sign = (incoming ? direction : -direction).toDouble();
  return SlideTransition(
    position: Tween<Offset>(begin: Offset(sign, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    ),
    child: child,
  );
}

/// Page arrows and "Page 2/5" label. Hidden for a single page.
class PdfPreviewPager extends StatelessWidget {
  final int page;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PdfPreviewPager({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _arrow(
          icon: Icons.chevron_left_rounded,
          enabled: onPrevious != null,
          tooltip: 'Page précédente',
          onPressed: onPrevious,
        ),
        const SizedBox(width: AppSpacing.s),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface2(isDark),
            borderRadius: AppRadius.pillAll,
            border: Border.fromBorderSide(AppBorders.standard(isDark)),
          ),
          child: Text(
            'Page $page/$pageCount',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        _arrow(
          icon: Icons.chevron_right_rounded,
          enabled: onNext != null,
          tooltip: 'Page suivante',
          onPressed: onNext,
        ),
      ],
    );
  }

  Widget _arrow({
    required IconData icon,
    required bool enabled,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? AppOpacity.opaque : AppOpacity.strong,
      duration: AppDurations.quick,
      child: ConfidiaIconButton(
        icon: icon,
        compact: true,
        tooltip: enabled ? tooltip : null,
        onPressed: onPressed,
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final BuildContext context;
  final bool isDark;
  final String title;
  final String message;
  final VoidCallback onDownload;

  const _Unavailable({
    required this.context,
    required this.isDark,
    required this.title,
    required this.message,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext _) {
    final muted = ConfidiaColors.textSecondary(isDark);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 52, color: muted.withValues(alpha: 0.55)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }
}
