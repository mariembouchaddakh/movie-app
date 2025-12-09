/// Modèle de données représentant un utilisateur de l'application
/// 
/// Cette classe encapsule toutes les informations d'un utilisateur :
/// - Informations personnelles (nom, prénom, âge, email)
/// - Photo de profil
/// - Rôle et statut (admin/user, actif/désactivé)
/// - Liste des films favoris
/// 
/// Utilisée pour :
/// - Stocker les utilisateurs dans Firestore
/// - Gérer l'authentification et les permissions
/// - Afficher les profils utilisateurs
class AppUser {
  /// Identifiant unique de l'utilisateur (UID Firebase Auth)
  final String id;
  
  /// Adresse email de l'utilisateur
  final String email;
  
  /// Prénom de l'utilisateur
  final String firstName;
  
  /// Nom de famille de l'utilisateur
  final String lastName;
  
  /// Âge de l'utilisateur (0 si non spécifié)
  final int age;
  
  /// URL de la photo de profil (null si aucune photo)
  final String? photoUrl;
  
  /// Rôle de l'utilisateur : 'admin' ou 'user'
  /// Détermine les permissions dans l'application
  final String role;
  
  /// Statut actif/désactivé de l'utilisateur
  /// Un utilisateur désactivé ne peut plus se connecter
  final bool isActive;
  
  /// Liste des IDs des films favoris de l'utilisateur
  /// Utilisée pour le matching et l'affichage des favoris
  final List<String> favoriteMovies;

  /// Constructeur du modèle AppUser
  /// 
  /// Paramètres :
  /// - [id] : UID Firebase Auth (requis)
  /// - [email] : Email de l'utilisateur (requis)
  /// - [firstName] : Prénom (requis)
  /// - [lastName] : Nom (requis)
  /// - [age] : Âge (requis, peut être 0)
  /// - [photoUrl] : URL de la photo (optionnel)
  /// - [role] : Rôle par défaut 'user' (optionnel)
  /// - [isActive] : Statut actif par défaut true (optionnel)
  /// - [favoriteMovies] : Liste des favoris (optionnel, vide par défaut)
  AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
    this.photoUrl,
    this.role = 'user',
    this.isActive = true,
    List<String>? favoriteMovies,
  }) : favoriteMovies = favoriteMovies ?? [];

  /// Crée une instance AppUser à partir d'un JSON Firestore
  /// 
  /// Cette méthode gère de manière sécurisée :
  /// - Les conversions de types (age, isActive)
  /// - Les valeurs nulles ou manquantes
  /// - Les erreurs de parsing (favoriteMovies)
  /// 
  /// Paramètres :
  /// - [json] : Map contenant les données Firestore
  /// - [id] : ID du document Firestore (UID utilisateur)
  /// 
  /// Retourne une instance AppUser avec des valeurs par défaut si des champs sont absents
  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    // Gérer favoriteMovies de manière sécurisée
    // Le champ peut être absent, null, ou de type différent
    List<String> favoriteMoviesList = [];
    if (json['favoriteMovies'] != null) {
      try {
        final favoriteMoviesData = json['favoriteMovies'];
        // Vérifier que c'est bien une liste
        if (favoriteMoviesData is List) {
          // Convertir chaque élément en string et filtrer les vides
          favoriteMoviesList = favoriteMoviesData
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (e) {
        // En cas d'erreur, utiliser une liste vide
        print('Erreur lors de la conversion de favoriteMovies: $e');
        favoriteMoviesList = [];
      }
    }

    // Gérer age de manière sécurisée
    // Le champ peut être absent, null, int, ou string
    int userAge = 0;
    if (json['age'] != null) {
      if (json['age'] is int) {
        // Type correct, utiliser directement
        userAge = json['age'];
      } else if (json['age'] is String) {
        // Convertir depuis string si nécessaire
        userAge = int.tryParse(json['age']) ?? 0;
      }
    }

    // Gérer isActive de manière sécurisée
    // Le champ peut être absent, null, bool, ou string
    bool userIsActive = true;
    if (json['isActive'] != null) {
      if (json['isActive'] is bool) {
        // Type correct, utiliser directement
        userIsActive = json['isActive'];
      } else if (json['isActive'] is String) {
        // Convertir depuis string si nécessaire
        userIsActive = json['isActive'].toLowerCase() == 'true';
      }
    }

    return AppUser(
      id: id,
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      age: userAge,
      photoUrl: json['photoUrl']?.toString(),
      role: json['role']?.toString() ?? 'user',
      isActive: userIsActive,
      favoriteMovies: favoriteMoviesList,
    );
  }

  /// Convertit une instance AppUser en JSON pour Firestore
  /// 
  /// Cette méthode est utilisée pour :
  /// - Sauvegarder un utilisateur dans Firestore
  /// - Mettre à jour les données utilisateur
  /// 
  /// Retourne un Map avec tous les champs de l'utilisateur
  /// Note : L'ID n'est pas inclus car c'est l'ID du document Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
      'favoriteMovies': favoriteMovies,
    };
  }

  /// Vérifie si l'utilisateur est administrateur
  /// 
  /// Retourne true si role == 'admin', false sinon
  /// Utilisée pour afficher/masquer les fonctionnalités admin
  bool get isAdmin => role == 'admin';

  /// Retourne le nom complet de l'utilisateur
  /// 
  /// Format : "Prénom Nom"
  /// Utilisée pour l'affichage dans l'interface
  String get fullName => '$firstName $lastName';

  /// Crée une copie de l'utilisateur avec des modifications optionnelles
  /// 
  /// Cette méthode permet de créer une nouvelle instance AppUser
  /// en modifiant seulement certains champs, sans toucher aux autres.
  /// 
  /// Exemple :
  /// ```dart
  /// final updatedUser = user.copyWith(age: 26, role: 'admin');
  /// ```
  /// 
  /// Si un paramètre est null, la valeur originale est conservée
  AppUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? photoUrl,
    String? role,
    bool? isActive,
    List<String>? favoriteMovies,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      favoriteMovies: favoriteMovies ?? this.favoriteMovies,
    );
  }
}

