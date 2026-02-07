import 'package:flutter/material.dart';
import '../../models/ville.dart';

// entete du drawer avec gradient et ville mise en avant

Widget drawerHeaderSection(bool isDark, Ville? villeMiseEnAvant) {
  return DrawerHeader(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [
                const Color.fromARGB(255, 0, 0, 0),
                const Color.fromARGB(255, 0, 92, 20),
              ]
            : [
                const Color.fromARGB(255, 0, 92, 20),
                const Color.fromARGB(255, 0, 0, 0),
              ],
      ),
    ),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Mes Villes Favorites',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (villeMiseEnAvant != null)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Mise en avant : ${villeMiseEnAvant.name}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
