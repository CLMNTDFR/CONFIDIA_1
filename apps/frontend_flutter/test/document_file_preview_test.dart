import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:confidia/core/theme/tokens/app_opacity.dart';
import 'package:confidia/features/documents/widgets/document_file_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pdf pager stays hidden for a single page', (tester) async {
    await tester.pumpWidget(_pager(page: 1, pageCount: 1));

    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.textContaining('Page '), findsNothing);
  });

  testWidgets('pdf pager shows the page label and dims the unavailable arrow', (tester) async {
    await tester.pumpWidget(_pager(page: 5, pageCount: 5, onPrevious: () {}));

    expect(find.text('Page 5/5'), findsOneWidget);

    final previous = _opacityOf(tester, Icons.chevron_left_rounded);
    final next = _opacityOf(tester, Icons.chevron_right_rounded);
    expect(previous, AppOpacity.opaque);
    expect(next, AppOpacity.strong);
  });

  testWidgets('pdf pager moves forward and back', (tester) async {
    var page = 2;
    await tester.pumpWidget(
      _host(
        child: StatefulBuilder(
          builder: (context, setState) {
            return PdfPreviewPager(
              page: page,
              pageCount: 5,
              onPrevious: page > 1 ? () => setState(() => page -= 1) : null,
              onNext: page < 5 ? () => setState(() => page += 1) : null,
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('Page 3/5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    expect(find.text('Page 2/5'), findsOneWidget);
  });

  testWidgets('next page slides in from the right and previous page from the left', (tester) async {
    final next = AnimationController(vsync: tester, duration: const Duration(milliseconds: 220));
    addTearDown(next.dispose);
    await tester.pumpWidget(
      _slide(
        animation: next,
        activePage: 2,
        direction: 1,
        child: const SizedBox(key: ValueKey<int>(2), width: 80, height: 80),
      ),
    );
    expect(_offset(tester), const Offset(1, 0));
    next.value = 1;
    await tester.pump();
    expect(_offset(tester), Offset.zero);

    final previous = AnimationController(vsync: tester, duration: const Duration(milliseconds: 220));
    addTearDown(previous.dispose);
    await tester.pumpWidget(
      _slide(
        animation: previous,
        activePage: 1,
        direction: -1,
        child: const SizedBox(key: ValueKey<int>(1), width: 80, height: 80),
      ),
    );
    expect(_offset(tester), const Offset(-1, 0));
  });
}

double _opacityOf(WidgetTester tester, IconData icon) {
  return tester
      .widget<AnimatedOpacity>(
        find.ancestor(of: find.byIcon(icon), matching: find.byType(AnimatedOpacity)),
      )
      .opacity;
}

Offset _offset(WidgetTester tester) {
  return tester.widget<SlideTransition>(find.byType(SlideTransition)).position.value;
}

Widget _pager({required int page, required int pageCount, VoidCallback? onPrevious, VoidCallback? onNext}) {
  return _host(
    child: PdfPreviewPager(
      page: page,
      pageCount: pageCount,
      onPrevious: onPrevious,
      onNext: onNext,
    ),
  );
}

Widget _slide({
  required Animation<double> animation,
  required int activePage,
  required int direction,
  required Widget child,
}) {
  return _host(
    child: pdfPreviewPageTransition(
      child: child,
      animation: animation,
      activePage: activePage,
      direction: direction,
    ),
  );
}

Widget _host({required Widget child}) {
  return MaterialApp(
    theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
    home: Scaffold(body: Center(child: child)),
  );
}
