/// Fichier d'exemple pour les constantes de l'application
/// 
/// Ce fichier montre la structure attendue sans exposer les clés API réelles.
/// 
/// Pour utiliser ce fichier :
/// 1. Copiez ce fichier vers constants.dart
/// 2. Remplacez les placeholders par vos vraies clés API
/// 3. Ne commitez JAMAIS constants.dart avec vos vraies clés

class AppConstants {
  // ========== MESSAGES D'ERREUR ==========
  
  static const String errorNetwork = 'Erreur de connexion réseau';
  static const String errorUnknown = 'Une erreur est survenue';
  
  // ========== MESSAGES DE SUCCÈS ==========
  
  static const String successLogin = 'Connexion réussie !';
  static const String successSignup = 'Inscription réussie !';
  
  // ========== VALIDATION ==========
  
  static const int minPasswordLength = 6;
  
  // ========== CONFIGURATION GÉNÉRALE ==========
  
  static const String appName = 'Movie App';
  
  // ========== CONFIGURATION API TMDb ==========
  
  /// Remplacez 'YOUR_TMDB_API_KEY' par votre clé API TMDb
  /// Obtenez une clé gratuite sur : https://www.themoviedb.org/settings/api
  static const String tmdbApiKey = 'YOUR_TMDB_API_KEY';
  
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  
  // ========== CONFIGURATION API RAPIDAPI (Alternative) ==========
  
  static const String rapidApiKey = 'YOUR_RAPIDAPI_KEY';
  static const String rapidApiHost = 'moviesdatabase.p.rapidapi.com';
  static const String rapidApiBaseUrl = 'https://moviesdatabase.p.rapidapi.com';
}



