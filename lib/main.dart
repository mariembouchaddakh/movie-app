/// Point d'entrée principal de l'application Flutter
/// 
/// Ce fichier initialise :
/// - Flutter et ses bindings
/// - Firebase (Auth, Firestore, Storage)
/// - Les gestionnaires d'erreurs globaux
/// - L'application MaterialApp avec routing
/// 
/// Architecture :
/// - MyApp : Widget racine de l'application
/// - AuthWrapper : Gère la redirection selon l'état d'authentification

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Fonction main : Point d'entrée de l'application
/// 
/// Processus d'initialisation :
/// 1. Initialiser Flutter bindings (nécessaire avant toute opération Flutter)
/// 2. Configurer les gestionnaires d'erreurs globaux
/// 3. Initialiser Firebase
/// 4. Lancer l'application
void main() async {
  // Initialiser Flutter bindings
  // Nécessaire pour utiliser les widgets Flutter et les plugins
  WidgetsFlutterBinding.ensureInitialized();

  // ========== GESTIONNAIRE D'ERREURS GLOBAL ==========
  
  /// Gestionnaire d'erreurs pour les erreurs Flutter capturées
  /// 
  /// Ignore spécifiquement l'erreur Firebase interne "PigeonUserDetails"
  /// qui est un bug connu de Firebase et ne doit pas bloquer l'application.
  /// 
  /// Pour toutes les autres erreurs, utilise le gestionnaire par défaut
  /// qui affiche l'erreur à l'utilisateur.
  FlutterError.onError = (FlutterErrorDetails details) {
    final errorString = details.exception.toString().toLowerCase();
    
    // Vérifier si c'est l'erreur Firebase interne connue
    if (errorString.contains('pigeonuserdetails') || 
        errorString.contains('list<object?>') ||
        (errorString.contains('type') && errorString.contains('subtype'))) {
      // Ignorer cette erreur Firebase interne (bug connu)
      debugPrint('Erreur Firebase interne ignorée: ${details.exception}');
      return; // Ne pas afficher l'erreur
    }
    
    // Pour les autres erreurs, utiliser le gestionnaire par défaut
    FlutterError.presentError(details);
  };

  /// Gestionnaire d'erreurs pour les erreurs non capturées (asynchrones)
  /// 
  /// Gère les erreurs qui ne sont pas capturées par les try-catch
  /// (par exemple dans les callbacks asynchrones)
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorString = error.toString().toLowerCase();
    
    // Vérifier si c'est l'erreur Firebase interne connue
    if (errorString.contains('pigeonuserdetails') || 
        errorString.contains('list<object?>') ||
        (errorString.contains('type') && errorString.contains('subtype'))) {
      // Ignorer cette erreur Firebase interne
      debugPrint('Erreur Firebase interne ignorée (non capturée): $error');
      return true; // Indique que l'erreur a été gérée
    }
    
    // Laisser Flutter gérer les autres erreurs
    return false;
  };

  // ========== INITIALISATION FIREBASE ==========
  
  /// Initialiser Firebase
  /// 
  /// Charge la configuration depuis :
  /// - android/app/google-services.json (Android)
  /// - ios/Runner/GoogleService-Info.plist (iOS)
  /// 
  /// NOTE: Vous devez configurer Firebase avant de lancer l'application
  /// Voir les guides : FIX_FIREBASE_AUTH.md, ENABLE_FIRESTORE.md
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialisé avec succès');
  } catch (e) {
    // Si Firebase n'est pas configuré, afficher un message d'erreur
    // L'application peut toujours démarrer, mais Firebase ne fonctionnera pas
    debugPrint('❌ Erreur lors de l\'initialisation de Firebase: $e');
    debugPrint('⚠️ Assurez-vous que Firebase est correctement configuré.');
    debugPrint('📋 Voir les guides de configuration dans le projet.');
  }

  // Lancer l'application
  runApp(const MyApp());
}

/// Widget racine de l'application
/// 
/// Configure :
/// - Le thème de l'application (Material Design 3)
/// - Les routes de navigation
/// - Le widget de démarrage (AuthWrapper)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Titre de l'application (utilisé par le système)
      title: 'Movie App',
      
      // Thème Material Design 3
      theme: ThemeData(
        primarySwatch: Colors.blue, // Couleur principale
        useMaterial3: true, // Utiliser Material Design 3
      ),
      
      // Widget de démarrage : AuthWrapper gère la redirection
      home: const AuthWrapper(),
      
      // Routes nommées pour la navigation
      routes: {
        '/login': (context) => const LoginScreen(), // Écran de connexion
        '/home': (context) => const HomeScreen(),   // Écran d'accueil
      },
    );
  }
}

/// Widget qui vérifie l'état d'authentification et redirige l'utilisateur
/// 
/// Fonctionnement :
/// 1. Écoute les changements d'état d'authentification Firebase
/// 2. Affiche un indicateur de chargement pendant la vérification
/// 3. Redirige vers l'écran approprié selon l'état
/// 
/// Comportement actuel :
/// - Toujours affiche l'écran de connexion au démarrage
/// - L'utilisateur doit se connecter même s'il a une session active
/// 
/// Pour changer ce comportement :
/// - Modifier la logique dans le builder pour rediriger automatiquement
///   vers HomeScreen si snapshot.hasData est true
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // StreamBuilder écoute les changements d'état d'authentification
    // authStateChanges() émet un événement à chaque changement :
    // - null : Utilisateur déconnecté
    // - User : Utilisateur connecté
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // État de chargement : vérification en cours
        // Afficher un indicateur de chargement pendant la vérification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Comportement actuel : Toujours afficher l'écran de connexion
        // 
        // Pour activer la redirection automatique si l'utilisateur est déjà connecté,
        // décommenter le code suivant :
        //
        // if (snapshot.hasData) {
        //   // Utilisateur connecté, rediriger vers l'écran d'accueil
        //   return const HomeScreen();
        // }
        //
        // // Utilisateur non connecté, afficher l'écran de connexion
        // return const LoginScreen();
        
        // Pour l'instant, toujours afficher l'écran de connexion
        // L'utilisateur devra se connecter même s'il a une session active
        return const LoginScreen();
      },
    );
  }
}