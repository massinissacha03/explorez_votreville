import 'package:flutter/material.dart';
import '../../models/lieu.dart';
import '../../utils/commun.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';


// un widget pour afficher une carte d'un lieu
// avec image , nom , note moyenne , accessibilité PMR , favori 
// les images sont dans assets/images/categorie/ et elles sont générée avec IA 
// car on n'arrive pas à récupérer les images des lieux via une api

Widget lieuCard(BuildContext context, Lieu lieu) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDark = themeProvider.isDarkMode;
  final imagePath = Commun.getImageCategorie(lieu.categorie);
  final heroTag = 'lieu-${lieu.id ?? '${lieu.latitude}-${lieu.longitude}'}';

  final overlayBg = Colors.black.withAlpha(140);
  final access = lieu.accessibiliteHandicape;
  final accessColor = access == true ? Colors.greenAccent : Colors.redAccent;

  return GestureDetector(
    onTap: () {
      Navigator.of(context).pushNamed(
        '/main/details/${Uri.encodeComponent(lieu.nom)}',
        arguments: lieu,
      );
    },
    child: Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(150)
                : Colors.grey.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: 250,
      height: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias, // pour arrondir les bords de l'image
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag,
              child: Image.asset('assets/$imagePath', fit: BoxFit.cover),
            ),
            if (lieu.estFavori)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.favorite, color: Colors.red, size: 22),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: overlayBg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lieu.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (lieu.noteMoyenne != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lieu.noteMoyenne!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/handicap.png',
                                width: 20,
                                height: 20,
                                color: accessColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                access == 'yes' ? 'Accès PMR' : 'Non accessible',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ), 
                          const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
