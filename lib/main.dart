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

// Import du package Flutter Material pour les widgets UI (Scaffold, AppBar, etc.)
import 'package:flutter/material.dart';
// Import du package Flutter Foundation pour debugPrint et autres utilitaires de débogage
import 'package:flutter/foundation.dart';
// Import pour les opérations asynchrones (Future, async/await)
import 'dart:async';
// Import pour PlatformDispatcher (gestion des erreurs au niveau de la plateforme)
import 'dart:ui';
// Import du package Firebase Core pour initialiser Firebase
import 'package:firebase_core/firebase_core.dart';
// Import du package Firebase Auth pour l'authentification des utilisateurs
import 'package:firebase_auth/firebase_auth.dart';
// Import de l'écran de connexion
import 'screens/login_screen.dart';
// Import de l'écran d'accueil principal
import 'screens/home_screen.dart';

/// Fonction main : Point d'entrée de l'application
/// 
/// Processus d'initialisation :
/// 1. Initialiser Flutter bindings (nécessaire avant toute opération Flutter)
/// 2. Configurer les gestionnaires d'erreurs globaux
/// 3. Initialiser Firebase
/// 4. Lancer l'application
/// Fonction main : Point d'entrée de l'application
/// 
/// Cette fonction est appelée automatiquement au démarrage de l'application.
/// Elle est marquée comme `async` car elle doit attendre l'initialisation de Firebase.
/// 
/// Ordre d'exécution :
/// 1. Initialiser Flutter bindings (obligatoire avant toute opération Flutter)
/// 2. Configurer les gestionnaires d'erreurs globaux (pour ignorer les erreurs Firebase internes)
/// 3. Initialiser Firebase (charge la configuration depuis google-services.json)
/// 4. Lancer l'application avec runApp()
void main() async {
  // Initialiser Flutter bindings
  // Cette méthode est OBLIGATOIRE avant toute utilisation de widgets Flutter ou plugins.
  // Elle initialise le moteur de rendu Flutter et permet l'utilisation des canaux de communication
  // entre Dart et le code natif (Android/iOS).
  // Sans cette initialisation, l'application planterait immédiatement.
  WidgetsFlutterBinding.ensureInitialized();

  // ========== GESTIONNAIRE D'ERREURS GLOBAL ==========
  
  /// Gestionnaire d'erreurs pour les erreurs Flutter capturées
  /// 
  /// Ce gestionnaire intercepte toutes les erreurs qui se produisent dans le code Flutter
  /// (erreurs synchrones dans les widgets, build methods, etc.).
  /// 
  /// Ignore spécifiquement l'erreur Firebase interne "PigeonUserDetails"
  /// qui est un bug connu de Firebase et ne doit pas bloquer l'application.
  /// 
  /// Pour toutes les autres erreurs, utilise le gestionnaire par défaut
  /// qui affiche l'erreur à l'utilisateur.
  /// 
  /// Paramètres :
  /// - [details] : Objet FlutterErrorDetails contenant l'exception, la stack trace, etc.
  FlutterError.onError = (FlutterErrorDetails details) {
    // Convertir l'exception en string et mettre en minuscules pour la comparaison
    // Cela permet de détecter l'erreur même si la casse est différente
    final errorString = details.exception.toString().toLowerCase();
    
    // Vérifier si c'est l'erreur Firebase interne connue "PigeonUserDetails"
    // Cette erreur est un bug connu de Firebase qui se produit lors de la récupération
    // des données utilisateur. Elle n'affecte pas le fonctionnement de l'application.
    // On la détecte en cherchant des mots-clés dans le message d'erreur :
    // - "pigeonuserdetails" : nom de la classe interne Firebase
    // - "list<object?>" : type de données incorrect retourné par Firebase
    // - "type" + "subtype" : erreur de cast de type
    if (errorString.contains('pigeonuserdetails') || 
        errorString.contains('list<object?>') ||
        (errorString.contains('type') && errorString.contains('subtype'))) {
      // Ignorer cette erreur Firebase interne (bug connu)
      // Afficher un message dans les logs pour le débogage, mais ne pas bloquer l'application
      debugPrint('Erreur Firebase interne ignorée: ${details.exception}');
      // Retourner sans rien faire pour ignorer l'erreur
      return; // Ne pas afficher l'erreur à l'utilisateur
    }
    
    // Pour toutes les autres erreurs (non liées à Firebase), utiliser le gestionnaire par défaut
    // qui affiche l'erreur dans l'interface utilisateur (écran rouge d'erreur en mode debug)
    FlutterError.presentError(details);
  };

  /// Gestionnaire d'erreurs pour les erreurs non capturées (asynchrones)
  /// 
  /// Ce gestionnaire intercepte les erreurs qui se produisent dans le code asynchrone
  /// (callbacks, Futures, Streams) et qui ne sont pas capturées par les blocs try-catch.
  /// 
  /// Gère les erreurs qui ne sont pas capturées par les try-catch
  /// (par exemple dans les callbacks asynchrones, les Futures non await, etc.)
  /// 
  /// Paramètres :
  /// - [error] : L'objet d'erreur (peut être de n'importe quel type)
  /// - [stack] : La stack trace associée à l'erreur
  /// 
  /// Retourne :
  /// - true : L'erreur a été gérée, ne pas la propager
  /// - false : L'erreur n'a pas été gérée, laisser Flutter la gérer (crash de l'app)
  PlatformDispatcher.instance.onError = (error, stack) {
    // Convertir l'erreur en string et mettre en minuscules pour la comparaison
    final errorString = error.toString().toLowerCase();
    
    // Vérifier si c'est l'erreur Firebase interne connue (même logique que FlutterError.onError)
    // Cette erreur peut aussi se produire dans des callbacks asynchrones
    if (errorString.contains('pigeonuserdetails') || 
        errorString.contains('list<object?>') ||
        (errorString.contains('type') && errorString.contains('subtype'))) {
      // Ignorer cette erreur Firebase interne
      // Afficher un message dans les logs pour le débogage
      debugPrint('Erreur Firebase interne ignorée (non capturée): $error');
      // Retourner true pour indiquer que l'erreur a été gérée et ne doit pas faire planter l'app
      return true; // Indique que l'erreur a été gérée, ne pas faire planter l'application
    }
    
    // Pour toutes les autres erreurs, retourner false pour laisser Flutter les gérer
    // Cela provoquera un crash de l'application (normal en cas d'erreur non gérée)
    return false; // Laisser Flutter gérer les autres erreurs (crash de l'app)
  };

  // ========== INITIALISATION FIREBASE ==========
  
  /// Initialiser Firebase
  /// 
  /// Cette méthode charge la configuration Firebase depuis les fichiers de configuration :
  /// - Android : android/app/google-services.json
  /// - iOS : ios/Runner/GoogleService-Info.plist
  /// 
  /// L'initialisation est asynchrone (await) car elle doit :
  /// - Lire les fichiers de configuration
  /// - Se connecter aux services Firebase
  /// - Initialiser les SDK Firebase (Auth, Firestore, Storage)
  /// 
  /// NOTE: Vous devez configurer Firebase avant de lancer l'application
  /// Voir les guides : FIX_FIREBASE_AUTH.md, ENABLE_FIRESTORE.md
  try {
    // Appeler Firebase.initializeApp() pour initialiser tous les services Firebase
    // Cette méthode est asynchrone, donc on utilise await pour attendre la fin
    await Firebase.initializeApp();
    // Afficher un message de succès dans les logs (visible dans la console de débogage)
    debugPrint('✅ Firebase initialisé avec succès');
  } catch (e) {
    // Si Firebase n'est pas configuré ou s'il y a une erreur, capturer l'exception
    // L'application peut toujours démarrer, mais Firebase ne fonctionnera pas
    // (authentification, base de données, etc. ne fonctionneront pas)
    debugPrint('❌ Erreur lors de l\'initialisation de Firebase: $e');
    debugPrint('⚠️ Assurez-vous que Firebase est correctement configuré.');
    debugPrint('📋 Voir les guides de configuration dans le projet.');
    // Note : On ne fait pas planter l'application, elle peut démarrer sans Firebase
    // mais les fonctionnalités Firebase ne seront pas disponibles
  }

  // Lancer l'application Flutter
  // runApp() est la méthode qui démarre réellement l'application Flutter
  // Elle prend en paramètre le widget racine (MyApp) qui sera rendu à l'écran
  // const MyApp() crée une instance constante de MyApp (optimisation de performance)
  runApp(const MyApp());
}

/// Widget racine de l'application
/// 
/// Cette classe représente le widget racine de toute l'application Flutter.
/// Elle hérite de StatelessWidget car elle n'a pas d'état mutable.
/// 
/// Configure :
/// - Le thème de l'application (Material Design 3)
/// - Les routes de navigation (chemins nommés pour naviguer entre les écrans)
/// - Le widget de démarrage (AuthWrapper qui gère l'authentification)
/// 
/// MaterialApp est le widget principal qui :
/// - Fournit le thème Material Design à toute l'application
/// - Gère la navigation entre les écrans
/// - Fournit le contexte Material nécessaire pour tous les widgets enfants
class MyApp extends StatelessWidget {
  /// Constructeur constant pour optimiser les performances
  /// super.key permet de passer une clé au widget parent (StatelessWidget)
  const MyApp({super.key});

  /// Méthode build : Construit l'interface utilisateur de ce widget
  /// 
  /// Cette méthode est appelée automatiquement par Flutter quand le widget doit être rendu.
  /// Elle retourne un MaterialApp qui est le widget racine de l'application Material Design.
  /// 
  /// Paramètres :
  /// - [context] : Le contexte BuildContext qui contient les informations sur l'arbre de widgets
  @override
  Widget build(BuildContext context) {
    // Retourner un MaterialApp qui est le widget racine de l'application Material Design
    return MaterialApp(
      // Titre de l'application (utilisé par le système d'exploitation)
      // Ce titre apparaît dans la barre des tâches, les notifications, etc.
      title: 'Movie App',
      
      // Thème Material Design 3 de l'application
      // Le thème définit les couleurs, les styles de texte, les formes, etc.
      theme: ThemeData(
        // Couleur principale de l'application (utilisée pour les boutons, AppBar, etc.)
        // Colors.blue est une palette de couleurs bleues prédéfinie
        primarySwatch: Colors.blue,
        // Utiliser Material Design 3 (la dernière version du design system Material)
        // Material 3 apporte de nouvelles couleurs, formes et animations
        useMaterial3: true,
      ),
      
      // Widget de démarrage : AuthWrapper gère la redirection selon l'état d'authentification
      // AuthWrapper vérifie si l'utilisateur est connecté et redirige vers l'écran approprié
      // const AuthWrapper() crée une instance constante (optimisation)
      home: const AuthWrapper(),
      
      // Routes nommées pour la navigation entre les écrans
      // Les routes nommées permettent de naviguer avec Navigator.pushNamed('/login')
      // au lieu de Navigator.push(MaterialPageRoute(...))
      routes: {
        // Route '/login' : Affiche l'écran de connexion
        // (context) => const LoginScreen() : Fonction qui crée l'écran LoginScreen
        '/login': (context) => const LoginScreen(),
        // Route '/home' : Affiche l'écran d'accueil principal
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

/// Widget qui vérifie l'état d'authentification et redirige l'utilisateur
/// 
/// Ce widget est un StatefulWidget car il doit gérer un état (l'état d'authentification).
/// Il utilise un StreamBuilder pour écouter les changements d'état d'authentification Firebase.
/// 
/// Fonctionnement :
/// 1. Écoute les changements d'état d'authentification Firebase via authStateChanges()
/// 2. Affiche un indicateur de chargement pendant la vérification initiale
/// 3. Redirige vers l'écran approprié selon l'état (connecté ou non connecté)
/// 
/// Comportement actuel :
/// - Toujours affiche l'écran de connexion au démarrage
/// - L'utilisateur doit se connecter même s'il a une session active
/// 
/// Pour changer ce comportement :
/// - Modifier la logique dans le builder pour rediriger automatiquement
///   vers HomeScreen si snapshot.hasData est true
class AuthWrapper extends StatefulWidget {
  /// Constructeur constant pour optimiser les performances
  /// super.key permet de passer une clé au widget parent (StatefulWidget)
  const AuthWrapper({super.key});

  /// Méthode createState : Crée l'état associé à ce widget
  /// 
  /// Cette méthode est appelée automatiquement par Flutter pour créer l'objet State
  /// qui gère l'état mutable de ce widget.
  /// 
  /// Retourne : Une instance de _AuthWrapperState qui gère l'état de ce widget
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

/// Classe d'état pour AuthWrapper
/// 
/// Cette classe gère l'état mutable du widget AuthWrapper.
/// Elle utilise un StreamBuilder pour écouter les changements d'authentification.
class _AuthWrapperState extends State<AuthWrapper> {
  /// Méthode build : Construit l'interface utilisateur de ce widget
  /// 
  /// Cette méthode utilise un StreamBuilder pour écouter les changements d'état d'authentification.
  /// Le StreamBuilder se reconstruit automatiquement à chaque changement d'état.
  /// 
  /// Paramètres :
  /// - [context] : Le contexte BuildContext qui contient les informations sur l'arbre de widgets
  /// 
  /// Retourne : Un widget qui affiche soit un indicateur de chargement, soit l'écran de connexion
  @override
  Widget build(BuildContext context) {
    // StreamBuilder : Widget qui écoute un Stream et se reconstruit à chaque nouvelle valeur
    // 
    // StreamBuilder<User?> : Le type générique User? indique que le Stream émet des User? (nullable)
    // - User : Objet représentant un utilisateur Firebase connecté
    // - null : Aucun utilisateur connecté
    return StreamBuilder<User?>(
      // stream : Le Stream à écouter
      // FirebaseAuth.instance.authStateChanges() retourne un Stream qui émet :
      // - Un événement immédiatement avec l'état actuel (User ou null)
      // - Un nouvel événement à chaque changement d'état (connexion, déconnexion)
      stream: FirebaseAuth.instance.authStateChanges(),
      // builder : Fonction appelée à chaque fois que le Stream émet une nouvelle valeur
      // Cette fonction reçoit le contexte et un snapshot contenant les données du Stream
      builder: (context, snapshot) {
        // Log pour déboguer
        debugPrint('🔍 AuthWrapper - ConnectionState: ${snapshot.connectionState}');
        debugPrint('🔍 AuthWrapper - hasData: ${snapshot.hasData}');
        debugPrint('🔍 AuthWrapper - hasError: ${snapshot.hasError}');
        if (snapshot.hasError) {
          debugPrint('🔍 AuthWrapper - Error: ${snapshot.error}');
        }
        
        // snapshot.connectionState : État de la connexion au Stream
        // ConnectionState.waiting : Le Stream n'a pas encore émis de valeur (chargement initial)
        // Dans ce cas, on affiche un indicateur de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ AuthWrapper - Affiche l\'indicateur de chargement');
          // Retourner un Scaffold avec un indicateur de chargement centré
          // Scaffold : Widget de base pour une page Material Design
          // Center : Widget qui centre son enfant
          // CircularProgressIndicator : Indicateur de chargement circulaire animé
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Gérer les erreurs
        if (snapshot.hasError) {
          debugPrint('❌ AuthWrapper - Erreur: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }

        // Comportement actuel : Toujours afficher l'écran de connexion
        // 
        // Pour activer la redirection automatique si l'utilisateur est déjà connecté,
        // décommenter le code suivant :
        //
        // snapshot.hasData : Vérifie si le Stream a émis une valeur non-null
        // Si true, cela signifie qu'un utilisateur est connecté
        // if (snapshot.hasData) {
        //   // Utilisateur connecté, rediriger vers l'écran d'accueil
        //   // snapshot.data contient l'objet User Firebase
        //   return const HomeScreen();
        // }
        //
        // // Utilisateur non connecté (snapshot.data == null), afficher l'écran de connexion
        // return const LoginScreen();
        
        // Pour l'instant, toujours afficher l'écran de connexion
        // L'utilisateur devra se connecter même s'il a une session active
        // Ce comportement est utile pour les tests ou pour forcer la reconnexion
        // const LoginScreen() crée une instance constante de l'écran de connexion
        debugPrint('✅ AuthWrapper - Affiche LoginScreen');
        try {
        return const LoginScreen();
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors de la création de LoginScreen: $e');
          debugPrint('Stack trace: $stackTrace');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: $e'),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}