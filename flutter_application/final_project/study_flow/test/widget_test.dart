import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/main.dart';

void main() {
  testWidgets('App login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen is displayed by finding the 'Login' title text.
    expect(find.text('Login'), findsAtLeastNWidgets(1));
  });
}


