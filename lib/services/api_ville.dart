import 'dart:convert';
import 'package:http/http.dart' as http;


/* service pour interagir avec l'API Nominatim d'osm */
class ApiVille {
   


  // rechercher une ville par son nom
  Future<List<Map<String, dynamic>>> searchCityAPI(String cityName) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/search'
          '?q=$cityName&format=json&limit=5';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ExplorezVotreVille'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (_) {
      return [];
    }
  }


  // trouver une ville par position (lat, lon)
  Future<Map<String, dynamic>?> fetchVilleParPosition(
    double lat,
    double lon,
  ) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=$lat&lon=$lon&format=json';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ExplorezVotreVille'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
