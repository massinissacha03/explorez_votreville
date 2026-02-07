import 'database_helper.dart';
import '../models/commentaire.dart';

/*un Helper pour gérer les operation CRUD sur les commentaires dans la BDD*/

class CommentaireDbHelper {
  // insertion d'un commentaire
  static Future<int> insert(Commentaire commentaire) async {
    final db = await DatabaseHelper.database;
    return db.insert('commentaires', commentaire.toMap());
  }

  // getter de commentaires par un lieu
  static Future<List<Commentaire>> getByLieu(int lieuId) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'commentaires',
      where: 'lieuId = ?',
      whereArgs: [lieuId],
      // trier par date de création décroissante
      orderBy: 'dateCreation DESC',
    );
    return result.map((map) => Commentaire.fromMap(map)).toList();
  }

  // getter de la note moyenne d'un lieu
  static Future<double?> getNoteMoyennePourLieu(int lieuId) async {
    final db = await DatabaseHelper.database;

    // on utilise rawQuery parce que nous faisons une agrégation sql avg
    final result = await db.rawQuery(
      'SELECT AVG(note) AS moyenne FROM commentaires WHERE lieuId = ?',
      [lieuId],
    );

    // retourne la moyenne comme double si elle existe
    final moyenne = result.first['moyenne'] as num?;
    return moyenne?.toDouble();
  }
}
