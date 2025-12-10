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

/// Classe AppUser : Modèle de données pour un utilisateur
/// 
/// Cette classe est immuable (tous les champs sont final) pour garantir
/// l'intégrité des données. Pour modifier un utilisateur, utiliser copyWith().
class AppUser {
  /// Identifiant unique de l'utilisateur (UID Firebase Auth)
  /// 
  /// Cet ID correspond à l'UID généré par Firebase Authentication lors de l'inscription.
  /// Il est utilisé comme ID du document dans Firestore (collection "users").
  /// 
  /// Type : String (non nullable, toujours présent)
  final String id; // Identifiant unique Firebase Auth (requis)
  
  /// Adresse email de l'utilisateur
  /// 
  /// Email utilisé pour l'authentification et la communication.
  /// Doit être unique dans la base de données.
  /// 
  /// Type : String (non nullable, toujours présent)
  final String email; // Email de l'utilisateur (requis)
  
  /// Prénom de l'utilisateur
  /// 
  /// Prénom affiché dans l'interface utilisateur.
  /// Utilisé pour l'affichage du profil et les messages personnalisés.
  /// 
  /// Type : String (non nullable, peut être vide "")
  final String firstName; // Prénom de l'utilisateur (requis)
  
  /// Nom de famille de l'utilisateur
  /// 
  /// Nom de famille affiché dans l'interface utilisateur.
  /// Utilisé avec firstName pour former le nom complet.
  /// 
  /// Type : String (non nullable, peut être vide "")
  final String lastName; // Nom de famille de l'utilisateur (requis)
  
  /// Âge de l'utilisateur (0 si non spécifié)
  /// 
  /// Âge en années. Si non spécifié, vaut 0.
  /// Utilisé pour le matching et l'affichage du profil.
  /// 
  /// Type : int (non nullable, 0 par défaut si non spécifié)
  final int age; // Âge de l'utilisateur (requis, peut être 0)
  
  /// URL de la photo de profil (null si aucune photo)
  /// 
  /// URL complète de l'image stockée dans Firebase Storage.
  /// Si null, l'interface affiche une initiale ou une icône par défaut.
  /// 
  /// Type : String? (nullable, optionnel)
  final String? photoUrl; // URL de la photo de profil (optionnel, peut être null)
  
  /// Rôle de l'utilisateur : 'admin' ou 'user'
  /// 
  /// Détermine les permissions dans l'application :
  /// - 'admin' : Accès à l'interface d'administration
  /// - 'user' : Utilisateur standard (par défaut)
  /// 
  /// Type : String (non nullable, 'user' par défaut)
  final String role; // Rôle de l'utilisateur (optionnel, 'user' par défaut)
  
  /// Statut actif/désactivé de l'utilisateur
  /// 
  /// Un utilisateur désactivé (isActive = false) ne peut plus se connecter.
  /// Utilisé par les administrateurs pour gérer les comptes.
  /// 
  /// Type : bool (non nullable, true par défaut)
  final bool isActive; // Statut actif/désactivé (optionnel, true par défaut)
  
  /// Liste des IDs des films favoris de l'utilisateur
  /// 
  /// Liste des identifiants (String) des films ajoutés aux favoris.
  /// Utilisée pour :
  /// - Afficher la liste des favoris
  /// - Calculer le matching avec d'autres utilisateurs
  /// 
  /// Type : List<String> (non nullable, liste vide par défaut)
  final List<String> favoriteMovies; // Liste des IDs des films favoris (optionnel, [] par défaut)

  /// Constructeur du modèle AppUser
  /// 
  /// Crée une nouvelle instance AppUser avec les paramètres fournis.
  /// 
  /// Paramètres :
  /// - [id] : UID Firebase Auth (requis, non nullable)
  /// - [email] : Email de l'utilisateur (requis, non nullable)
  /// - [firstName] : Prénom (requis, non nullable, peut être vide)
  /// - [lastName] : Nom (requis, non nullable, peut être vide)
  /// - [age] : Âge (requis, non nullable, peut être 0)
  /// - [photoUrl] : URL de la photo (optionnel, nullable)
  /// - [role] : Rôle par défaut 'user' (optionnel, 'user' si non fourni)
  /// - [isActive] : Statut actif par défaut true (optionnel, true si non fourni)
  /// - [favoriteMovies] : Liste des favoris (optionnel, [] si non fourni)
  /// 
  /// Initialisation de favoriteMovies :
  /// Si favoriteMovies est null, utilise une liste vide [].
  /// Sinon, utilise la liste fournie.
  AppUser({
    required this.id, // ID Firebase Auth (obligatoire)
    required this.email, // Email (obligatoire)
    required this.firstName, // Prénom (obligatoire)
    required this.lastName, // Nom (obligatoire)
    required this.age, // Âge (obligatoire)
    this.photoUrl, // URL photo (optionnel, peut être null)
    this.role = 'user', // Rôle (optionnel, 'user' par défaut)
    this.isActive = true, // Statut actif (optionnel, true par défaut)
    List<String>? favoriteMovies, // Liste favoris (optionnel, nullable)
  }) : favoriteMovies = favoriteMovies ?? []; // Initialiser favoriteMovies : liste fournie ou [] si null

  /// Factory constructor : Crée une instance AppUser à partir d'un JSON Firestore
  /// 
  /// Cette méthode désérialise les données JSON depuis Firestore en créant
  /// une instance AppUser. Elle gère de manière sécurisée :
  /// - Les conversions de types (age peut être int ou String)
  /// - Les valeurs nulles ou manquantes (utilise des valeurs par défaut)
  /// - Les erreurs de parsing (favoriteMovies peut être de différents types)
  /// 
  /// Paramètres :
  /// - [json] : Map<String, dynamic> contenant les données Firestore
  /// - [id] : String ID du document Firestore (UID utilisateur)
  /// 
  /// Retourne : Une instance AppUser avec des valeurs par défaut si des champs sont absents
  /// 
  /// Gestion des erreurs :
  /// - Si favoriteMovies ne peut pas être parsé, utilise une liste vide
  /// - Si age n'est pas un int, essaie de le convertir depuis String
  /// - Si isActive n'est pas un bool, essaie de le convertir depuis String
  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    // ========== GESTION DE favoriteMovies ==========
    // Le champ favoriteMovies peut être absent, null, ou de type différent dans Firestore
    // Il faut le gérer de manière sécurisée pour éviter les erreurs de type
    
    // Initialiser une liste vide par défaut
    List<String> favoriteMoviesList = []; // Liste vide par défaut
    
    // Vérifier si le champ favoriteMovies existe et n'est pas null
    if (json['favoriteMovies'] != null) {
      // Bloc try-catch pour gérer les erreurs de conversion
      try {
        // Récupérer les données brutes du champ favoriteMovies
        final favoriteMoviesData = json['favoriteMovies']; // Données brutes depuis JSON
        
        // Vérifier que c'est bien une liste (peut être List<dynamic>, List<String>, etc.)
        if (favoriteMoviesData is List) {
          // Convertir chaque élément en string et filtrer les vides
          // map() : Transforme chaque élément de la liste
          // item?.toString() ?? '' : Convertit en string, ou '' si null
          // where() : Filtre les éléments vides
          // toList() : Convertit l'itérable en liste
          favoriteMoviesList = favoriteMoviesData
              .map((item) => item?.toString() ?? '') // Convertir chaque élément en string
              .where((item) => item.isNotEmpty) // Filtrer les chaînes vides
              .toList(); // Convertir en liste finale
        }
      } catch (e) {
        // En cas d'erreur de conversion, utiliser une liste vide
        // print() : Affiche l'erreur dans la console pour le débogage
        print('Erreur lors de la conversion de favoriteMovies: $e'); // Log de l'erreur
        favoriteMoviesList = []; // Utiliser une liste vide en cas d'erreur
      }
    }

    // ========== GESTION DE age ==========
    // Le champ age peut être absent, null, int, ou string dans Firestore
    // Il faut le gérer de manière sécurisée
    
    // Initialiser à 0 par défaut
    int userAge = 0; // Âge par défaut : 0
    
    // Vérifier si le champ age existe et n'est pas null
    if (json['age'] != null) {
      // Vérifier le type de la valeur
      if (json['age'] is int) {
        // Type correct (int), utiliser directement
        userAge = json['age']; // Assigner directement la valeur int
      } else if (json['age'] is String) {
        // Type string, convertir en int
        // int.tryParse() : Essaie de convertir la string en int
        // ?? 0 : Si la conversion échoue, utiliser 0
        userAge = int.tryParse(json['age']) ?? 0; // Convertir depuis string ou 0
      }
    }

    // ========== GESTION DE isActive ==========
    // Le champ isActive peut être absent, null, bool, ou string dans Firestore
    // Il faut le gérer de manière sécurisée
    
    // Initialiser à true par défaut (utilisateur actif par défaut)
    bool userIsActive = true; // Statut actif par défaut : true
    
    // Vérifier si le champ isActive existe et n'est pas null
    if (json['isActive'] != null) {
      // Vérifier le type de la valeur
      if (json['isActive'] is bool) {
        // Type correct (bool), utiliser directement
        userIsActive = json['isActive']; // Assigner directement la valeur bool
      } else if (json['isActive'] is String) {
        // Type string, convertir en bool
        // toLowerCase() : Convertir en minuscules pour la comparaison
        // == 'true' : Comparer avec la string 'true'
        userIsActive = json['isActive'].toLowerCase() == 'true'; // Convertir depuis string
      }
    }

    // Créer et retourner une instance AppUser avec les données parsées
    return AppUser(
      id: id, // ID du document Firestore (passé en paramètre)
      // email : Convertir en string, ou '' si null
      email: json['email']?.toString() ?? '', // Email ou chaîne vide
      // firstName : Convertir en string, ou '' si null
      firstName: json['firstName']?.toString() ?? '', // Prénom ou chaîne vide
      // lastName : Convertir en string, ou '' si null
      lastName: json['lastName']?.toString() ?? '', // Nom ou chaîne vide
      age: userAge, // Âge parsé (0 si absent ou invalide)
      // photoUrl : Convertir en string, ou null si absent
      photoUrl: json['photoUrl']?.toString(), // URL photo ou null
      // role : Convertir en string, ou 'user' par défaut
      role: json['role']?.toString() ?? 'user', // Rôle ou 'user' par défaut
      isActive: userIsActive, // Statut actif parsé (true par défaut)
      favoriteMovies: favoriteMoviesList, // Liste des favoris parsée ([] par défaut)
    );
  }

  /// Méthode toJson : Convertit une instance AppUser en JSON pour Firestore
  /// 
  /// Cette méthode sérialise l'instance AppUser en Map<String, dynamic>
  /// pour pouvoir l'enregistrer dans Firestore.
  /// 
  /// Utilisée pour :
  /// - Sauvegarder un utilisateur dans Firestore (createOrUpdateUser)
  /// - Mettre à jour les données utilisateur (update)
  /// 
  /// Retourne : Un Map<String, dynamic> avec tous les champs de l'utilisateur
  /// 
  /// Note : L'ID n'est pas inclus car c'est l'ID du document Firestore lui-même
  /// (pas un champ du document)
  Map<String, dynamic> toJson() {
    // Retourner un Map avec tous les champs de l'utilisateur
    return {
      'email': email, // Email de l'utilisateur
      'firstName': firstName, // Prénom
      'lastName': lastName, // Nom
      'age': age, // Âge
      'photoUrl': photoUrl, // URL photo (peut être null)
      'role': role, // Rôle (admin ou user)
      'isActive': isActive, // Statut actif/désactivé
      'favoriteMovies': favoriteMovies, // Liste des IDs des films favoris
    };
  }

  /// Getter isAdmin : Vérifie si l'utilisateur est administrateur
  /// 
  /// Cette méthode retourne true si le rôle de l'utilisateur est 'admin',
  /// false sinon.
  /// 
  /// Utilisée pour :
  /// - Afficher/masquer les fonctionnalités admin dans l'interface
  /// - Vérifier les permissions avant certaines actions
  /// 
  /// Retourne : bool (true si admin, false sinon)
  bool get isAdmin => role == 'admin'; // Retourner true si role == 'admin'

  /// Getter fullName : Retourne le nom complet de l'utilisateur
  /// 
  /// Cette méthode combine firstName et lastName pour former le nom complet.
  /// 
  /// Format : "Prénom Nom"
  /// 
  /// Utilisée pour :
  /// - L'affichage dans l'interface utilisateur
  /// - Les messages personnalisés
  /// 
  /// Retourne : String (nom complet)
  String get fullName => '$firstName $lastName'; // Concaténer prénom et nom

  /// Méthode copyWith : Crée une copie de l'utilisateur avec des modifications optionnelles
  /// 
  /// Cette méthode permet de créer une nouvelle instance AppUser
  /// en modifiant seulement certains champs, sans toucher aux autres.
  /// 
  /// Pattern : Immutability (immuabilité)
  /// Au lieu de modifier l'instance existante, on crée une nouvelle instance
  /// avec les modifications souhaitées.
  /// 
  /// Exemple d'utilisation :
  /// ```dart
  /// final updatedUser = user.copyWith(age: 26, role: 'admin');
  /// ```
  /// 
  /// Paramètres :
  /// Tous les paramètres sont optionnels (nullable).
  /// Si un paramètre est null, la valeur originale est conservée.
  /// Si un paramètre est fourni, la nouvelle valeur est utilisée.
  /// 
  /// Retourne : Une nouvelle instance AppUser avec les modifications appliquées
  AppUser copyWith({
    String? id, // Nouvel ID (optionnel)
    String? email, // Nouvel email (optionnel)
    String? firstName, // Nouveau prénom (optionnel)
    String? lastName, // Nouveau nom (optionnel)
    int? age, // Nouvel âge (optionnel)
    String? photoUrl, // Nouvelle URL photo (optionnel)
    String? role, // Nouveau rôle (optionnel)
    bool? isActive, // Nouveau statut actif (optionnel)
    List<String>? favoriteMovies, // Nouvelle liste favoris (optionnel)
  }) {
    // Créer une nouvelle instance AppUser
    return AppUser(
      // Utiliser la nouvelle valeur si fournie, sinon conserver l'ancienne
      // ?? : Opérateur null-coalescing (utilise la valeur de droite si gauche est null)
      id: id ?? this.id, // Nouvel ID ou ID actuel
      email: email ?? this.email, // Nouvel email ou email actuel
      firstName: firstName ?? this.firstName, // Nouveau prénom ou prénom actuel
      lastName: lastName ?? this.lastName, // Nouveau nom ou nom actuel
      age: age ?? this.age, // Nouvel âge ou âge actuel
      photoUrl: photoUrl ?? this.photoUrl, // Nouvelle URL ou URL actuelle
      role: role ?? this.role, // Nouveau rôle ou rôle actuel
      isActive: isActive ?? this.isActive, // Nouveau statut ou statut actuel
      favoriteMovies: favoriteMovies ?? this.favoriteMovies, // Nouvelle liste ou liste actuelle
    );
  }
}
