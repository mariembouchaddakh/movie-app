/// Service de gestion des données Firestore et Firebase Storage
/// 
/// Ce service centralise toutes les opérations de base de données :
/// - Gestion des utilisateurs (CRUD)
/// - Gestion des films (CRUD)
/// - Gestion des favoris (ajout/retrait)
/// - Calcul du matching entre utilisateurs
/// - Upload de photos de profil
/// 
/// Architecture :
/// - Utilise Firestore pour les données structurées
/// - Utilise Firebase Storage pour les fichiers (photos)
/// - Implémente la logique de retry pour les opérations critiques
/// - Complète automatiquement les champs manquants des utilisateurs
/// 
/// Collections Firestore :
/// - users : Documents utilisateurs (ID = UID Firebase Auth)
/// - movies : Documents films (ID = ID du film)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/movie.dart';

class FirestoreService {
  /// Instance Firestore pour accéder à la base de données
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Instance Firebase Storage pour gérer les fichiers (photos)
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========== NOMS DES COLLECTIONS ==========
  
  /// Nom de la collection Firestore pour les utilisateurs
  static const String usersCollection = 'users';
  
  /// Nom de la collection Firestore pour les films
  static const String moviesCollection = 'movies';

  // ========== OPÉRATIONS UTILISATEURS ==========

  /// Crée ou met à jour un utilisateur dans Firestore
  /// 
  /// Utilise SetOptions(merge: true) pour :
  /// - Créer le document s'il n'existe pas
  /// - Mettre à jour seulement les champs fournis s'il existe déjà
  /// 
  /// Paramètres :
  /// - [user] : Instance AppUser à sauvegarder
  /// 
  /// Utilisé lors de :
  /// - L'inscription (création du profil)
  /// - La mise à jour du profil utilisateur
  /// - La complétion automatique des champs manquants
  Future<void> createOrUpdateUser(AppUser user) async {
    await _firestore
        .collection(usersCollection)
        .doc(user.id) // ID = UID Firebase Auth
        .set(user.toJson(), SetOptions(merge: true)); // Merge = ne pas écraser les champs existants
  }

  // Récupérer un utilisateur par ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final appUser = AppUser.fromJson(data, doc.id);
        
        // Vérifier et compléter les champs manquants
        await _ensureUserFieldsComplete(userId, appUser, data);
        
        return appUser;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Compléter automatiquement les champs manquants d'un utilisateur
  Future<void> _ensureUserFieldsComplete(String userId, AppUser appUser, Map<String, dynamic> data) async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      bool needsUpdate = false;
      final updates = <String, dynamic>{};

      // Vérifier et compléter l'email
      if (appUser.email.isEmpty && authUser?.email != null) {
        updates['email'] = authUser!.email!;
        needsUpdate = true;
        debugPrint('✅ Email complété automatiquement: ${authUser.email}');
      }

      // Vérifier et compléter firstName
      if (appUser.firstName.isEmpty) {
        // Essayer d'extraire depuis le displayName ou email
        String firstName = 'Utilisateur';
        if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) {
          final parts = authUser.displayName!.split(' ');
          firstName = parts[0];
        } else if (authUser?.email != null) {
          final emailParts = authUser!.email!.split('@');
          firstName = emailParts[0].split('.')[0];
          firstName = firstName[0].toUpperCase() + firstName.substring(1);
        }
        updates['firstName'] = firstName;
        needsUpdate = true;
        debugPrint('✅ firstName complété automatiquement: $firstName');
      }

      // Vérifier et compléter lastName
      if (appUser.lastName.isEmpty && authUser?.displayName != null) {
        final parts = authUser!.displayName!.split(' ');
        if (parts.length > 1) {
          updates['lastName'] = parts.sublist(1).join(' ');
          needsUpdate = true;
          debugPrint('✅ lastName complété automatiquement: ${updates['lastName']}');
        }
      }

      // Vérifier et compléter age
      // Ne pas mettre 0 par défaut, laisser le champ vide si absent
      // L'âge sera affiché comme "Non spécifié" dans l'interface
      if (!data.containsKey('age')) {
        // Ne pas ajouter le champ age s'il n'existe pas
        // L'utilisateur devra le remplir manuellement ou lors de l'inscription
        debugPrint('⚠️ Champ age manquant, mais non complété automatiquement (doit être rempli manuellement)');
      }

      // Vérifier et compléter role
      if (appUser.role.isEmpty || !data.containsKey('role')) {
        updates['role'] = 'user'; // Par défaut, pas admin
        needsUpdate = true;
        debugPrint('✅ role complété automatiquement: user');
      }

      // Vérifier et compléter isActive
      if (!data.containsKey('isActive')) {
        updates['isActive'] = true;
        needsUpdate = true;
        debugPrint('✅ isActive complété automatiquement: true');
      }

      // Sauvegarder les mises à jour si nécessaire
      if (needsUpdate) {
        await _firestore
            .collection(usersCollection)
            .doc(userId)
            .update(updates);
        debugPrint('✅ Document utilisateur complété automatiquement avec ${updates.length} champs');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la complétion automatique des champs: $e');
      // Ne pas bloquer si la complétion échoue
    }
  }

  // Récupérer l'utilisateur actuel
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final appUser = await getUserById(user.uid);
        
        // Si le document n'existe pas du tout, créer un profil minimal
        if (appUser == null) {
          debugPrint('📝 Création d\'un profil minimal pour: ${user.uid}');
          final newUser = AppUser(
            id: user.uid,
            email: user.email ?? '',
            firstName: user.displayName?.split(' ').first ?? 
                       (user.email?.split('@').first.split('.').first ?? 'Utilisateur'),
            lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
            age: 0,
            role: 'user',
            isActive: true,
          );
          await createOrUpdateUser(newUser);
          return newUser;
        }
        
        return appUser;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur actuel: $e');
      return null;
    }
  }

  // Vérifier si l'utilisateur actuel est admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final appUser = await getCurrentUser();
      return appUser?.isAdmin ?? false;
    } catch (e) {
      print('Erreur lors de la vérification du statut admin: $e');
      return false;
    }
  }

  // Désactiver un utilisateur (admin seulement)
  Future<void> disableUser(String userId) async {
    await _firestore
        .collection(usersCollection)
        .doc(userId)
        .update({'isActive': false});
  }

  // Activer un utilisateur (admin seulement)
  Future<void> enableUser(String userId) async {
    await _firestore
        .collection(usersCollection)
        .doc(userId)
        .update({'isActive': true});
  }

  // Récupérer tous les utilisateurs (admin seulement)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(usersCollection).get();
      return snapshot.docs
          .where((doc) => doc.exists && doc.data().isNotEmpty)
          .map((doc) {
            try {
              return AppUser.fromJson(doc.data(), doc.id);
            } catch (e) {
              print('Erreur lors de la conversion de l\'utilisateur ${doc.id}: $e');
              return null;
            }
          })
          .whereType<AppUser>()
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  // Upload une photo de profil
  Future<String?> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erreur lors de l\'upload de la photo: $e');
      return null;
    }
  }

  // ========== FAVORITE MOVIES OPERATIONS ==========

  // Ajouter un film aux favoris avec retry automatique
  Future<void> addFavoriteMovie(String userId, String movieId) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final userRef = _firestore.collection(usersCollection).doc(userId);
        
        // Vérifier si le document existe
        final doc = await userRef.get();
        
        if (doc.exists) {
          // Si le document existe, utiliser update
          await userRef.update({
            'favoriteMovies': FieldValue.arrayUnion([movieId]),
          });
        } else {
          // Si le document n'existe pas, créer le document avec set
          await userRef.set({
            'favoriteMovies': [movieId],
          }, SetOptions(merge: true));
        }
        
        print('✅ Film $movieId ajouté aux favoris pour l\'utilisateur $userId');
        return; // Succès, sortir de la boucle
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        final isPermissionDenied = errorString.contains('permission_denied') || 
                                   errorString.contains('api has not been used') ||
                                   errorString.contains('is disabled');
        
        if (isPermissionDenied) {
          print('❌ ERREUR CRITIQUE: Firestore n\'est pas activé dans votre projet Firebase!');
          print('📋 Solution: Activez Firestore dans Firebase Console');
          print('🔗 Lien: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=project-73978');
          rethrow;
        }
        
        final isUnavailable = errorString.contains('unavailable') || 
                              errorString.contains('transient');
        
        if (isUnavailable && attempt < maxRetries - 1) {
          // Attendre avant de réessayer (backoff exponentiel)
          final delay = Duration(milliseconds: baseDelay.inMilliseconds * (1 << attempt));
          print('⚠️ Service indisponible, nouvelle tentative dans ${delay.inSeconds}s... (${attempt + 1}/$maxRetries)');
          await Future.delayed(delay);
          continue;
        } else {
          print('❌ Erreur lors de l\'ajout du film aux favoris: $e');
          rethrow;
        }
      }
    }
  }

  // Retirer un film des favoris avec retry automatique
  Future<void> removeFavoriteMovie(String userId, String movieId) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final userRef = _firestore.collection(usersCollection).doc(userId);
        
        // Vérifier si le document existe
        final doc = await userRef.get();
        
        if (doc.exists) {
          await userRef.update({
            'favoriteMovies': FieldValue.arrayRemove([movieId]),
          });
          print('✅ Film $movieId retiré des favoris pour l\'utilisateur $userId');
          return; // Succès, sortir de la boucle
        } else {
          print('⚠️ Document utilisateur n\'existe pas, rien à retirer');
          return;
        }
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        final isPermissionDenied = errorString.contains('permission_denied') || 
                                   errorString.contains('api has not been used') ||
                                   errorString.contains('is disabled');
        
        if (isPermissionDenied) {
          print('❌ ERREUR CRITIQUE: Firestore n\'est pas activé dans votre projet Firebase!');
          print('📋 Solution: Activez Firestore dans Firebase Console');
          print('🔗 Lien: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=project-73978');
          rethrow;
        }
        
        final isUnavailable = errorString.contains('unavailable') || 
                              errorString.contains('transient');
        
        if (isUnavailable && attempt < maxRetries - 1) {
          // Attendre avant de réessayer (backoff exponentiel)
          final delay = Duration(milliseconds: baseDelay.inMilliseconds * (1 << attempt));
          print('⚠️ Service indisponible, nouvelle tentative dans ${delay.inSeconds}s... (${attempt + 1}/$maxRetries)');
          await Future.delayed(delay);
          continue;
        } else {
          print('❌ Erreur lors du retrait du film des favoris: $e');
          rethrow;
        }
      }
    }
  }

  // Vérifier si un film est dans les favoris
  Future<bool> isFavoriteMovie(String userId, String movieId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final favoriteMovies = data['favoriteMovies'] as List?;
        if (favoriteMovies != null) {
          return favoriteMovies.contains(movieId);
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification du favori: $e');
      return false;
    }
  }

  // Récupérer les films favoris d'un utilisateur
  Future<List<String>> getFavoriteMovies(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final favoriteMovies = data['favoriteMovies'] as List?;
        if (favoriteMovies != null) {
          return favoriteMovies.map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }

  // ========== MOVIE OPERATIONS ==========

  // Ajouter un film à la base (admin seulement)
  Future<void> addMovie(Movie movie) async {
    await _firestore
        .collection(moviesCollection)
        .doc(movie.id)
        .set(movie.toJson());
  }

  // Récupérer tous les films depuis Firestore
  Future<List<Movie>> getMoviesFromFirestore() async {
    try {
      final snapshot = await _firestore.collection(moviesCollection).get();
      return snapshot.docs
          .map((doc) => Movie.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des films: $e');
      return [];
    }
  }

  // Récupérer un film par ID depuis Firestore
  Future<Movie?> getMovieByIdFromFirestore(String movieId) async {
    try {
      final doc = await _firestore.collection(moviesCollection).doc(movieId).get();
      if (doc.exists) {
        return Movie.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du film: $e');
      return null;
    }
  }

  // ========== MATCHING OPERATIONS ==========

  // Calculer le taux de correspondance entre deux utilisateurs
  double calculateMatchRate(AppUser user1, AppUser user2) {
    if (user1.favoriteMovies.isEmpty || user2.favoriteMovies.isEmpty) {
      print('   ⚠️ Un des utilisateurs n\'a pas de favoris');
      return 0.0;
    }

    final set1 = user1.favoriteMovies.toSet();
    final set2 = user2.favoriteMovies.toSet();

    // Calculer l'intersection (films communs)
    final intersection = set1.intersection(set2).length;
    print('   📊 Films en commun: $intersection');
    
    // Calculer l'union (tous les films uniques)
    final union = set1.union(set2).length;
    print('   📊 Total de films uniques: $union');

    if (union == 0) return 0.0;

    // Taux de correspondance basé sur Jaccard similarity
    final rate = (intersection / union) * 100;
    print('   📊 Calcul: ($intersection / $union) × 100 = ${rate.toStringAsFixed(1)}%');
    return rate;
  }

  // Trouver les utilisateurs avec un taux de correspondance > 75%
  Future<List<Map<String, dynamic>>> findMatchingUsers(String userId) async {
    try {
      print('🔍 Recherche de correspondances pour l\'utilisateur: $userId');
      
      final currentUser = await getUserById(userId);
      if (currentUser == null) {
        print('❌ Utilisateur actuel non trouvé');
        return [];
      }

      print('👤 Utilisateur actuel: ${currentUser.firstName} ${currentUser.lastName}');
      print('🎬 Favoris de l\'utilisateur actuel: ${currentUser.favoriteMovies.length} films');
      print('   IDs: ${currentUser.favoriteMovies}');

      final allUsers = await getAllUsers();
      print('👥 Total d\'utilisateurs dans la base: ${allUsers.length}');

      final matches = <Map<String, dynamic>>[];

      for (final user in allUsers) {
        // Ignorer l'utilisateur actuel et les utilisateurs désactivés
        if (user.id == userId || !user.isActive) {
          if (user.id == userId) {
            print('⏭️ Ignoré: utilisateur actuel');
          } else {
            print('⏭️ Ignoré: ${user.firstName} ${user.lastName} (désactivé)');
          }
          continue;
        }

        print('🔍 Comparaison avec: ${user.firstName} ${user.lastName}');
        print('   Favoris: ${user.favoriteMovies.length} films - IDs: ${user.favoriteMovies}');

        final matchRate = calculateMatchRate(currentUser, user);
        print('   Taux de correspondance: ${matchRate.toStringAsFixed(1)}%');

        if (matchRate > 75.0) {
          print('✅ Correspondance trouvée! (${matchRate.toStringAsFixed(1)}%)');
          matches.add({
            'user': user,
            'matchRate': matchRate,
          });
        } else {
          print('❌ Correspondance insuffisante (${matchRate.toStringAsFixed(1)}% < 75%)');
        }
      }

      // Trier par taux de correspondance décroissant
      matches.sort((a, b) => (b['matchRate'] as double).compareTo(a['matchRate'] as double));

      print('✨ Total de correspondances trouvées: ${matches.length}');
      return matches;
    } catch (e) {
      print('❌ Erreur lors de la recherche de correspondances: $e');
      return [];
    }
  }
}

