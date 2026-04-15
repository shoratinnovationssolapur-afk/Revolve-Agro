import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ Added
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ Added
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';


// --- 1. DEFINE NOTIFICATION CHANNEL (Matches Python Backend) ---
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'agro_channel', // 🔥 CRITICAL: Must match Python backend channel_id
  'Agro Notifications',
  description: 'Used for important updates from Revolve Agro.',
  importance: Importance.max,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// --- 2. BACKGROUND MESSAGE HANDLER ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- FIX FOR LINE 48: Local Notifications Init ---
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // Use 'settings:' named parameter here
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // --- FIX FOR LINE 61-62: Create Channel ---
  // In v21.0.0, use the 'channel' named parameter
// Change this line:
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel); // Removed 'channel:' parameter name

  // --- Notification Setup ---
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  await messaging.subscribeToTopic("agro_members");
  print("✅ Successfully subscribed to agro_members");

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
          ),
          home: const _AppBootstrap(),
        );
      },
    );
  }
}

// --- KEEPING YOUR BOOTSTRAP & ANIMATION CODE EXACTLY AS IS ---

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
    _introDelay = Future<void>.delayed(const Duration(milliseconds: 4000));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _introDelay,
      builder: (context, snapshot) {
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

            if (firebaseSnapshot.connectionState == ConnectionState.done) {
              return const WelcomeScreen();
            }

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
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
              Color(0xFF183020),
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