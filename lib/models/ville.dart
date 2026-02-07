/* classe Ville */
class Ville {
  final int? id; // peut etre null avant insertion dans la BDD
  final String name;
  final double latitude;
  final double longitude;
  final bool isFavorite;



  Ville({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
  });

  // true si la ville est mise en avant
  bool estMiseEnAvant(int? villeMiseEnAvantId) {
    return id != null && id == villeMiseEnAvantId;
  }

  // transforme une map BDD en ville
  factory Ville.fromMap(Map<String, dynamic> map) {
    return Ville(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isFavorite: map['isFavorite'] == 1,
    );
  }

  // transforme une ville en map pour insertion dans la BDD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }
  // créer une ville à partir des données api 
  factory Ville.creerVilleDepuisAPI(Map<String, dynamic> data) {
    String nom; 


    // déterminer le nom de la ville
    // on vérifie si la clé 'address' est présente
    // si oui, on cherche les clés city, town, village
    // sinon on utilise display_name et on prend la première partie avant la virgule 
    if (data.containsKey('address')) {
      final address = data['address'] as Map<String, dynamic>;
      nom =
          address['city'] ??
          address['town'] ??
          address['village'] ??
          'Ville inconnue';
    } else {
      final parts = (data['display_name'] as String).split(',');
      nom = parts.first.trim();
    }

    return Ville(
      name: nom,
      latitude: double.parse(data['lat']),
      longitude: double.parse(data['lon']),
      isFavorite: false,
    );
  }

  // permet de créer une copie d'une ville avec des modifications
  // utilisé pour attribuer un id , pour modifier le statut favori...
  Ville copie({
    int? id,
    bool forceIdNull = false,
    String? name,
    double? latitude,
    double? longitude,
    bool? isFavorite,
  }) {
    return Ville(
      id: forceIdNull ? null : (id ?? this.id),
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
