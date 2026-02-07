// classes de fonctions communes utilisés dans plusieurs endroits de l'application
import 'package:flutter/material.dart';

class Commun {
  // categories de lieux
  static const List<String> categories = [
    'Musée',
    'Restaurant',
    'Monument',
    'Parc',
    'Hôtel',
    'Café',
    'Hôpital',
    'Stade',
    'Lac',
    'Plage',
    'Aéroport',
    'Cinéma',
    'Études',
    'Lieu de culte',
    'Gare',
    'Autre',
  ];

  // chemins des images par catégories
  static const Map<String, String> imagesCategories = {
    'Musée': 'categories/musee.png',
    'Restaurant': 'categories/restaurant.png',
    'Monument': 'categories/monument.png',
    'Parc': 'categories/parc.png',
    'Hôtel': 'categories/hotel.png',
    'Café': 'categories/cafe.png',
    'Hôpital': 'categories/hopital.png',
    'Stade': 'categories/stade.png',
    'Lac': 'categories/lac.png',
    'Plage': 'categories/plage.png',
    'Aéroport': 'categories/aeroport.png',
    'Cinéma': 'categories/cinema.png',
    'Études': 'categories/univ.png',
    'Lieu de culte': 'categories/culte.png',
    'Gare': 'categories/gare.png',
    'Autre': 'categories/autre.png',
  };

  // icones par categories
  static const Map<String, IconData> iconesCategories = {
    'Restaurant': Icons.restaurant,
    'Musée': Icons.museum,
    'Monument': Icons.account_balance,
    'Parc': Icons.park,
    'Hôtel': Icons.hotel,
    'Café': Icons.local_cafe,
    'Hôpital': Icons.local_hospital,
    'Stade': Icons.sports_soccer,
    'Lac': Icons.water,
    'Plage': Icons.beach_access,
    'Aéroport': Icons.flight,
    'Cinéma': Icons.movie,
    'Études': Icons.school,
    'Lieu de culte': Icons.church,
    'Gare': Icons.train_outlined,

    'Autre': Icons.interests,
  };

  static IconData getIconeCategorie(String categorie) {
    return iconesCategories[categorie] ?? Icons.place;
  }

  static String getImageCategorie(String categorie) {
    return imagesCategories[categorie] ?? 'categories/musee.png';
  }

  // obtenir le chemin de l'animation météo selon la description
  // nous n'avons trouvé que 9 animations lottie gratuites
  // donc nous allons faire que 9 cas et par défaut soleil
  static String getAnimationMeteo(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('orage') || desc.contains('thunder')) {
      return 'assets/meteo/thunder.json';
    } else if (desc.contains('forte pluie') || desc.contains('heavy')) {
      return 'assets/meteo/heavy_rain.json';
    } else if (desc.contains('pluie') || desc.contains('rain')) {
      return 'assets/meteo/rain.json';
    } else if (desc.contains('neige') || desc.contains('snow')) {
      return 'assets/meteo/snow.json';
    } else if (desc.contains('brouillard') ||
        desc.contains('fog') ||
        desc.contains('brume')) {
      return 'assets/meteo/foggy.json';
    } else if (desc.contains('nuageux') ||
        desc.contains('couvert') ||
        desc.contains('nuage') ||
        desc.contains('cloud')) {
      return 'assets/meteo/cloudy.json';
    } else if (desc.contains('partiellement') ||
        desc.contains('éclaircies') ||
        desc.contains('partly')) {
      return 'assets/meteo/partly_cloudy_day.json';
    } else {
      return 'assets/meteo/sunny.json';
    }
  }
}
