/// Écran d'administration de l'application
/// 
/// Accessible uniquement aux utilisateurs avec role = "admin" dans Firestore
/// 
/// Fonctionnalités :
/// - Ajouter des films manuellement à la base de données
/// - Gérer les utilisateurs (voir tous les utilisateurs)
/// - Activer/Désactiver des utilisateurs
/// 
/// Structure :
/// - Utilise un TabBar avec 2 onglets :
///   1. Ajouter un film : Formulaire pour ajouter un nouveau film
///   2. Gérer les utilisateurs : Liste de tous les utilisateurs avec actions
/// 
/// Actions disponibles :
/// - Ajouter un film : Crée un document dans la collection "movies"
/// - Activer/Désactiver : Modifie le champ isActive d'un utilisateur
/// 
/// Note : Un utilisateur désactivé ne peut plus se connecter à l'application

// Import du package Flutter Material pour les widgets UI (Scaffold, AppBar, Dialog, etc.)
import 'package:flutter/material.dart';
// Import du modèle Movie pour créer des instances de films
import '../models/movie.dart';
// Import du modèle AppUser pour gérer les utilisateurs
import '../models/user.dart';
// Import du service MovieService pour gérer les films
import '../services/movie_service.dart';
// Import du service FirestoreService pour les opérations de base de données
import '../services/firestore_service.dart';

/// Widget StatefulWidget pour l'écran d'administration
/// 
/// Ce widget est un StatefulWidget car il doit gérer un état (liste des utilisateurs, onglets).
/// Il est accessible uniquement aux administrateurs (vérifié dans HomeScreen).
class AdminScreen extends StatefulWidget {
  /// Service pour gérer les films (récupération, ajout, etc.)
  /// 
  /// Ce service est passé en paramètre depuis HomeScreen pour éviter de créer
  /// plusieurs instances du même service (pattern Singleton).
  final MovieService movieService;
  
  /// Service pour gérer les données Firestore (utilisateurs, films, etc.)
  /// 
  /// Ce service est passé en paramètre depuis HomeScreen pour éviter de créer
  /// plusieurs instances du même service (pattern Singleton).
  final FirestoreService firestoreService;
  
  /// Callback appelé quand un film est ajouté (pour rafraîchir la liste)
  /// 
  /// Cette fonction est appelée après l'ajout réussi d'un film pour mettre à jour
  /// la liste des films dans HomeScreen sans avoir à recharger toute l'application.
  final VoidCallback onMoviesUpdated;

  /// Constructeur constant pour optimiser les performances
  /// 
  /// Paramètres :
  /// - super.key : Clé du widget parent (StatefulWidget)
  /// - required this.movieService : Service de gestion des films (obligatoire)
  /// - required this.firestoreService : Service Firestore (obligatoire)
  /// - required this.onMoviesUpdated : Callback de mise à jour (obligatoire)
  const AdminScreen({
    super.key, // Clé du widget parent, passée au constructeur parent
    required this.movieService, // Service de gestion des films (obligatoire)
    required this.firestoreService, // Service Firestore (obligatoire)
    required this.onMoviesUpdated, // Callback de mise à jour (obligatoire)
  });

  /// Méthode createState : Crée l'état associé à ce widget
  /// 
  /// Cette méthode est appelée automatiquement par Flutter pour créer l'objet State
  /// qui gère l'état mutable de ce widget.
  /// 
  /// Retourne : Une instance de _AdminScreenState qui gère l'état de ce widget
  @override
  State<AdminScreen> createState() => _AdminScreenState(); // Créer et retourner l'état du widget
}

/// Classe d'état pour AdminScreen
/// 
/// Cette classe gère l'état mutable du widget AdminScreen.
/// Elle hérite de State<AdminScreen> et implémente SingleTickerProviderStateMixin
/// pour utiliser un TabController (nécessaire pour les onglets).
/// 
/// SingleTickerProviderStateMixin : Fournit un Ticker pour animer le TabController
class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  /// Contrôleur pour gérer les onglets (Ajouter un film, Gérer les utilisateurs)
  /// 
  /// Ce contrôleur gère la navigation entre les différents onglets.
  /// Il est initialisé avec 2 onglets dans initState().
  /// 
  /// late : Initialisé dans initState(), pas à la déclaration
  late TabController _tabController; // Contrôleur pour les onglets (initialisé dans initState)
  
  /// Liste de tous les utilisateurs de l'application
  /// 
  /// Cette liste est remplie lors du chargement initial depuis Firestore.
  /// Elle contient tous les utilisateurs (admin et user).
  /// 
  /// Initialisée à une liste vide [] au démarrage
  List<AppUser> _users = []; // Liste vide au démarrage, remplie par _loadUsers()
  
  /// Indicateur de chargement pour la liste des utilisateurs
  /// 
  /// true : Les utilisateurs sont en cours de chargement (afficher un spinner)
  /// false : Les utilisateurs sont chargés (afficher la liste)
  /// 
  /// Initialisé à false car on charge les utilisateurs dans initState()
  bool _isLoadingUsers = false; // Indicateur de chargement (false au démarrage)

  /// Méthode initState : Appelée une seule fois lors de la création du widget
  /// 
  /// Cette méthode est appelée automatiquement par Flutter après la création du widget.
  /// Elle est utilisée pour initialiser les données et les services.
  /// 
  /// Ordre d'exécution :
  /// 1. Appeler super.initState() (obligatoire)
  /// 2. Initialiser le TabController avec 2 onglets
  /// 3. Charger la liste des utilisateurs
  @override
  void initState() {
    // Appeler super.initState() est OBLIGATOIRE
    // Cette méthode initialise l'état du widget parent (State<AdminScreen>)
    super.initState(); // Initialiser l'état du widget parent
    
    // Initialiser le TabController pour gérer les 2 onglets
    // length: 2 : Nombre d'onglets (Ajouter un film, Gérer les utilisateurs)
    // vsync: this : Fournit le Ticker pour les animations (via SingleTickerProviderStateMixin)
    _tabController = TabController(length: 2, vsync: this); // Créer le contrôleur avec 2 onglets
    
    // Charger immédiatement la liste des utilisateurs
    // Cette méthode récupère tous les utilisateurs depuis Firestore
    _loadUsers(); // Charger les utilisateurs depuis Firestore
  }

  /// Méthode asynchrone pour charger tous les utilisateurs depuis Firestore
  /// 
  /// Cette méthode :
  /// 1. Affiche un indicateur de chargement
  /// 2. Récupère tous les utilisateurs depuis Firestore
  /// 3. Met à jour la liste _users
  /// 4. Gère les erreurs avec un message SnackBar
  /// 
  /// Retourne : Future<void> (méthode asynchrone)
  Future<void> _loadUsers() async {
    // Mettre à jour l'état pour afficher l'indicateur de chargement
    // setState() déclenche un rebuild du widget avec les nouvelles valeurs
    setState(() {
      _isLoadingUsers = true; // Activer l'indicateur de chargement
    });

    // Bloc try-catch pour gérer les erreurs potentielles
    try {
      // Récupérer tous les utilisateurs depuis Firestore
      // widget.firestoreService : Accès au service Firestore passé en paramètre
      // getAllUsers() : Méthode qui récupère tous les documents de la collection "users"
      // await : Attendre que la requête Firestore se termine
      final users = await widget.firestoreService.getAllUsers(); // Récupérer tous les utilisateurs
      
      // Mettre à jour l'état avec les utilisateurs récupérés
      setState(() {
        _users = users; // Stocker la liste des utilisateurs
        _isLoadingUsers = false; // Désactiver l'indicateur de chargement
      });
    } catch (e) {
      // En cas d'erreur, désactiver l'indicateur de chargement
      setState(() {
        _isLoadingUsers = false; // Désactiver l'indicateur même en cas d'erreur
      });
      
      // Vérifier que le widget est toujours monté (pas détruit)
      // mounted : Propriété qui indique si le widget est encore dans l'arbre de widgets
      if (mounted) {
        // Afficher un message d'erreur à l'utilisateur
        // ScaffoldMessenger : Gère l'affichage des SnackBar (messages en bas de l'écran)
        // of(context) : Récupère le ScaffoldMessenger associé au contexte
        // showSnackBar() : Affiche un message SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          // SnackBar : Widget qui affiche un message temporaire en bas de l'écran
          SnackBar(content: Text('Erreur lors du chargement des utilisateurs: $e')), // Message d'erreur avec détails
        );
      }
    }
  }

  /// Méthode asynchrone pour afficher le dialogue d'ajout de film
  /// 
  /// Cette méthode :
  /// 1. Crée un dialogue avec un formulaire
  /// 2. Permet de saisir les informations du film
  /// 3. Valide les données (titre requis)
  /// 4. Crée le film dans Firestore
  /// 5. Appelle le callback onMoviesUpdated pour rafraîchir la liste
  /// 
  /// Retourne : Future<void> (méthode asynchrone)
  Future<void> _showAddMovieDialog() async {
    // Créer des contrôleurs pour chaque champ du formulaire
    // TextEditingController : Gère le texte saisi dans un TextField
    final titleController = TextEditingController(); // Contrôleur pour le champ titre
    final descriptionController = TextEditingController(); // Contrôleur pour le champ description
    final imageUrlController = TextEditingController(); // Contrôleur pour le champ URL image
    final ratingController = TextEditingController(); // Contrôleur pour le champ note
    final yearController = TextEditingController(); // Contrôleur pour le champ année
    final genreController = TextEditingController(); // Contrôleur pour le champ genre
    final directorController = TextEditingController(); // Contrôleur pour le champ réalisateur

    // Afficher un dialogue modal (bloque l'interface jusqu'à fermeture)
    // showDialog() : Affiche un dialogue modal
    // context : Contexte du widget (nécessaire pour afficher le dialogue)
    // builder : Fonction qui construit le contenu du dialogue
    await showDialog(
      context: context, // Contexte du widget actuel
      // builder : Fonction appelée pour construire le dialogue
      // (context) => AlertDialog(...) : Fonction anonyme qui retourne un AlertDialog
      builder: (context) => AlertDialog(
        // title : Titre du dialogue (affiché en haut)
        title: const Text('Ajouter un film'), // Texte constant "Ajouter un film"
        // content : Contenu principal du dialogue (le formulaire)
        content: SingleChildScrollView(
          // SingleChildScrollView : Permet de faire défiler le contenu si trop long
          child: Column(
            // Column : Widget qui organise ses enfants verticalement
            mainAxisSize: MainAxisSize.min, // Taille minimale (s'adapte au contenu)
            children: [
              // Liste des widgets enfants (champs du formulaire)
              // Champ Titre
              TextField(
                // TextField : Champ de saisie de texte
                controller: titleController, // Contrôleur qui gère le texte saisi
                decoration: const InputDecoration(
                  // InputDecoration : Style et labels du champ
                  labelText: 'Titre', // Label affiché au-dessus du champ
                  border: OutlineInputBorder(), // Bordure avec contour
                ),
              ),
              // Espacement vertical de 12 pixels entre les champs
              const SizedBox(height: 12), // Espacement de 12 pixels
              // Champ Description
              TextField(
                controller: descriptionController, // Contrôleur pour la description
                decoration: const InputDecoration(
                  labelText: 'Description', // Label "Description"
                  border: OutlineInputBorder(), // Bordure avec contour
                ),
                maxLines: 3, // Permettre 3 lignes de texte (champ multiligne)
              ),
              const SizedBox(height: 12), // Espacement de 12 pixels
              // Champ URL de l'image
              TextField(
                controller: imageUrlController, // Contrôleur pour l'URL de l'image
                decoration: const InputDecoration(
                  labelText: 'URL de l\'image', // Label "URL de l'image"
                  border: OutlineInputBorder(), // Bordure avec contour
                ),
              ),
              const SizedBox(height: 12), // Espacement de 12 pixels
              // Champ Note
              TextField(
                controller: ratingController, // Contrôleur pour la note
                decoration: const InputDecoration(
                  labelText: 'Note (0-10)', // Label "Note (0-10)"
                  border: OutlineInputBorder(), // Bordure avec contour
                ),
                keyboardType: TextInputType.number, // Clavier numérique pour faciliter la saisie
              ),
              const SizedBox(height: 12), // Espacement de 12 pixels
              // Champ Année
              TextField(
                controller: yearController, // Contrôleur pour l'année
                decoration: const InputDecoration(
                  labelText: 'Année', // Label "Année"
                  border: OutlineInputBorder(), // Bordure avec contour
                ),
                keyboardType: TextInputType.number, // Clavier numérique
              ),
              const SizedBox(height: 12), // Espacement de 12 pixels
              // Champ Genre
              TextField(
                controller: genreController, // Contrôleur pour le genre
                decoration: const InputDecoration(
                  labelText: 'Genre', // Label "Genre"
                  border: OutlineInputBorder(), // Bordure avec contour
                ),
              ),
              const SizedBox(height: 12), // Espacement de 12 pixels
              // Champ Réalisateur
              TextField(
                controller: directorController, // Contrôleur pour le réalisateur
                decoration: const InputDecoration(
                  labelText: 'Réalisateur', // Label "Réalisateur"
                  border: OutlineInputBorder(), // Bordure avec contour
                ),
              ),
            ],
          ),
        ),
        // actions : Boutons d'action en bas du dialogue
        actions: [
          // Bouton Annuler
          TextButton(
            // TextButton : Bouton avec texte (style simple)
            onPressed: () => Navigator.pop(context), // Fermer le dialogue sans action
            child: const Text('Annuler'), // Texte du bouton
          ),
          // Bouton Ajouter
          ElevatedButton(
            // ElevatedButton : Bouton avec élévation (style Material Design)
            onPressed: () async {
              // Fonction asynchrone appelée quand on clique sur "Ajouter"
              // Vérifier que le titre n'est pas vide (champ requis)
              if (titleController.text.isEmpty) {
                // Afficher un message d'erreur
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le titre est requis')), // Message d'erreur
                );
                return; // Sortir de la fonction sans créer le film
              }

              // Créer une instance Movie avec les données du formulaire
              final movie = Movie(
                // id : Identifiant unique du film (timestamp en millisecondes)
                id: DateTime.now().millisecondsSinceEpoch.toString(), // ID basé sur le timestamp actuel
                // title : Titre du film (depuis le champ titre)
                title: titleController.text, // Texte saisi dans le champ titre
                // description : Description du film (depuis le champ description)
                description: descriptionController.text, // Texte saisi dans le champ description
                // imageUrl : URL de l'affiche du film
                imageUrl: imageUrlController.text.isEmpty
                    ? 'https://via.placeholder.com/500x750?text=No+Image' // URL par défaut si vide
                    : imageUrlController.text, // URL saisie si non vide
                // rating : Note du film (convertie en double, 0.0 par défaut)
                rating: double.tryParse(ratingController.text) ?? 0.0, // Convertir en double ou 0.0
                // year : Année de sortie (convertie en int, 0 par défaut)
                year: int.tryParse(yearController.text) ?? 0, // Convertir en int ou 0
                // genre : Genre du film (ou "Non spécifié" si vide)
                genre: genreController.text.isEmpty ? 'Non spécifié' : genreController.text, // Genre ou valeur par défaut
                // director : Réalisateur (ou "Non spécifié" si vide)
                director: directorController.text.isEmpty ? 'Non spécifié' : directorController.text, // Réalisateur ou valeur par défaut
              );

              // Bloc try-catch pour gérer les erreurs lors de l'ajout
              try {
                // Ajouter le film dans Firestore
                // widget.firestoreService : Service Firestore passé en paramètre
                // addMovie() : Méthode qui crée un document dans la collection "movies"
                // await : Attendre que l'opération Firestore se termine
                await widget.firestoreService.addMovie(movie); // Ajouter le film dans Firestore
                
                // Vérifier que le widget est toujours monté
                if (mounted) {
                  // Fermer le dialogue
                  Navigator.pop(context); // Fermer le dialogue modal
                  
                  // Appeler le callback pour rafraîchir la liste des films
                  widget.onMoviesUpdated(); // Notifier HomeScreen de mettre à jour la liste
                  
                  // Afficher un message de succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Film ajouté avec succès')), // Message de succès
                  );
                }
              } catch (e) {
                // En cas d'erreur, afficher un message d'erreur
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')), // Message d'erreur avec détails
                  );
                }
              }
            },
            child: const Text('Ajouter'), // Texte du bouton
          ),
        ],
      ),
    );
  }

  /// Méthode asynchrone pour activer/désactiver un utilisateur
  /// 
  /// Cette méthode :
  /// 1. Vérifie si l'utilisateur est actif ou non
  /// 2. Appelle disableUser() ou enableUser() selon l'état
  /// 3. Affiche un message de confirmation
  /// 4. Recharge la liste des utilisateurs
  /// 5. Gère les erreurs avec un message SnackBar
  /// 
  /// Paramètres :
  /// - [user] : L'utilisateur à activer/désactiver
  /// 
  /// Retourne : Future<void> (méthode asynchrone)
  Future<void> _toggleUserStatus(AppUser user) async {
    // Bloc try-catch pour gérer les erreurs potentielles
    try {
      // Vérifier si l'utilisateur est actuellement actif
      if (user.isActive) {
        // Si actif, le désactiver
        // widget.firestoreService : Service Firestore passé en paramètre
        // disableUser() : Méthode qui met isActive à false dans Firestore
        // await : Attendre que l'opération Firestore se termine
        await widget.firestoreService.disableUser(user.id); // Désactiver l'utilisateur
        
        // Vérifier que le widget est toujours monté
        if (mounted) {
          // Afficher un message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            // Message avec le nom complet de l'utilisateur désactivé
            SnackBar(content: Text('${user.firstName} ${user.lastName} a été désactivé')), // Message de confirmation
          );
        }
      } else {
        // Si inactif, l'activer
        // widget.firestoreService : Service Firestore passé en paramètre
        // enableUser() : Méthode qui met isActive à true dans Firestore
        // await : Attendre que l'opération Firestore se termine
        await widget.firestoreService.enableUser(user.id); // Activer l'utilisateur
        
        // Vérifier que le widget est toujours monté
        if (mounted) {
          // Afficher un message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            // Message avec le nom complet de l'utilisateur activé
            SnackBar(content: Text('${user.firstName} ${user.lastName} a été activé')), // Message de confirmation
          );
        }
      }
      // Recharger la liste des utilisateurs pour afficher les changements
      _loadUsers(); // Rafraîchir la liste des utilisateurs
    } catch (e) {
      // En cas d'erreur, afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')), // Message d'erreur avec détails
        );
      }
    }
  }

  /// Méthode build : Construit l'interface utilisateur de ce widget
  /// 
  /// Cette méthode est appelée automatiquement par Flutter quand le widget doit être rendu.
  /// Elle retourne un Column contenant un TabBar et un TabBarView.
  /// 
  /// Paramètres :
  /// - [context] : Le contexte BuildContext qui contient les informations sur l'arbre de widgets
  /// 
  /// Retourne : Un widget Column avec TabBar et TabBarView
  @override
  Widget build(BuildContext context) {
    // Retourner un Column qui organise ses enfants verticalement
    return Column(
      children: [
        // TabBar : Barre d'onglets en haut de l'écran
        TabBar(
          controller: _tabController, // Contrôleur qui gère les onglets
          tabs: const [
            // Premier onglet : Ajouter un film
            Tab(icon: Icon(Icons.add_circle), text: 'Ajouter un film'), // Onglet avec icône et texte
            // Deuxième onglet : Gérer les utilisateurs
            Tab(icon: Icon(Icons.people), text: 'Gérer les utilisateurs'), // Onglet avec icône et texte
          ],
        ),
        // Expanded : Prend tout l'espace disponible restant
        Expanded(
          child: TabBarView(
            // TabBarView : Contenu de chaque onglet (synchronisé avec TabBar)
            controller: _tabController, // Même contrôleur que TabBar
            children: [
              // Contenu du premier onglet : Ajouter un film
              Padding(
                // Padding : Ajoute un espacement de 16 pixels de tous les côtés
                padding: const EdgeInsets.all(16.0), // Espacement de 16 pixels
                child: Column(
                  // Column : Organise ses enfants verticalement
                  mainAxisAlignment: MainAxisAlignment.center, // Centrer verticalement
                  children: [
                    // Icône de film (grande taille)
                    const Icon(
                      Icons.movie_creation, // Icône de création de film
                      size: 80, // Taille de 80 pixels
                      color: Colors.blue, // Couleur bleue
                    ),
                    // Espacement vertical de 20 pixels
                    const SizedBox(height: 20), // Espacement de 20 pixels
                    // Texte titre
                    const Text(
                      'Ajouter un nouveau film', // Texte du titre
                      style: TextStyle(
                        fontSize: 20, // Taille de police 20
                        fontWeight: FontWeight.bold, // Texte en gras
                      ),
                    ),
                    // Espacement vertical de 20 pixels
                    const SizedBox(height: 20), // Espacement de 20 pixels
                    // Bouton pour ouvrir le dialogue d'ajout
                    ElevatedButton.icon(
                      onPressed: _showAddMovieDialog, // Appeler la méthode qui affiche le dialogue
                      icon: const Icon(Icons.add), // Icône "+"
                      label: const Text('Ajouter un film'), // Texte du bouton
                      style: ElevatedButton.styleFrom(
                        // Style personnalisé du bouton
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, // Espacement horizontal de 24 pixels
                          vertical: 12, // Espacement vertical de 12 pixels
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenu du deuxième onglet : Gérer les utilisateurs
              // Opérateur ternaire : Afficher un spinner si chargement, sinon la liste
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator()) // Indicateur de chargement centré
                  : _users.isEmpty
                      ? const Center(
                          // Si aucun utilisateur, afficher un message
                          child: Text('Aucun utilisateur trouvé'), // Message "Aucun utilisateur trouvé"
                        )
                      : ListView.builder(
                          // ListView.builder : Crée une liste défilable optimisée
                          padding: const EdgeInsets.all(16.0), // Espacement de 16 pixels
                          itemCount: _users.length, // Nombre d'éléments dans la liste
                          itemBuilder: (context, index) {
                            // Fonction appelée pour chaque élément de la liste
                            // index : Index de l'élément actuel (0, 1, 2, ...)
                            final user = _users[index]; // Récupérer l'utilisateur à l'index actuel
                            
                            // Retourner une Card pour chaque utilisateur
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12), // Marge en bas de 12 pixels
                              child: ListTile(
                                // ListTile : Widget Material Design pour afficher une ligne de liste
                                leading: CircleAvatar(
                                  // CircleAvatar : Avatar circulaire (photo de profil)
                                  backgroundImage: user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!) // Image depuis l'URL si disponible
                                      : null, // Pas d'image si photoUrl est null
                                  child: user.photoUrl == null
                                      ? Text(
                                          // Afficher l'initiale si pas de photo
                                          user.firstName.isNotEmpty
                                              ? user.firstName[0].toUpperCase() // Première lettre du prénom
                                              : user.email.isNotEmpty
                                                  ? user.email[0].toUpperCase() // Première lettre de l'email
                                                  : 'U', // 'U' par défaut
                                        )
                                      : null, // Pas de texte si photo disponible
                                ),
                                title: Text('${user.firstName} ${user.lastName}'), // Nom complet
                                subtitle: Column(
                                  // Column : Organise les informations verticalement
                                  crossAxisAlignment: CrossAxisAlignment.start, // Aligner à gauche
                                  children: [
                                    Text(user.email), // Email de l'utilisateur
                                    Text(
                                      // Afficher l'âge ou "Non spécifié"
                                      user.age > 0 
                                          ? 'Âge: ${user.age} ans' // Âge si > 0
                                          : 'Âge: Non spécifié', // Message par défaut
                                    ),
                                    Text('Rôle: ${user.role}'), // Rôle (admin ou user)
                                    Text(
                                      // Statut actif/désactivé avec couleur
                                      user.isActive ? 'Actif' : 'Désactivé', // Texte selon l'état
                                      style: TextStyle(
                                        color: user.isActive ? Colors.green : Colors.red, // Vert si actif, rouge si désactivé
                                        fontWeight: FontWeight.bold, // Texte en gras
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  // IconButton : Bouton avec icône à droite
                                  icon: Icon(
                                    // Icône selon l'état (block si actif, check si désactivé)
                                    user.isActive ? Icons.block : Icons.check_circle, // Icône conditionnelle
                                    color: user.isActive ? Colors.red : Colors.green, // Couleur conditionnelle
                                  ),
                                  onPressed: () => _toggleUserStatus(user), // Appeler la méthode de bascule
                                  tooltip: user.isActive
                                      ? 'Désactiver l\'utilisateur' // Tooltip si actif
                                      : 'Activer l\'utilisateur', // Tooltip si désactivé
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ],
    );
  }

  /// Méthode dispose : Appelée quand le widget est détruit
  /// 
  /// Cette méthode est appelée automatiquement par Flutter quand le widget est retiré
  /// de l'arbre de widgets. Elle est utilisée pour libérer les ressources.
  /// 
  /// Actions :
  /// 1. Libérer le TabController (évite les fuites mémoire)
  /// 2. Appeler super.dispose() (obligatoire)
  @override
  void dispose() {
    // Libérer le TabController pour éviter les fuites mémoire
    _tabController.dispose(); // Libérer les ressources du contrôleur
    // Appeler super.dispose() est OBLIGATOIRE
    super.dispose(); // Libérer les ressources du widget parent
  }
}
