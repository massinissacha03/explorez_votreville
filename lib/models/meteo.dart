/* classe Meteo */
class Meteo {
  final double temperature;
  final double tempMin;
  final double tempMax;
  final String description;
  final int? humidity;
  final double? windSpeed;
  final int? timezoneSeconds; // extension : on l'utilise pour afficher l'heure locale 

  Meteo({
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    this.humidity,
    this.windSpeed,
    this.timezoneSeconds,
  });


  // Construit un objet Meteo à partir d’une Map (données JSON)
  factory Meteo.fromMap(Map<String, dynamic> data) {
    return Meteo(
      temperature: (data['temperature'] as num).toDouble(),
      tempMin: (data['tempMin'] as num).toDouble(),
      tempMax: (data['tempMax'] as num).toDouble(),
      description: data['weatherDescription']?.toString() ?? 'Pas de données',
      humidity: (data['humidity'] as num?)?.toInt(),
      windSpeed: (data['windSpeed'] as num?)?.toDouble(),
      timezoneSeconds: (data['timezone'] as num?)?.toInt(),
    );
  }

  // Extrait les informations météo sous forme de Map de chaînes de caractères
  // utilisée pour l'affichage dans l'interface
   Map<String, String> extraireMeteo() {
    final temp = temperature;
    final tmpMin = tempMin;
    final tmpMax = tempMax;
    final humidite = humidity ?? 0;
    final vent = windSpeed ?? 0.0;
    final desc = description;

    return {
      'temp': temp.toStringAsFixed(0),
      'tempMin': tmpMin.toStringAsFixed(0),
      'tempMax': tmpMax.toStringAsFixed(0),
      'humidite': humidite.toString(),
      'vent': vent.toStringAsFixed(0),
      'description': desc,
    };
  }
}
