import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'firebase_options.dart';
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
            // ... (Your existing theme data remains the same)
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
  late final Future<void> _introDelay;

  @override
  void initState() {
    super.initState();
    _initialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // 🔥 UPDATED: Set to 4000ms (4 seconds) as requested
    _introDelay = Future<void>.delayed(const Duration(milliseconds: 4000));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _introDelay,
      builder: (context, snapshot) {
        // Show splash screen while the 4-second timer is running
        if (snapshot.connectionState != ConnectionState.done) {
          return const _IntroSplashScreen();
        }

        return FutureBuilder<FirebaseApp>(
          future: _initialization,
          builder: (context, firebaseSnapshot) {
            if (firebaseSnapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Startup failed: ${firebaseSnapshot.error}')),
              );
            }

            // Once 4 seconds are up AND Firebase is ready, go to WelcomeScreen
            if (firebaseSnapshot.connectionState == ConnectionState.done) {
              return const WelcomeScreen();
            }

            // Fallback while Firebase finishes if it takes > 4 seconds
            return const _IntroSplashScreen();
          },
        );
      },
    );
  }
}

class _IntroSplashScreen extends StatefulWidget {
  const _IntroSplashScreen();

  @override
  State<_IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<_IntroSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // 🔥 UPDATED: Slowed down the animation for a smoother feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // Smooth fade in
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF183020), // Darker green for a premium look
              Color(0xFF2F6A3E),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Color(0xFF2F6A3E),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "REVOLVE AGRO",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Cultivating the Future",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}