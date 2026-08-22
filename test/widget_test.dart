import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:punklorde/app/theme/default.dart';
import 'package:punklorde/utils/etc/fdialog.dart';

void main() {
  testWidgets('forui theme renders widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      FTheme(
        data: lightTheme,
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: FButton(onPress: null, child: Text('Hello'))),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Hello'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('punklordeDialog opens via showFDialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      FTheme(
        data: lightTheme,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FButton(
                  onPress: () {
                    showFDialog(
                      context: context,
                      builder: (context, style, animation) => punklordeDialog(
                        style: style,
                        animation: animation,
                        title: const Text('Dialog Title'),
                        body: const Text('Dialog Body'),
                        actions: [
                          FButton(
                            size: .xs,
                            onPress: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Dialog Title'), findsOneWidget);
    expect(find.text('Dialog Body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
