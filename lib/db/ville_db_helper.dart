import 'database_helper.dart';
import '../models/ville.dart';

/* helper qui gère les opérations CRUD sur la table villes */

class VilleDbHelper {
  /* insertion d'une ville */
  static Future<int> insert(Ville ville) async {
    final db = await DatabaseHelper.database;
    return db.insert('villes', ville.toMap());
  }

  /* récupération de toutes les villes */
  static Future<List<Ville>> getAll() async {
    final db = await DatabaseHelper.database;
    final result = await db.query('villes');
    return result.map((map) => Ville.fromMap(map)).toList();
  }

  /* getter de ville depuis la BDD par id */
  static Future<Ville?> getById(int id) async {
    final db = await DatabaseHelper.database;
    final result = await db.query('villes', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Ville.fromMap(result.first) : null;
  }

  /* mise à jour d'une ville */
  static Future<int> update(Ville ville) async {
    final db = await DatabaseHelper.database;
    return db.update(
      'villes',
      ville.toMap(),
      where: 'id = ?',
      whereArgs: [ville.id],
    );
  }

  /* suppression d'une ville par son id */

  static Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('villes', where: 'id = ?', whereArgs: [id]);
  }
}
