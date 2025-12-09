/// Fichier de constantes de l'application
/// 
/// Ce fichier centralise toutes les constantes utilisées dans l'application :
/// - Messages d'erreur et de succès
/// - Paramètres de validation
/// - Configuration des APIs externes
/// 
/// Avantages :
/// - Facilite la maintenance (modification en un seul endroit)
/// - Améliore la lisibilité du code
/// - Évite les erreurs de typo

class AppConstants {
  // ========== MESSAGES D'ERREUR ==========
  
  /// Message d'erreur générique pour les problèmes de réseau
  static const String errorNetwork = 'Erreur de connexion réseau';
  
  /// Message d'erreur générique pour les erreurs inconnues
  static const String errorUnknown = 'Une erreur est survenue';
  
  // ========== MESSAGES DE SUCCÈS ==========
  
  /// Message de succès affiché après une connexion réussie
  static const String successLogin = 'Connexion réussie !';
  
  /// Message de succès affiché après une inscription réussie
  static const String successSignup = 'Inscription réussie !';
  
  // ========== VALIDATION ==========
  
  /// Longueur minimale requise pour un mot de passe
  /// Utilisée lors de l'inscription et de la validation
  static const int minPasswordLength = 6;
  
  // ========== CONFIGURATION GÉNÉRALE ==========
  
  /// Nom de l'application affiché dans l'interface
  static const String appName = 'Movie App';
  
  // ========== CONFIGURATION API TMDb ==========
  
  /// Clé API pour The Movie Database (TMDb)
  /// 
  /// Pour obtenir une clé API gratuite :
  /// 1. Créer un compte sur https://www.themoviedb.org/
  /// 2. Aller dans Paramètres > API
  /// 3. Demander une clé API (type Developer)
  /// 4. Copier la clé ici
  /// 
  /// Documentation : https://www.themoviedb.org/documentation/api
  /// 
  /// ⚠️ IMPORTANT : Remplacez cette clé par votre propre clé API avant de commiter sur GitHub
  /// Pour obtenir une clé gratuite : https://www.themoviedb.org/settings/api
  static const String tmdbApiKey = 'YOUR_TMDB_API_KEY';
  
  /// URL de base de l'API TMDb
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  
  /// URL de base pour les images TMDb
  /// Utilisée pour construire les URLs complètes des affiches de films
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  
  // ========== CONFIGURATION API RAPIDAPI (Alternative) ==========
  
  /// Clé API pour RapidAPI (alternative à TMDb)
  /// 
  /// Non utilisée actuellement, mais disponible si vous préférez
  /// utiliser l'API MovieDB de RapidAPI
  static const String rapidApiKey = 'YOUR_RAPIDAPI_KEY';
  
  /// Host de l'API RapidAPI
  static const String rapidApiHost = 'moviesdatabase.p.rapidapi.com';
  
  /// URL de base de l'API RapidAPI
  static const String rapidApiBaseUrl = 'https://moviesdatabase.p.rapidapi.com';
}




