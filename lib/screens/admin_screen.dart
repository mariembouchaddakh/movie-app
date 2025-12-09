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

import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../services/movie_service.dart';
import '../services/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  /// Service pour gérer les films
  final MovieService movieService;
  
  /// Service pour gérer les données Firestore
  final FirestoreService firestoreService;
  
  /// Callback appelé quand un film est ajouté (pour rafraîchir la liste)
  final VoidCallback onMoviesUpdated;

  const AdminScreen({
    super.key,
    required this.movieService,
    required this.firestoreService,
    required this.onMoviesUpdated,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _users = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await widget.firestoreService.getAllUsers();
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des utilisateurs: $e')),
        );
      }
    }
  }

  Future<void> _showAddMovieDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final ratingController = TextEditingController();
    final yearController = TextEditingController();
    final genreController = TextEditingController();
    final directorController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un film'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de l\'image',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(
                  labelText: 'Note (0-10)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(
                  labelText: 'Année',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: directorController,
                decoration: const InputDecoration(
                  labelText: 'Réalisateur',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le titre est requis')),
                );
                return;
              }

              final movie = Movie(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                description: descriptionController.text,
                imageUrl: imageUrlController.text.isEmpty
                    ? 'https://via.placeholder.com/500x750?text=No+Image'
                    : imageUrlController.text,
                rating: double.tryParse(ratingController.text) ?? 0.0,
                year: int.tryParse(yearController.text) ?? 0,
                genre: genreController.text.isEmpty ? 'Non spécifié' : genreController.text,
                director: directorController.text.isEmpty ? 'Non spécifié' : directorController.text,
              );

              try {
                await widget.firestoreService.addMovie(movie);
                if (mounted) {
                  Navigator.pop(context);
                  widget.onMoviesUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Film ajouté avec succès')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    try {
      if (user.isActive) {
        await widget.firestoreService.disableUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.firstName} ${user.lastName} a été désactivé')),
          );
        }
      } else {
        await widget.firestoreService.enableUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.firstName} ${user.lastName} a été activé')),
          );
        }
      }
      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle), text: 'Ajouter un film'),
            Tab(icon: Icon(Icons.people), text: 'Gérer les utilisateurs'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet Ajouter un film
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.movie_creation,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ajouter un nouveau film',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showAddMovieDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un film'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Onglet Gérer les utilisateurs
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(
                          child: Text('Aucun utilisateur trouvé'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null
                                      ? Text(
                                          user.firstName.isNotEmpty
                                              ? user.firstName[0].toUpperCase()
                                              : user.email.isNotEmpty
                                                  ? user.email[0].toUpperCase()
                                                  : 'U',
                                        )
                                      : null,
                                ),
                                title: Text('${user.firstName} ${user.lastName}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    Text(
                                      user.age > 0 
                                          ? 'Âge: ${user.age} ans' 
                                          : 'Âge: Non spécifié',
                                    ),
                                    Text('Rôle: ${user.role}'),
                                    Text(
                                      user.isActive ? 'Actif' : 'Désactivé',
                                      style: TextStyle(
                                        color: user.isActive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    user.isActive ? Icons.block : Icons.check_circle,
                                    color: user.isActive ? Colors.red : Colors.green,
                                  ),
                                  onPressed: () => _toggleUserStatus(user),
                                  tooltip: user.isActive
                                      ? 'Désactiver l\'utilisateur'
                                      : 'Activer l\'utilisateur',
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

