import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/notes_list_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isFirebaseInitialized = false;
  String? initializationError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    initializationError = e.toString();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
        isFirebaseInitialized: isFirebaseInitialized,
        initializationError: initializationError,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  final String? initializationError;

  const MyApp({
    super.key,
    required this.isFirebaseInitialized,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Light Theme Definition
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.lightPrimary,
        brightness: Brightness.light,
        primary: AppConstants.lightPrimary,
        surface: AppConstants.lightSurface,
        primaryContainer: AppConstants.lightPrimaryContainer,
        onPrimaryContainer: AppConstants.lightOnPrimaryContainer,
        error: AppConstants.colorError,
      ),
      scaffoldBackgroundColor: AppConstants.lightBg,
      cardTheme: CardThemeData(
        color: AppConstants.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: AppConstants.lightBorder),
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ),
    );

    // Dark Theme Definition
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.darkPrimary,
        brightness: Brightness.dark,
        primary: AppConstants.darkPrimary,
        surface: AppConstants.darkSurface,
        primaryContainer: AppConstants.darkPrimaryContainer,
        onPrimaryContainer: AppConstants.darkOnPrimaryContainer,
        error: AppConstants.colorError,
      ),
      scaffoldBackgroundColor: AppConstants.darkBg,
      cardTheme: CardThemeData(
        color: AppConstants.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: AppConstants.darkBorder),
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
    );

    return MaterialApp(
      title: 'Notes Management App',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      home: !isFirebaseInitialized
          ? FirebaseErrorScreen(error: initializationError)
          : const MainAppWrapper(),
    );
  }
}

/// Screen to display if Firebase initialization fails entirely (e.g. library load failure or platform incompatibilities)
class FirebaseErrorScreen extends StatelessWidget {
  final String? error;

  const FirebaseErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 80,
                color: AppConstants.colorError,
              ),
              const SizedBox(height: AppConstants.spaceLG),
              Text(
                'Firebase Initialization Failed',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spaceSM),
              Text(
                error ?? 'An unknown error occurred during initialization.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper to check if placeholder config is active and show an optional setup warning banner
class MainAppWrapper extends StatelessWidget {
  const MainAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if the current options are using the placeholder project ID
    final isPlaceholder = DefaultFirebaseOptions.currentPlatform.projectId == 'notes-app-placeholder';

    return Column(
      children: [
        if (isPlaceholder)
          Material(
            color: theme.colorScheme.primaryContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceMD,
                  vertical: AppConstants.spaceSM,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spaceSM),
                    Expanded(
                      child: Text(
                        'Using placeholder Firebase config. Setup is required for data sync.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSM),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        _showSetupInstructions(context);
                      },
                      child: Text(
                        'Setup Guide',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const Expanded(
          child: NotesListScreen(),
        ),
      ],
    );
  }

  void _showSetupInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppConstants.spaceLG),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceLG),
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: AppConstants.spaceSM),
                    Text(
                      'Firebase Setup Steps',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceMD),
                const Divider(),
                const SizedBox(height: AppConstants.spaceMD),
                _buildStep(
                  '1',
                  'Install Firebase CLI',
                  'Run this command globally on your development machine:\n`npm install -g firebase-tools`',
                  theme,
                ),
                _buildStep(
                  '2',
                  'Log in to Firebase',
                  'Authenticate CLI tool by running:\n`firebase login`',
                  theme,
                ),
                _buildStep(
                  '3',
                  'Activate FlutterFire CLI',
                  'Enable the Flutter-specific CLI tools globally:\n`dart pub global activate flutterfire_cli`',
                  theme,
                ),
                _buildStep(
                  '4',
                  'Configure Firebase in this App',
                  'Run this command in the project root to generate the actual configurations:\n`flutterfire configure`',
                  theme,
                ),
                const SizedBox(height: AppConstants.spaceLG),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStep(String number, String title, String description, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceLG),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              number,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
