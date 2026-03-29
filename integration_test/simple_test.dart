import 'package:flutter_test/flutter_test.dart';
import 'package:punklorde/app/main.dart';
import 'package:punklorde/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    await tester.pumpWidget(const MainMobileApp());
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  });
}
