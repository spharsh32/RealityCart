import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reality_cart/openingphase/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/wishlist_provider.dart';
import 'package:reality_cart/providers/cart_provider.dart';
import 'package:reality_cart/providers/theme_provider.dart';
import 'package:reality_cart/providers/notification_provider.dart';
import 'package:reality_cart/providers/admin_notification_provider.dart';
import 'package:reality_cart/admin/providers/admin_provider.dart';
import 'package:reality_cart/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('DEBUG: App started');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('DEBUG: Firebase initialized');

    // Initialize FCM (Don't await to prevent blocking app start on web if it fails)
    FCMService.initialize().then((_) {
      print('DEBUG: FCM Initialized');
    }).catchError((e) {
      print('DEBUG: FCM Initialization failed: $e');
    });

    FCMService.subscribeToTopic('new_products').catchError((e) {
      print('DEBUG: Topic subscription failed: $e');
    });
    
  } catch (e) {
    print('DEBUG: Initialization failed: $e');
  }

  runApp(
    DevicePreview(
      enabled: true, // Set to false to disable
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => AdminNotificationProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        print('DEBUG: MyApp rebuilding with locale: ${languageProvider.currentLocale.languageCode}');
        return MaterialApp(
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('hi'), // Hindi
            Locale('gu'), // Gujarati
          ],
          debugShowCheckedModeBanner: false,
          builder: DevicePreview.appBuilder,
          title: 'Reality Cart',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFB8C00),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            textTheme: GoogleFonts.notoSansTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFB8C00),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
