import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/* helper qui gère l'initialisation de la BDD */
class DatabaseHelper {
  // Instance Singleton de la base de données , une seule utilisée dans toute l’application.
  static Database? _database;

  // accesseur à la base de données
  // si la base n'est pas encore ouverte, on l'ouvre
  // sinon on retourne l'instance en mémoire
  static Future<Database> get database async {
    if (_database != null) return _database!;

    // Répertoire de stockage des bases SQLite de l’app
    final dbPath = await getDatabasesPath();

    // chemin complet vers la BDD
    final path = join(dbPath, 'explorez_votre_ville.db');

    // ouverture (ou creation) de la BDD
    // si la BDD n'existe pas, on appelle la fonction _createDB
    _database = await openDatabase(path, version: 8, onCreate: _createDB);

    return _database!;
  }

  // création des tables de la BDD
  static Future<void> _createDB(Database db, int version) async {
    /*création de la table villes
    Attributs : id(auto increment), name, latitude, longitude, isFavorite (par défaut à false) */
    await db.execute('''
    CREATE TABLE villes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      isFavorite INTEGER NOT NULL DEFAULT 0
    )
  ''');

    /*création de la table lieux 
    attributs : id(auto increment) , villeId (clé étrangère vers villes), nom ....     
    - ON DELETE CASCADE : si une ville est supprimée , toutes les lignes liées a cette ville seront supprimés aussi  */
    await db.execute('''
  CREATE TABLE lieux (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    villeId INTEGER NOT NULL,
    nom TEXT NOT NULL,
    description TEXT,
    categorie TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    noteMoyenne REAL,
    estFavori INTEGER NOT NULL DEFAULT 0,
    telephone TEXT,
    email TEXT,
    siteWeb TEXT,
    adresse TEXT,
    accessibiliteHandicape INTEGER,
    FOREIGN KEY (villeId) REFERENCES villes (id) ON DELETE CASCADE
  )
''');


    /* creation de la table commentaires*/
    await db.execute('''
    CREATE TABLE commentaires (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lieuId INTEGER NOT NULL,
      texte TEXT NOT NULL,
      note REAL NOT NULL,
      dateCreation TEXT NOT NULL,
      FOREIGN KEY (lieuId) REFERENCES lieux (id) ON DELETE CASCADE
    )
  ''');
  }

  /* sert à reinitialiser la base de données */
  static Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('commentaires');
    await db.delete('lieux');
    await db.delete('villes');
  }
}
