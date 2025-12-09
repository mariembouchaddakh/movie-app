/// Écran de détails d'un film
/// 
/// Fonctionnalités :
/// - Affiche toutes les informations d'un film (titre, description, note, etc.)
/// - Affiche l'affiche du film
/// - Permet d'ajouter/retirer le film des favoris
/// - Gère l'état du bouton favori (coeur rempli/vide)
/// 
/// Affichage :
/// - Affiche du film (image)
/// - Titre, description complète
/// - Métadonnées : note, année, genre, réalisateur
/// - Bouton favori (coeur) pour ajouter/retirer des favoris
/// 
/// Gestion des favoris :
/// - Vérifie si le film est déjà dans les favoris au chargement
/// - Permet de basculer l'état favori avec retry automatique en cas d'erreur
/// - Affiche des messages d'erreur spécifiques avec option de retry

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';
import '../services/firestore_service.dart';

class MovieDetailScreen extends StatefulWidget {
  /// Film dont on affiche les détails
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ Aucun utilisateur connecté');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    debugPrint('🔍 Vérification du statut favori pour le film: ${widget.movie.id}');
    debugPrint('👤 Utilisateur: ${user.uid}');
    
    try {
      final isFavorite = await _firestoreService.isFavoriteMovie(
        user.uid,
        widget.movie.id,
      );
      debugPrint('${isFavorite ? "✅" : "❌"} Film ${isFavorite ? "est" : "n'est pas"} dans les favoris');
      
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du statut favori: $e');
      // En cas d'erreur, afficher quand même le bouton (non favori par défaut)
      if (mounted) {
        setState(() {
          _isFavorite = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour ajouter aux favoris')),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (_isFavorite) {
        debugPrint('➕ Ajout du film ${widget.movie.id} aux favoris...');
        await _firestoreService.addFavoriteMovie(user.uid, widget.movie.id);
        debugPrint('✅ Film ${widget.movie.id} ajouté aux favoris avec succès');
        
        // Recharger le statut pour être sûr
        await _checkFavoriteStatus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Film ajouté aux favoris'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('➖ Retrait du film ${widget.movie.id} des favoris...');
        await _firestoreService.removeFavoriteMovie(user.uid, widget.movie.id);
        debugPrint('✅ Film ${widget.movie.id} retiré des favoris avec succès');
        
        // Recharger le statut pour être sûr
        await _checkFavoriteStatus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Film retiré des favoris'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // En cas d'erreur, annuler le changement d'état
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      final errorString = e.toString().toLowerCase();
      String errorMessage = 'Erreur lors de la modification des favoris';
      
      if (errorString.contains('api has not been used') || 
          errorString.contains('is disabled') ||
          (errorString.contains('permission') && errorString.contains('firestore'))) {
        errorMessage = 'Firestore n\'est pas activé dans votre projet Firebase.\n\n'
            'Solution:\n'
            '1. Allez sur Firebase Console\n'
            '2. Activez Firestore Database\n'
            '3. Attendez 2-5 minutes\n'
            '4. Redémarrez l\'application\n\n'
            'Voir le fichier ENABLE_FIRESTORE.md pour les instructions détaillées.';
      } else if (errorString.contains('unavailable') || errorString.contains('transient')) {
        errorMessage = 'Service temporairement indisponible. Veuillez réessayer dans quelques instants.';
      } else if (errorString.contains('permission')) {
        errorMessage = 'Permission refusée. Vérifiez vos règles Firestore dans Firebase Console.';
      } else if (errorString.contains('network')) {
        errorMessage = 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _toggleFavorite(),
            ),
          ),
        );
      }
      print('❌ Erreur lors de la modification des favoris: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
        actions: [
          // Toujours afficher le bouton, même pendant le chargement
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du film
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: Image.network(
                widget.movie.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.movie,
                      size: 100,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et note
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.movie.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.movie.rating.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Année et genre
                  Wrap(
                    spacing: 16,
                    children: [
                      _buildInfoChip(
                        Icons.calendar_today,
                        '${widget.movie.year}',
                      ),
                      _buildInfoChip(
                        Icons.movie_filter,
                        widget.movie.genre,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Réalisateur
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Réalisateur: ${widget.movie.director}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
