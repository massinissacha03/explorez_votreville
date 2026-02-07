import 'database_helper.dart';
import '../models/lieu.dart';

/* helper qui gère les opérations CRUD sur la table lieux */
class LieuDbHelper {
  /* insertion d'un lieu */
  static Future<int> insert(Lieu lieu) async {
    final db = await DatabaseHelper.database;
    return db.insert('lieux', lieu.toMap());
  }

  /* récupération des lieux par ville */
  static Future<List<Lieu>> getByVille(int villeId) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'lieux',
      where: 'villeId = ?',
      whereArgs: [villeId],
    );
    // conversion des maps en objets Lieu puis retour de la liste
    return result.map((map) => Lieu.fromMap(map)).toList();
  }

  // mise à jour d'un lieu
  // utilisé pour modifier un lieu ou pour mettre à jour la note moyenne...

  static Future<int> update(Lieu lieu) async {
    final db = await DatabaseHelper.database;
    return db.update(
      'lieux',
      lieu.toMap(),
      where: 'id = ?',
      whereArgs: [lieu.id],
    );
  }


  // suppression d'un lieu par son id
  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('lieux', where: 'id = ?', whereArgs: [id]);
  }


  // suppression de tous les lieux d'une ville
  static Future<void> supprimerParVille(int villeId) async {
    final db = await DatabaseHelper.database;
    await db.delete('lieux', where: 'villeId = ?', whereArgs: [villeId]);
  }
  
}