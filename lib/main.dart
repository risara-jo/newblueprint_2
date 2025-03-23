import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/project_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/landing_screen.dart';
import 'firebase_options.dart';
import 'theme.dart'; // ✅ Import your custom theme

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Initialized Successfully!");

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    print("✅ Firestore Logging Enabled!");
  } catch (e) {
    print("❌ Firebase Initialization Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            print("✅ AuthService Provider Initialized");
            return AuthService();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ ProjectProvider Initialized");
            return ProjectProvider();
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Blueprint',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            iconTheme: IconThemeData(color: AppColors.white),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: AppColors.white),
            bodyLarge: TextStyle(color: AppColors.white),
            titleLarge: TextStyle(color: AppColors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            hintStyle: const TextStyle(color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/':
              (context) => Consumer<AuthService>(
                builder: (context, authService, child) {
                  if (authService.currentUser != null) {
                    print("🔄 User is Logged In - Navigating to LandingScreen");
                    return const LandingScreen();
                  } else {
                    print("🔄 No User Found - Navigating to AuthScreen");
                    return const AuthScreen();
                  }
                },
              ),
          '/auth': (context) {
            print("🔄 Navigating to AuthScreen");
            return const AuthScreen();
          },
          '/landing': (context) {
            print("🔄 Navigating to LandingScreen");
            return const LandingScreen();
          },
        },
      ),
    );
  }
}
