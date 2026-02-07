
/* classe Commentaire*/
class Commentaire {
  final int? id; // id commentaire , peut être null avant insertion en BDD
  final int lieuId; // FK vers le lieu commenté
  final String texte;
  final double note;
  final DateTime dateCreation = DateTime.now(); // date de création du commentaire )


  
  Commentaire({
    this.id,
    required this.lieuId,
    required this.texte,
    required this.note,
    DateTime? dateCreation, 

  }); 


  // transforme une map depuis la BDD en un commentaire
  // factory : constructeur qui retourne une instance de la classe
  factory Commentaire.fromMap(Map<String, dynamic> map) {
    // map est la ligne de la table commentaires
    return Commentaire(
      id: map['id'],
      lieuId: map['lieuId'],
      texte: map['texte'],
      note: map['note'],
      // conversion de la chaîne en DateTime
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }

  // transforme un commentaire en map pour inserer dans la BDD 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lieuId': lieuId,
      'texte': texte,
      'note': note,
      'dateCreation': dateCreation.toString(),
    };
  }


  // permet de creer une copie d'un commentaire avec des cjamps modifiés
  // dans notre cas on l'utilise pour créer un commentaire avec id généré par la BDD
  // plus tard on pourrait l'utiliser pour modifier le texte du commentaire ou autre chose
  Commentaire copie({
    int? id,
    int? lieuId,
    String? texte,
    double? note,
    DateTime? dateCreation,
  }) {
    return Commentaire(
      id: id ?? this.id,
      lieuId: lieuId ?? this.lieuId,
      texte: texte ?? this.texte,
      note: note ?? this.note,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
