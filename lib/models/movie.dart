/// Modèle de données représentant un film dans l'application
/// 
/// Cette classe encapsule toutes les informations d'un film :
/// - Identifiant unique
/// - Informations de base (titre, description)
/// - Métadonnées (note, année, genre, réalisateur)
/// - URL de l'affiche
/// 
/// Utilisée pour :
/// - Stocker les films depuis Firestore
/// - Parser les données de l'API TMDb
/// - Afficher les films dans l'interface
class Movie {
  /// Identifiant unique du film (peut être un ID TMDb ou un ID Firestore)
  final String id;
  
  /// Titre du film
  final String title;
  
  /// Description/résumé du film
  final String description;
  
  /// URL de l'affiche du film
  final String imageUrl;
  
  /// Note du film sur 10 (peut être 0 si non spécifiée)
  final double rating;
  
  /// Année de sortie du film
  final int year;
  
  /// Genre(s) du film (ex: "Action, Thriller")
  final String genre;
  
  /// Nom du réalisateur
  final String director;

  /// Constructeur du modèle Movie
  /// 
  /// Tous les paramètres sont requis pour garantir l'intégrité des données
  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.year,
    required this.genre,
    required this.director,
  });

  /// Crée une instance Movie à partir d'un JSON (Firestore ou API)
  /// 
  /// Cette méthode est utilisée pour :
  /// - Désérialiser les données depuis Firestore
  /// - Parser les réponses de l'API TMDb
  /// 
  /// Utilise des valeurs par défaut si certains champs sont absents
  /// pour éviter les erreurs de parsing
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      year: json['year'] ?? 0,
      genre: json['genre'] ?? '',
      director: json['director'] ?? '',
    );
  }

  /// Convertit une instance Movie en JSON pour Firestore
  /// 
  /// Cette méthode est utilisée pour :
  /// - Sauvegarder un film dans Firestore
  /// - Envoyer des données à l'API
  /// 
  /// Retourne un Map avec tous les champs du film
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'year': year,
      'genre': genre,
      'director': director,
    };
  }
}

