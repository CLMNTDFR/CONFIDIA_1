import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:confidia/shared/widgets/confidia_dropdown_field.dart';
import 'package:confidia/shared/widgets/confidia_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('menu button aligns with a compact IconButton', (tester) async {
    await tester.pumpWidget(
      wrap(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Télécharger',
              icon: const Icon(Icons.download_outlined),
              onPressed: () {},
            ),
            ConfidiaMenuButton<String>(
              tooltip: 'Plus d\'actions',
              items: const [
                ConfidiaMenuEntry(value: 'edit', label: 'Modifier'),
              ],
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    );

    final download = tester.getRect(find.byTooltip('Télécharger'));
    final menu = tester.getRect(find.byTooltip('Plus d\'actions'));
    expect((download.center.dy - menu.center.dy).abs(), lessThan(0.5));
  });

  testWidgets('menu button opens chrome panel and selects an entry', (tester) async {
    String? selected;
    await tester.pumpWidget(
      wrap(
        ConfidiaMenuButton<String>(
          tooltip: 'Plus d\'actions',
          items: const [
            ConfidiaMenuEntry(value: 'edit', label: 'Modifier', icon: Icons.edit_outlined),
            ConfidiaMenuEntry(
              value: 'delete',
              label: 'Supprimer',
              icon: Icons.delete_outline_rounded,
              destructive: true,
            ),
          ],
          onSelected: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Plus d\'actions'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(selected, 'edit');
    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets('dropdown field opens the same menu and updates the value', (tester) async {
    String? value = 'facture';
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 320,
              child: ConfidiaDropdownField<String>(
                value: value,
                items: const ['facture', 'contrat', 'autre'],
                itemLabel: (item) => item,
                labelText: 'Type de document',
                onChanged: (next) => setState(() => value = next),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('facture'), findsOneWidget);
    await tester.tap(find.text('facture'));
    await tester.pumpAndSettle();

    expect(find.text('contrat'), findsOneWidget);
    await tester.tap(find.text('contrat'));
    await tester.pumpAndSettle();

    expect(value, 'contrat');
    expect(find.text('contrat'), findsOneWidget);
    expect(find.text('facture'), findsNothing);
  });
}
