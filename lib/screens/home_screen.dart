/// Écran d'accueil principal de l'application
/// 
/// Fonctionnalités :
/// - Affichage de tous les films avec recherche
/// - Liste des films favoris
/// - Matching avec d'autres utilisateurs
/// - Interface administrateur (si admin)
/// - Navigation vers les détails d'un film
/// - Déconnexion
/// 
/// Structure :
/// - Utilise un TabBar avec plusieurs onglets :
///   1. Films : Liste de tous les films + recherche
///   2. Favoris : Liste des films favoris de l'utilisateur
///   3. Matching : Utilisateurs avec goûts similaires
///   4. Admin : Interface admin (visible uniquement si admin)
/// 
/// Chargement des données :
/// - Films : Depuis MovieService (Firestore + API)
/// - Favoris : Depuis Firestore (liste favoriteMovies)
/// - Données utilisateur : Depuis Firestore (profil + statut admin)
/// 
/// Gestion de l'état :
/// - État de chargement pour chaque section
/// - Rafraîchissement automatique après retour de MovieDetailScreen

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../services/movie_service.dart';
import '../services/firestore_service.dart';
import 'movie_detail_screen.dart';
import 'login_screen.dart';
import 'admin_screen.dart';
import 'matching_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Classe d'état pour HomeScreen
/// 
/// Cette classe gère l'état mutable de l'écran d'accueil.
/// Elle hérite de State<HomeScreen> et implémente SingleTickerProviderStateMixin
/// pour utiliser un TabController (nécessaire pour les onglets).
/// 
/// SingleTickerProviderStateMixin : Fournit un Ticker pour animer le TabController
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // ========== SERVICES ==========
  
  /// Service pour récupérer les films depuis Firestore et l'API externe (TMDb)
  /// 
  /// Ce service combine les films depuis plusieurs sources :
  /// - Firestore : Films ajoutés manuellement par les administrateurs
  /// - API TMDb : Films populaires récupérés depuis l'API externe
  /// - Films de démonstration : Fallback si aucune autre source n'est disponible
  /// 
  /// Instance finale (ne change jamais après l'initialisation)
  final MovieService _movieService = MovieService();
  
  /// Service pour gérer les données Firestore (utilisateurs, favoris, matching)
  /// 
  /// Ce service centralise toutes les opérations de base de données :
  /// - Récupération des données utilisateur
  /// - Gestion des films favoris (ajout/retrait)
  /// - Calcul du matching entre utilisateurs
  /// 
  /// Instance finale (ne change jamais après l'initialisation)
  final FirestoreService _firestoreService = FirestoreService();
  
  // ========== ÉTAT DE L'INTERFACE ==========
  
  /// Liste de tous les films disponibles dans l'application
  /// 
  /// Cette liste est remplie lors du chargement initial depuis MovieService.
  /// Elle contient tous les films (Firestore + API + démo).
  /// 
  /// Initialisée à une liste vide [] au démarrage
  List<Movie> _movies = [];
  
  /// Liste des films filtrés selon la recherche de l'utilisateur
  /// 
  /// Cette liste est mise à jour à chaque changement dans le champ de recherche.
  /// Si la recherche est vide, elle contient tous les films (_movies).
  /// Sinon, elle contient uniquement les films correspondant à la recherche.
  /// 
  /// Initialisée à une liste vide [] au démarrage
  List<Movie> _filteredMovies = [];
  
  /// Liste des films favoris de l'utilisateur actuel
  /// 
  /// Cette liste est remplie depuis Firestore en récupérant les IDs des favoris
  /// puis en chargeant les détails de chaque film depuis MovieService.
  /// 
  /// Initialisée à une liste vide [] au démarrage
  List<Movie> _favoriteMovies = [];
  
  /// Indicateur de chargement pour la liste principale des films
  /// 
  /// true : Les films sont en cours de chargement (afficher un spinner)
  /// false : Les films sont chargés (afficher la liste)
  /// 
  /// Initialisé à true car on charge les films au démarrage
  bool _isLoading = true;
  
  /// Indicateur de chargement pour la liste des favoris
  /// 
  /// true : Les favoris sont en cours de chargement (afficher un spinner)
  /// false : Les favoris sont chargés (afficher la liste ou message vide)
  /// 
  /// Initialisé à false car on charge les favoris après les données utilisateur
  bool _isLoadingFavorites = false;
  
  /// Contrôleur pour le champ de recherche de films
  /// 
  /// Ce contrôleur gère le texte saisi dans le champ de recherche.
  /// Il a un listener (_onSearchChanged) qui se déclenche à chaque modification.
  /// 
  /// Instance finale (créée une seule fois et réutilisée)
  final TextEditingController _searchController = TextEditingController();
  
  /// Utilisateur Firebase Auth actuellement connecté
  /// 
  /// Récupéré depuis FirebaseAuth.instance.currentUser.
  /// Peut être null si aucun utilisateur n'est connecté.
  /// 
  /// Instance finale (ne change pas après l'initialisation)
  final User? _user = FirebaseAuth.instance.currentUser;
  
  /// Données utilisateur complètes depuis Firestore
  /// 
  /// Contient toutes les informations de l'utilisateur (nom, prénom, âge, photo, etc.)
  /// Récupéré depuis Firestore via FirestoreService.getUserById().
  /// 
  /// Peut être null si le profil n'existe pas encore dans Firestore.
  AppUser? _appUser;
  
  /// Indicateur si l'utilisateur actuel est administrateur
  /// 
  /// true : L'utilisateur a le rôle "admin" dans Firestore
  /// false : L'utilisateur a le rôle "user" (par défaut)
  /// 
  /// Utilisé pour afficher/masquer l'onglet Admin dans le TabBar.
  /// 
  /// Initialisé à false par défaut
  bool _isAdmin = false;
  
  /// Contrôleur pour gérer les onglets (Films, Favoris, Matching, Admin)
  /// 
  /// Ce contrôleur gère la navigation entre les différents onglets.
  /// Il est initialisé avec 4 onglets (le dernier est masqué si pas admin).
  /// 
  /// late : Initialisé dans initState(), pas à la déclaration
  late TabController _tabController;

  /// Méthode initState : Appelée une seule fois lors de la création du widget
  /// 
  /// Cette méthode est appelée automatiquement par Flutter après la création du widget.
  /// Elle est utilisée pour initialiser les données et les services.
  /// 
  /// Ordre d'exécution :
  /// 1. Appeler super.initState() (obligatoire)
  /// 2. Initialiser le TabController
  /// 3. Charger les données utilisateur (avec délai pour éviter les erreurs Firebase)
  /// 4. Charger les films
  /// 5. Ajouter un listener au champ de recherche
  @override
  void initState() {
    // Appeler super.initState() est OBLIGATOIRE
    // Cette méthode initialise l'état du widget parent (State<HomeScreen>)
    super.initState();
    
    // Initialiser le TabController pour gérer les onglets
    // Cette méthode configure le contrôleur avec 4 onglets
    _initializeTabController();
    
    // Délayer le chargement des données utilisateur pour éviter les erreurs Firebase
    // 
    // Problème : Firebase peut avoir des erreurs internes (PigeonUserDetails) si on
    // accède aux données utilisateur trop rapidement après la connexion.
    // 
    // Solution : Attendre 500ms avant de charger les données utilisateur.
    // Cela laisse le temps à Firebase de terminer ses opérations internes.
    // 
    // Future.delayed : Crée un Future qui se complète après le délai spécifié
    // Duration(milliseconds: 500) : Délai de 500 millisecondes (0.5 seconde)
    // () { _loadUserData(); } : Fonction anonyme appelée après le délai
    Future.delayed(const Duration(milliseconds: 500), () {
      // Charger les données utilisateur depuis Firestore
      // Cette méthode récupère le profil complet de l'utilisateur
      _loadUserData();
    });
    
    // Charger immédiatement la liste des films
    // Cette méthode récupère les films depuis Firestore et l'API
    // Elle ne dépend pas de l'utilisateur, donc pas besoin de délai
    _loadMovies();
    
    // Ajouter un listener au contrôleur de recherche
    // Ce listener se déclenche à chaque modification du texte dans le champ de recherche
    // _onSearchChanged est appelée automatiquement à chaque changement
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeTabController() {
    // Toujours initialiser avec 4 onglets (le dernier sera masqué si pas admin)
    _tabController = TabController(length: 4, vsync: this);
    // Écouter les changements pour éviter les erreurs d'index
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Vérifier que l'index est valide
        if (_tabController.index >= _tabController.length) {
          debugPrint('⚠️ Index de tab invalide: ${_tabController.index}');
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      // Utiliser un try-catch avec gestion spécifique de l'erreur PigeonUserDetails
      try {
        debugPrint('Chargement des données utilisateur pour: ${_user!.uid}');
        
        // Charger les données utilisateur avec gestion d'erreur spécifique
        AppUser? appUser;
        try {
          appUser = await _firestoreService.getUserById(_user!.uid);
        } catch (e) {
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('pigeonuserdetails') || 
              errorString.contains('list<object?>') ||
              (errorString.contains('type') && errorString.contains('subtype'))) {
            debugPrint('Erreur Firebase interne lors du chargement utilisateur (ignorée): $e');
            // Continuer avec un utilisateur null, on créera un profil minimal
          } else {
            rethrow; // Relancer les autres erreurs
          }
        }
        
        if (mounted) {
          setState(() {
            _appUser = appUser;
            // Définir isAdmin basé sur le rôle de l'utilisateur si disponible
            _isAdmin = appUser?.isAdmin ?? false;
          });
        }
        
        // Charger le statut admin séparément pour éviter les erreurs
        if (appUser == null) {
          try {
            final isAdmin = await _firestoreService.isCurrentUserAdmin();
            if (mounted) {
              setState(() {
                _isAdmin = isAdmin;
              });
            }
          } catch (adminError) {
            final errorString = adminError.toString().toLowerCase();
            if (!errorString.contains('pigeonuserdetails') && 
                !errorString.contains('list<object?>')) {
              debugPrint('Erreur lors de la vérification du statut admin: $adminError');
            }
            // Ne pas bloquer si la vérification admin échoue
          }
        }
        
        // Charger les favoris même si appUser est null (on peut avoir des favoris sans profil complet)
        if (mounted && _user != null) {
          // Délayer légèrement le chargement des favoris pour éviter les conflits
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _loadFavoriteMovies();
            }
          });
        }
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('pigeonuserdetails') || 
            errorString.contains('list<object?>') ||
            (errorString.contains('type') && errorString.contains('subtype'))) {
          debugPrint('Erreur Firebase interne ignorée: $e');
          // Continuer avec un profil minimal
        } else {
          debugPrint('Erreur lors du chargement des données utilisateur: $e');
          debugPrint('Type d\'erreur: ${e.runtimeType}');
        }
        
        // Si le profil n'existe pas encore, créer un profil minimal
        if (_appUser == null && _user != null) {
          try {
            debugPrint('Création d\'un profil minimal pour: ${_user!.uid}');
            final appUser = AppUser(
              id: _user!.uid,
              email: _user!.email ?? '',
              firstName: 'Utilisateur',
              lastName: '',
              age: 0,
              role: 'user',
              isActive: true,
            );
            await _firestoreService.createOrUpdateUser(appUser);
            if (mounted) {
              setState(() {
                _appUser = appUser;
                _isAdmin = false;
              });
            }
          } catch (createError) {
            final errorString = createError.toString().toLowerCase();
            if (!errorString.contains('pigeonuserdetails') && 
                !errorString.contains('list<object?>')) {
              debugPrint('Erreur lors de la création du profil minimal: $createError');
            }
            // Même si la création échoue, on peut continuer avec un utilisateur minimal
            if (mounted && _appUser == null) {
              setState(() {
                _appUser = AppUser(
                  id: _user!.uid,
                  email: _user!.email ?? '',
                  firstName: 'Utilisateur',
                  lastName: '',
                  age: 0,
                  role: 'user',
                  isActive: true,
                );
                _isAdmin = false;
              });
            }
          }
        }
      }
    }
  }

  void _loadMovies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final movies = await _movieService.getMovies();
      setState(() {
        _movies = movies;
        _filteredMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des films: $e')),
        );
      }
    }
  }

  Future<void> _loadFavoriteMovies() async {
    if (_user == null) {
      setState(() {
        _favoriteMovies = [];
        _isLoadingFavorites = false;
      });
      return;
    }

    setState(() {
      _isLoadingFavorites = true;
    });

    try {
      debugPrint('🔄 Chargement des favoris pour: ${_user!.uid}');
      final favoriteIds = await _firestoreService.getFavoriteMovies(_user!.uid);
      debugPrint('📋 IDs de favoris récupérés: $favoriteIds');
      
      final favorites = <Movie>[];

      for (final id in favoriteIds) {
        try {
          final movie = await _movieService.getMovieById(id);
          if (movie != null) {
            favorites.add(movie);
            debugPrint('✅ Film trouvé: ${movie.title} (ID: $id)');
          } else {
            debugPrint('⚠️ Film non trouvé pour l\'ID: $id');
          }
        } catch (e) {
          debugPrint('❌ Erreur lors de la récupération du film $id: $e');
        }
      }

      debugPrint('✅ Total de ${favorites.length} films favoris chargés');
      
      if (mounted) {
        setState(() {
          _favoriteMovies = favorites;
          _isLoadingFavorites = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des favoris: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des favoris: $e'),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _loadFavoriteMovies,
            ),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _filteredMovies = _movies;
      });
    } else {
      _movieService.searchMovies(query).then((results) {
        setState(() {
          _filteredMovies = results;
        });
      });
    }
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ Déconnexion réussie');
      if (mounted) {
        // Utiliser pushNamedAndRemoveUntil pour nettoyer complètement la pile de navigation
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
        );
      }
    }
  }

  Widget _buildMovieList(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun film trouvé',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(movie: movie),
                ),
              );
              // Recharger les favoris après retour de la page de détails
              if (_user != null) {
                _loadFavoriteMovies();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du film
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie.imageUrl,
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.movie,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Informations du film
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.rating.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${movie.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.genre,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.movie), text: 'Films'),
            const Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
            const Tab(icon: Icon(Icons.people), text: 'Matching'),
            Tab(
              icon: const Icon(Icons.admin_panel_settings),
              text: 'Admin',
              // Masquer visuellement si pas admin mais garder l'onglet
            ),
          ],
        ),
        actions: [
          if (_appUser != null && _appUser!.photoUrl != null)
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(_appUser!.photoUrl!),
            )
          else if (_appUser != null)
            CircleAvatar(
              radius: 18,
              child: Text(
                _appUser!.firstName.isNotEmpty 
                    ? _appUser!.firstName[0].toUpperCase()
                    : _appUser!.email.isNotEmpty
                        ? _appUser!.email[0].toUpperCase()
                        : 'U',
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Films
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un film...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
              if (_user != null && _appUser != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bienvenue, ${_appUser!.firstName} ${_appUser!.lastName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMovieList(_filteredMovies),
              ),
            ],
          ),
          // Onglet Favoris
          Column(
            children: [
              if (_favoriteMovies.isEmpty && !_isLoadingFavorites)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun film favori',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez des films à vos favoris depuis leur page de détails',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: _isLoadingFavorites
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMovieList(_favoriteMovies),
                ),
            ],
          ),
          // Onglet Matching
          MatchingScreen(
            userId: _user?.uid ?? '',
            firestoreService: _firestoreService,
          ),
          // Onglet Admin (afficher seulement si admin, sinon écran vide)
          _isAdmin
              ? AdminScreen(
                  movieService: _movieService,
                  firestoreService: _firestoreService,
                  onMoviesUpdated: _loadMovies,
                )
              : const Center(
                  child: Text('Accès réservé aux administrateurs'),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
