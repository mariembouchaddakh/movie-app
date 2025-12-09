# Movie App

Une application Flutter complète de gestion des films avec authentification Firebase, playlist de favoris, et système de matching entre utilisateurs.

## Fonctionnalités

### Utilisateurs
- 🔐 **Authentification Firebase** : Inscription et connexion sécurisées
- 👤 **Profil utilisateur** : Nom, prénom, âge et photo de profil
- ❤️ **Playlist de favoris** : Créez votre propre liste de films favoris
- 🔍 **Recherche de films** : Recherchez des films par titre, description ou genre
- 📄 **Détails des films** : Page détaillée pour chaque film avec toutes les informations
- 👥 **Matching** : Trouvez des utilisateurs avec plus de 75% de correspondance dans vos goûts cinématographiques

### Administrateurs
- ➕ **Ajouter des films** : Ajoutez des films à la base de données
- 👥 **Gestion des utilisateurs** : Désactivez (ou activez) des utilisateurs sans les supprimer
- 🎬 **Base de données** : Films stockés dans Firestore

## Structure du projet

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── models/
│   ├── movie.dart              # Modèle de données pour les films
│   └── user.dart               # Modèle de données pour les utilisateurs
├── screens/
│   ├── login_screen.dart       # Écran de connexion
│   ├── signup_screen.dart      # Écran d'inscription (nom, prénom, âge, photo)
│   ├── home_screen.dart        # Écran d'accueil avec onglets (Films, Favoris, Matching, Admin)
│   ├── movie_detail_screen.dart # Écran de détail d'un film avec ajout aux favoris
│   ├── admin_screen.dart       # Interface admin (ajouter films, gérer utilisateurs)
│   └── matching_screen.dart    # Écran de matching entre utilisateurs
├── services/
│   ├── movie_service.dart      # Service pour gérer les films (API + Firestore)
│   └── firestore_service.dart  # Service pour gérer Firestore (utilisateurs, films, favoris)
└── utils/
    └── constants.dart          # Constantes de l'application (incluant clé API)
```

## Prérequis

- Flutter SDK (version 3.9.2 ou supérieure)
- Compte Firebase configuré avec :
  - Authentication (Email/Password)
  - Cloud Firestore
  - Storage (pour les photos de profil)
- Clé API TMDb (The Movie Database) - **Gratuite** (optionnel)
- Android Studio / Xcode pour le développement mobile

## Installation

1. Clonez le projet :
```bash
git clone <url-du-projet>
cd projet
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Configurez Firebase :
   - Ajoutez votre fichier `google-services.json` dans `android/app/`
   - Configurez Firebase pour iOS si nécessaire
   - Activez dans la console Firebase :
     - Authentication (Email/Password)
     - Cloud Firestore
     - Storage

4. Configurez l'API TMDb (optionnel) :
   - Obtenez une clé API gratuite sur [TMDb](https://www.themoviedb.org/settings/api)
   - Modifiez `lib/utils/constants.dart` et remplacez `YOUR_TMDB_API_KEY` par votre clé
   - Voir `lib/utils/constants.example.dart` pour la structure attendue

5. Lancez l'application :
```bash
flutter run
```

## Configuration Firebase

1. Créez un projet Firebase sur [Firebase Console](https://console.firebase.google.com/)
2. Activez les services suivants :
   - **Authentication** : Activez la méthode Email/Password
   - **Cloud Firestore** : Créez une base de données en mode test
   - **Storage** : Activez le stockage pour les photos de profil
3. Téléchargez les fichiers de configuration :
   - Pour Android : `google-services.json` → `android/app/`
   - Pour iOS : `GoogleService-Info.plist` → `ios/Runner/`

## Configuration de l'API TMDb (The Movie Database)

1. Créez un compte gratuit sur [TMDb](https://www.themoviedb.org/)
2. Allez dans **Paramètres** > **API**
3. Demandez une clé API (type **Developer** - gratuite)
4. Copiez votre clé API
5. Modifiez `lib/utils/constants.dart` :
```dart
static const String tmdbApiKey = 'VOTRE_CLE_API_ICI';
```

**Note** : Si vous ne configurez pas l'API, l'application fonctionnera toujours mais utilisera uniquement les films ajoutés par les administrateurs dans Firestore et des films de démonstration.

**⚠️ Important** : Ne commitez JAMAIS votre clé API sur GitHub ! Utilisez un placeholder (`YOUR_TMDB_API_KEY`).

## Utilisation

### Pour les utilisateurs

1. **Inscription** : 
   - Créez un compte avec email, mot de passe, nom, prénom, âge et photo
   - La photo est optionnelle mais recommandée

2. **Connexion** : 
   - Connectez-vous avec vos identifiants

3. **Explorer les films** : 
   - Parcourez la liste des films disponibles
   - Utilisez la barre de recherche pour trouver des films spécifiques

4. **Ajouter aux favoris** : 
   - Cliquez sur un film pour voir ses détails
   - Cliquez sur l'icône cœur pour ajouter/retirer des favoris
   - Consultez vos favoris dans l'onglet "Favoris"

5. **Matching** : 
   - Allez dans l'onglet "Matching"
   - Découvrez les utilisateurs avec plus de 75% de correspondance dans vos goûts

### Pour les administrateurs

Pour créer un compte administrateur, vous devez modifier manuellement le rôle dans Firestore :
1. Connectez-vous avec votre compte
2. Dans la console Firebase, allez dans Firestore
3. Trouvez votre document dans la collection `users`
4. Modifiez le champ `role` de `user` à `admin`

**Fonctionnalités admin** :
- **Ajouter un film** : Onglet "Ajouter un film" dans l'interface admin
- **Gérer les utilisateurs** : Onglet "Gérer les utilisateurs" pour activer/désactiver des comptes

## Technologies utilisées

- **Flutter** : Framework de développement multiplateforme
- **Firebase Core** : Services Firebase de base
- **Firebase Auth** : Authentification utilisateur
- **Cloud Firestore** : Base de données NoSQL
- **Firebase Storage** : Stockage des photos de profil
- **HTTP** : Appels API vers TMDb (The Movie Database)
- **Image Picker** : Sélection de photos depuis la galerie ou l'appareil photo

## Fonctionnalités techniques

### Système de matching

Le système de matching calcule le taux de correspondance entre deux utilisateurs en utilisant la similarité de Jaccard :
- **Formule** : (Films en commun) / (Tous les films uniques) × 100
- **Seuil** : Affiche uniquement les utilisateurs avec > 75% de correspondance
- Les résultats sont triés par taux de correspondance décroissant

### Gestion des films

- Les films peuvent provenir de plusieurs sources (par ordre de priorité) :
  1. **Firestore** : Films ajoutés par les administrateurs (priorité maximale)
  2. **API TMDb** : Films populaires récupérés depuis l'API TMDb (si configuré)
  3. **Films de démonstration** : Films par défaut si aucune autre source n'est disponible
- Les doublons sont évités en utilisant l'ID du film
- L'application récupère automatiquement plusieurs pages de films depuis TMDb (jusqu'à 100 films)

### Stockage des données

- **Utilisateurs** : Collection `users` dans Firestore
- **Films** : Collection `movies` dans Firestore
- **Photos de profil** : Dossier `profile_photos/` dans Firebase Storage

## Structure des données Firestore

### Collection `users`
```json
{
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "age": 25,
  "photoUrl": "https://...",
  "role": "user" | "admin",
  "isActive": true,
  "favoriteMovies": ["movieId1", "movieId2", ...]
}
```

### Collection `movies`
```json
{
  "id": "movieId",
  "title": "Titre du film",
  "description": "Description...",
  "imageUrl": "https://...",
  "rating": 8.5,
  "year": 2020,
  "genre": "Action, Thriller",
  "director": "Nom du réalisateur"
}
```

## 📚 Documentation

Le projet contient une documentation complète :

- **ARCHITECTURE_ET_DOCUMENTATION.md** : Architecture détaillée, processus Firebase, fonctionnalités
- **GITHUB_SETUP.md** : Guide complet pour déposer le projet sur GitHub
- **GUIDE_INTERFACE_ADMIN.md** : Guide de l'interface administrateur
- **ENABLE_FIRESTORE.md** : Guide pour activer Firestore
- **FIX_FIREBASE_AUTH.md** : Guide pour résoudre les problèmes d'authentification
- **TEST_FEATURES.md** : Guide de test des fonctionnalités
- **TROUBLESHOOTING.md** : Guide de dépannage

## 🚀 Déposer sur GitHub

Pour déposer ce projet sur GitHub, suivez le guide complet dans **GITHUB_SETUP.md**.

**Rappel important** :
- ⚠️ Ne commitez JAMAIS `google-services.json` ou `GoogleService-Info.plist`
- ⚠️ Remplacez les clés API par des placeholders avant de commiter
- ✅ Vérifiez que le `.gitignore` est correctement configuré

## 📝 Code commenté

Tous les fichiers Dart du projet sont entièrement commentés pour faciliter la compréhension :
- Modèles de données (`models/`)
- Services (`services/`)
- Écrans (`screens/`)
- Utilitaires (`utils/`)

## Auteur

Développé avec Flutter et Firebase.

## Licence

Ce projet est un projet éducatif.
