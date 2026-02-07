import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


// service pour interagir avec l'API OpenWeatherMap
// clé dans .env


// elle nous sert aussi à récuperer le fuseau horaire 
class MeteoApi {
  final String _weatherKey = dotenv.env['weatherApiKey'] ?? '';

 

  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lon&appid=$_weatherKey&units=metric&lang=fr';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temperature': data['main']['temp'].toDouble(),
          'tempMin': data['main']['temp_min'].toDouble(),
          'tempMax': data['main']['temp_max'].toDouble(),
          'weatherDescription': data['weather'][0]['description'],
          'humidity': (data['main']['humidity'] as num?)?.toInt(),
          'windSpeed': (data['wind']['speed'] as num?)?.toDouble(),
          'timezone': (data['timezone'] as num?)?.toInt(),
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
