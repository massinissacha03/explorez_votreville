import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lieu_provider.dart';
import 'lieu_card.dart';



// un widget pour afficher la liste des lieux favoris , scrollable horizontalement
Widget listDeLieux(BuildContext context) {
  final lieuProvider = Provider.of<LieuProvider>(context);
  final lieuxFavoris = lieuProvider.getLieuxFavoris();

  if (lieuxFavoris.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.bookmark, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Mes lieux enregistrés (${lieuxFavoris.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: lieuxFavoris.length,
          itemBuilder: (context, index) {
            final lieu = lieuxFavoris[index];
            return lieuCard(context, lieu);
          },
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}
