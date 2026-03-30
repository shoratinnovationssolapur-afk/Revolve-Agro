import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'firebase_options.dart';
import 'screens/product_list.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RevolveAgroApp());
}

class RevolveAgroApp extends StatelessWidget {
  const RevolveAgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2F6A3E);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
      secondary: const Color(0xFFD9952E),
      surface: const Color(0xFFF7F3E8),
    );

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.text('app_name'),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: const Color(0xFFF7F3E8),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF183020),
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Color(0xFF183020),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: seed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF214B2D),
                side: const BorderSide(color: Color(0x33214B2D)),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              hintStyle: TextStyle(color: Colors.grey.shade500),
              labelStyle: const TextStyle(color: Color(0xFF496155)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0x1F214B2D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF2F6A3E), width: 1.5),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF183020),
              contentTextStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFE4F1DD),
              labelStyle: const TextStyle(
                color: Color(0xFF214B2D),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Color(0x1F214B2D)),
              ),
            ),
          ),
          home: const _AppBootstrap(),
        );
      },
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'App startup failed: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.hasData) {
              return RevolveAgroProducts();
            }
            return const WelcomeScreen();
          },
        );
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7F1D9),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F6A3E), Color(0xFF6BAA54)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.agriculture, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 22),
              Text(
                context.l10n.text('app_name'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183020),
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF2F6A3E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
