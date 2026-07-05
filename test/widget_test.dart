// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes_management_app/main.dart';
import 'package:notes_management_app/screens/notes_list_screen.dart';

void main() {
  testWidgets('Notes App Smoke Test - Unconfigured Firebase', (WidgetTester tester) async {
    // Build our app and trigger a frame with Firebase uninitialized.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(
          isFirebaseInitialized: false,
          initializationError: 'Firebase setup required',
        ),
      ),
    );

    // Verify that the Firebase error instruction screen is displayed.
    expect(find.text('Firebase Initialization Failed'), findsOneWidget);
  });
}
