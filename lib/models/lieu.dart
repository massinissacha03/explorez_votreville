/* classe Lieu*/
class Lieu {
  final int? id;
  final int villeId; // fk vers la ville
  final String nom;
  final String? description;
  final String categorie;
  final double latitude;
  final double longitude;
  final bool estFavori; // par defaut false
  final double? noteMoyenne;
  final String? telephone;
  final String? email;
  final String? siteWeb;
  final String? adresse;
  final bool accessibiliteHandicape;

  Lieu({
    this.id,
    required this.villeId,
    required this.nom,
    this.description,
    required this.categorie,
    required this.latitude,
    required this.longitude,
    this.estFavori = false,
    this.noteMoyenne,
    this.telephone,
    this.email,
    this.siteWeb,
    this.adresse,
    this.accessibiliteHandicape = false,
  });

  // Construit un Lieu à partir d’une ligne (Map) récupérée depuis SQLite.
  factory Lieu.fromMap(Map<String, dynamic> m) {
    return Lieu(
      id: m['id'],
      villeId: m['villeId'],
      nom: m['nom'],
      description: m['description'],
      categorie: m['categorie'],
      latitude: (m['latitude'] as num).toDouble(),
      longitude: (m['longitude'] as num).toDouble(),
      estFavori: m['estFavori'] == 1,
      noteMoyenne: m['noteMoyenne'] == null
          ? null
          : (m['noteMoyenne'] as num).toDouble(),
      telephone: m['telephone'],
      email: m['email'],
      siteWeb: m['siteWeb'],
      adresse: m['adresse'],
     accessibiliteHandicape: (m['accessibiliteHandicape'] as int? ?? 0) == 1,
    );
  }


  // Convertit un Lieu en Map pour insertion dans la BDD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'villeId': villeId,
      'nom': nom,
      'description': description,
      'categorie': categorie,
      'latitude': latitude,
      'longitude': longitude,
      'estFavori': estFavori ? 1 : 0,
      'noteMoyenne': noteMoyenne,
      'telephone': telephone,
      'email': email,
      'siteWeb': siteWeb,
      'adresse': adresse,
      'accessibiliteHandicape': accessibiliteHandicape ? 1 : 0,
    };
  }


  // Construit un Lieu à partir des données d’une API externe
  factory Lieu.fromApi(
  Map<String, dynamic> json, {
  required String categorie,
  required int villeId,
}) {

  final acces = json['accessibilite']?.toString().toLowerCase();
  final bool accesNormalise = acces == 'yes';

  return Lieu(
    villeId: villeId,
    nom: (json['name'] ?? 'Lieu sans nom').toString(),
    description: json['description']?.toString() ?? json['vicinity']?.toString(),
    categorie: categorie,
    latitude: double.parse(json['lat'].toString()),
    longitude: double.parse(json['lon'].toString()),
    telephone: json['phone']?.toString(),
    siteWeb: json['website']?.toString(),
    adresse: json['address']?.toString(),
    accessibiliteHandicape: accesNormalise,  
  );
}
  
  Lieu copie({
    int? id,
    int? villeId,
    String? nom,
    String? description,
    String? categorie,
    double? latitude,
    double? longitude,
    bool? estFavori,
    double? noteMoyenne,
    String? telephone,
    String? email,
    String? siteWeb,
    String? adresse,
    bool? accessibiliteHandicape,
  }) {
    return Lieu(
      id: id ?? this.id,
      villeId: villeId ?? this.villeId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      categorie: categorie ?? this.categorie,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estFavori: estFavori ?? this.estFavori,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      adresse: adresse ?? this.adresse,
      accessibiliteHandicape:
          accessibiliteHandicape ?? this.accessibiliteHandicape,
    );
  }
}
