import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/ville_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/lieu_provider.dart';
import 'providers/suggestion_provider.dart';
import 'providers/commentaires_provider.dart';
import 'providers/historique_provider.dart';

import 'services/preferences_service.dart';
import 'db/database_helper.dart';

import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/details_screen.dart';
import 'screens/modification_screen.dart';

import 'models/lieu.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du "databaseFactory" selon la plateforme :
  // - Web : utilise une implémentation compatible navigateur
  // - Desktop (Windows/Linux) : initialise sqflite FFI + factory FFI
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    sqffi.sqfliteFfiInit();
    databaseFactory = sqffi.databaseFactoryFfi;
  }

  await PreferencesService.init();

  await DatabaseHelper.database;

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProvider(create: (_) => VilleProvider()),

        ChangeNotifierProvider(create: (_) => LieuProvider()),

        ChangeNotifierProvider(create: (_) => SuggestionProvider()),

        ChangeNotifierProvider(create: (_) => CommentaireProvider()),

        ChangeNotifierProvider(create: (_) => HistoriqueProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    // Récupère le ThemeProvider pour appliquer le ThemeData courant
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme =
        themeProvider.currentTheme; // ThemeData actuel (clair ou sombre)

    return MaterialApp(
      title: 'Explorez Votre Ville',
      debugShowCheckedModeBanner: false,

      theme: theme,

      // Route initiale (page d'accueil)
      initialRoute: '/',

      // Gestion des routes
      onGenerateRoute: (settings) {
        // Convertit le nom de route en URI pour récupérer les segments
        final uri = Uri.parse(settings.name ?? '/');
        final segments = uri.pathSegments;

        // "/" => segments vide
        if (segments.isEmpty) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/'),
            builder: (_) => const HomeScreen(),
          );
        }

        // "/main"
        if (segments.length == 1 && segments[0] == 'main') {
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/main'),
            builder: (_) => const MainScreen(),
          );
        }

        // Détails :
        if (segments.length >= 2 &&
            segments[0] == 'main' &&
            segments[1] == 'details') {
          // Les données attendues sont passées via settings.arguments
          final args = settings.arguments;

          if (args is Lieu) {
            final bool isModification =
                segments.length >= 4 && segments[3] == 'modification';

            // Route vers l’écran de modification
            if (isModification) {
              return MaterialPageRoute(
                settings: RouteSettings(name: settings.name),
                builder: (_) => ModificationScreen(lieu: args),
              );
            }

            // Route vers l’écran de détails
            return MaterialPageRoute(
              settings: RouteSettings(name: settings.name),
              builder: (_) => DetailsScreen(lieu: args),
            );
          }

          // Si arguments invalides => fallback accueil
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/'),
            builder: (_) => const HomeScreen(),
          );
        }

        // Toute autre route : accueil
        return MaterialPageRoute(
          settings: const RouteSettings(name: '/'),
          builder: (_) => const HomeScreen(),
        );
      },
    );
  }
}

/*
  il reste à faire :
  - readme? 
  - card lieu? 
*/
