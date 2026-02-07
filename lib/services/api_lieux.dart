import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/* service pour interagir avec l'API Google Places, clé dans .env 

** l'url est modifiée pour le web afin d'éviter les problèmes de CORS (youtube)

*/

class ApiLieux {
  final String _googleMapsKey = dotenv.env['googleMapsApiKey'] ?? '';


  // tags Google Maps pour chaque catégorie
  final Map<String, List<String>> _categoriesGoogleMaps = {
    'restaurant': ['restaurant'],
    'café': ['cafe'],
    'musée': ['museum'],
    'parc': ['park'],
    'hôtel': ['lodging'],
    'monument': ['tourist_attraction'],
    'stade': ['stadium'],
    'hôpital': ['hospital'],
    'lac': ['natural_feature'],
    'plage': ['natural_feature'],
    'aéroport': ['airport'],
    'cinéma': ['movie_theater'],
    'gare': ['transit_station', 'train_station', 'subway_station', 'light_rail_station', 'bus_station'],
    'études': ['school', 'secondary_school', 'primary_school', 'university', 'library'],
    'lieu de culte': ['church', 'mosque', 'synagogue'],
  };

  String _wrapForWeb(String url) {
    if (!kIsWeb) return url;
    final encoded = Uri.encodeQueryComponent(url);
    return 'https://corsproxy.io/?$encoded';
  }

  Future<List<Map<String, dynamic>>> chargerSuggestionsParCategorie(
    String categorie,
    double lat,
    double lon, {
    int radius = 5000,
  }) async {
    try {
      final types =
          _categoriesGoogleMaps[categorie.toLowerCase()] ?? ['point_of_interest'];

      final List<Map<String, dynamic>> resultsFusionnes = [];
      final Set<String> dejaVu = {};

      for (final type in types) {
        final baseUrl =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$lat,$lon'
            '&radius=$radius'
            '&type=$type'
            '&key=$_googleMapsKey'
            '&language=fr';
        final url = _wrapForWeb(baseUrl);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final results = List<Map<String, dynamic>>.from(data['results']);
            for (final place in results) {
              final placeId = place['place_id']?.toString();
              if (placeId != null && dejaVu.contains(placeId)) continue;
              if (placeId != null) dejaVu.add(placeId);
              resultsFusionnes.add(place);
            }
          }
        }
      }

      return resultsFusionnes.map((place) {
        return {
          'name': place['name'],
          'lat': place['geometry']['location']['lat'].toString(),
          'lon': place['geometry']['location']['lng'].toString(),
          'type': place['types'][0],
          'place_id': place['place_id'],
          'vicinity': place['vicinity'],
          'address': place['vicinity'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }


  // rechercher un lieu par son nom
  Future<List<Map<String, dynamic>>> rechercherParNom(
    String nom,
    double lat,
    double lon,
  ) async {
    try {
      if (nom.isEmpty) return [];

      final rayonRecherche = 20000; // 20 km

      final baseUrlSearch =
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(nom)}'
          '&location=$lat,$lon'
          '&radius=$rayonRecherche'
          '&key=$_googleMapsKey'
          '&language=fr';

      final urlSearch = _wrapForWeb(baseUrlSearch);

      final responseSearch = await http.get(Uri.parse(urlSearch));

      if (responseSearch.statusCode != 200) {
        return [];
      }

      final dataSearch = json.decode(responseSearch.body);

      if (dataSearch['status'] != 'OK') {
        return [];
      }

      final results = List<Map<String, dynamic>>.from(dataSearch['results']);
      List<Map<String, dynamic>> detailedResults = [];

      for (var place in results.take(10)) {
        final placeId = place['place_id'];

        final baseUrlDetails =
            'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&fields=name,geometry,formatted_address,formatted_phone_number,website,opening_hours'
            '&key=$_googleMapsKey'
            '&language=fr';

        final urlDetails = _wrapForWeb(baseUrlDetails);

        final responseDetails = await http.get(Uri.parse(urlDetails));
        if (responseDetails.statusCode == 200) {
          final dataDetails = json.decode(responseDetails.body);
          if (dataDetails['status'] == 'OK') {
            final result = dataDetails['result'];
            detailedResults.add({
              'name': result['name'],
              'lat': result['geometry']['location']['lat'].toString(),
              'lon': result['geometry']['location']['lng'].toString(),
              'address': result['formatted_address'],
              'phone': result['formatted_phone_number'],
              'website': result['website'],
              'opening_hours': result['opening_hours']?['weekday_text'],
            });
          }
        }
      }
      return detailedResults;
    } catch (e) {
      return [];
    }
  }
}
