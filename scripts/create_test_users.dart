// Script pour créer des utilisateurs de test dans Firebase
// Usage: dart scripts/create_test_users.dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/models/user.dart';

void main() async {
  print('🚀 Initialisation de Firebase...');
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation de Firebase: $e');
    print('⚠️ Assurez-vous que Firebase est correctement configuré');
    exit(1);
  }

  final firestore = FirebaseFirestore.instance;
  
  // Liste des utilisateurs de test à créer
  final testUsers = [
    {
      'id': 'test_user_1',
      'email': 'alice@test.com',
      'firstName': 'Alice',
      'lastName': 'Martin',
      'age': 25,
      'role': 'user',
      'isActive': true,
      'favoriteMovies': ['1', '2', '3'], // Films de démonstration
    },
    {
      'id': 'test_user_2',
      'email': 'bob@test.com',
      'firstName': 'Bob',
      'lastName': 'Dupont',
      'age': 30,
      'role': 'user',
      'isActive': true,
      'favoriteMovies': ['1', '2'], // 2 films en commun avec Alice
    },
    {
      'id': 'test_user_3',
      'email': 'charlie@test.com',
      'firstName': 'Charlie',
      'lastName': 'Bernard',
      'age': 28,
      'role': 'user',
      'isActive': true,
      'favoriteMovies': ['1', '2', '3', '4'], // 3 films en commun avec Alice
    },
    {
      'id': 'test_user_4',
      'email': 'diana@test.com',
      'firstName': 'Diana',
      'lastName': 'Lefebvre',
      'age': 22,
      'role': 'user',
      'isActive': true,
      'favoriteMovies': ['5'], // Aucun film en commun
    },
  ];

  print('\n📝 Création des utilisateurs de test...\n');

  for (final userData in testUsers) {
    try {
      await firestore.collection('users').doc(userData['id'] as String).set({
        'email': userData['email'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'age': userData['age'],
        'role': userData['role'],
        'isActive': userData['isActive'],
        'favoriteMovies': userData['favoriteMovies'],
      }, SetOptions(merge: true));
      
      print('✅ Utilisateur créé: ${userData['firstName']} ${userData['lastName']} (${userData['email']})');
      print('   Favoris: ${(userData['favoriteMovies'] as List).join(', ')}');
    } catch (e) {
      print('❌ Erreur lors de la création de ${userData['email']}: $e');
    }
  }

  print('\n✨ Création terminée !');
  print('\n📋 Note: Ces utilisateurs sont dans Firestore mais pas dans Firebase Auth.');
  print('   Pour les utiliser, vous devez créer les comptes dans Firebase Auth avec les mêmes emails.');
  print('   Ou utilisez l\'application pour vous inscrire avec ces emails.\n');
  
  exit(0);
}

