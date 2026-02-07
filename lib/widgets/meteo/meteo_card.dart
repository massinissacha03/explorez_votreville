import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../providers/ville_provider.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/commentaires_provider.dart';

import '../../models/ville.dart';
import '../../models/meteo.dart';

import '../../utils/commun.dart';
import '../../utils/ville_loader.dart';

import 'meteo_details_dialog.dart';

// Carte météo pour une ville donnée
// Affiche la température actuelle, description, icône animée
class MeteoCard extends StatefulWidget {
  final String nomVille;
  final Meteo? meteo;
  final Ville? ville;

  const MeteoCard({
    super.key,
    required this.nomVille,
    this.meteo,
    this.ville,
  });

  @override
  State<MeteoCard> createState() => _MeteoCardState();
}

class _MeteoCardState extends State<MeteoCard> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final villeProvider = Provider.of<VilleProvider>(context);
    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
    final suggestionProvider =
        Provider.of<SuggestionProvider>(context, listen: false);
    final commentaireProvider =
        Provider.of<CommentaireProvider>(context, listen: false);

    final couleurFond = isDark ? Colors.grey[850] : Colors.white;
    final couleurTexte = isDark ? Colors.white : Colors.black87;
    final couleurSubtitle = isDark ? Colors.grey[400] : Colors.grey[600];

    if (widget.meteo == null) {
      return const SizedBox(child: Text('Pas de données météo disponibles'));
    }

    final description = widget.meteo!.description;
    final double temperature = widget.meteo!.temperature;

    int? offsetSeconds;
    final timezoneRaw = widget.meteo!.timezoneSeconds;
    if (timezoneRaw != null) {
      offsetSeconds = timezoneRaw.toInt();
    }

    Ville? villeActuelle = villeProvider.villeActuelle ?? widget.ville;
    bool estEnBase = villeActuelle?.id != null;
    bool estFavori = villeActuelle?.isFavorite ?? false;
    bool estMiseEnAvant = villeActuelle != null &&
        villeActuelle.id != null &&
        villeProvider.villeMiseEnAvantId == villeActuelle.id;

    return GestureDetector(
      onTap: () {
        if (widget.meteo != null) {
          showDialog(
            context: context,
            builder: (context) => MeteoDetailsDialog(
              nomVille: widget.nomVille,
              meteo: widget.meteo!,
            ),
          );
        }
      },
      child: Card(
        color: couleurFond,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
           
            ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Lottie.asset(
                        Commun.getAnimationMeteo(description),
                        width: 70,
                        height: 70,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nomVille,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: couleurTexte,
                            ),
                          ),
                          if (offsetSeconds != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: couleurSubtitle,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  () {
                                    final utcNow =
                                        villeProvider.heureActuelle.toUtc();
                                    final localTime = utcNow.add(
                                      Duration(seconds: offsetSeconds!),
                                    );
                                    final hh = localTime.hour
                                        .toString()
                                        .padLeft(2, '0');
                                    final mm = localTime.minute
                                        .toString()
                                        .padLeft(2, '0');
                                    return '$hh:$mm';
                                  }(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: couleurSubtitle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(seconds: 1),
                                tween: Tween(begin: 0.0, end: temperature),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Text(
                                    '${value.toStringAsFixed(0)}°',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w300,
                                      color: couleurTexte,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: couleurSubtitle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (villeActuelle != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      // row visité et favori
                      Row(
                        children: [
                          // toggle Bouton Visitée
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (!estEnBase) {
                                  final miseAJour =
                                      await villeProvider.marquerCommeVisitee(
                                    villeActuelle,
                                  );
                                  await villeProvider.setVilleActuelle(
                                    miseAJour,
                                  );
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ville enregistrée comme visitée.',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  final lieuxDeCetteVille = lieuProvider.lieux
                                      .where(
                                          (l) => l.villeId == villeActuelle.id)
                                      .toList();

                                  final idsLieux = lieuxDeCetteVille
                                      .where((l) => l.id != null)
                                      .map((l) => l.id!)
                                      .toSet();

                                  commentaireProvider
                                      .supprimerCommentairesDeVille(idsLieux);

                                  if (villeActuelle.id != null) {
                                    suggestionProvider
                                        .ajouterLieuxDepuisVilleCommeSuggestions(
                                      lieuxDeCetteVille,
                                      villeActuelle.id!,
                                    );
                                    await lieuProvider.supprimerLieuxDeVille(
                                      villeActuelle.id!,
                                    );
                                  }

                                  await villeProvider.supprimerVille(
                                    villeActuelle,
                                  );

                                  final villeSansId = villeActuelle.copie(
                                    id: null,
                                    isFavorite: false,
                                    forceIdNull: true,
                                  );

                                  await villeProvider.setVilleActuelle(
                                    villeSansId,
                                  );
                                  await lieuProvider.chargerLieux(villeSansId);
                                  await suggestionProvider.chargerSuggestions(
                                    villeSansId,
                                    lieuProvider.lieux,
                                  );

                                  setState(() {});

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ville retirée des visités.',
                                      ),
                                    ),
                                  );
                                }
                              },


                              child: _ActionButton(
                                active: estEnBase,
                                color: Colors.green,
                                icon: Icons.explore_outlined,
                                activeIcon: Icons.explore,
                                label: estEnBase ? 'Visitée' : 'Visiter',
                                couleurTexte: couleurTexte,
                                couleurContour: couleurSubtitle!,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Bouton Favori
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await villeProvider.toggleFavori(villeActuelle);
                                final nouvelleVille =
                                    villeProvider.villeActuelle;
                                if (nouvelleVille != null) {
                                  await applyVilleSelection(
                                    context,
                                    nouvelleVille,
                                  );
                                }
                              },
                              child: _ActionButton(
                                active: estFavori,
                                color: Colors.red,
                                icon: Icons.favorite_border,
                                activeIcon: Icons.favorite,
                                label: estFavori ? 'Favorite' : 'Favoriser',
                                couleurTexte: couleurTexte,
                                couleurContour: couleurSubtitle,
                              ),
                            ),
                          ),
                        ],
                      ),

                      //  Mise en avant (seulement si favorite)
                      if (estFavori) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () async {
                              await villeProvider
                                  .toggleMiseEnAvant(villeActuelle);
                              final nouvelleVille = villeProvider.villeActuelle;
                              if (nouvelleVille != null) {
                                await applyVilleSelection(
                                  context,
                                  nouvelleVille,
                                );
                              }
                            },
                            child: _ActionButton(
                              active: estMiseEnAvant,
                              color: Colors.amber,
                              icon: Icons.star_border,
                              activeIcon: Icons.star,
                              label: estMiseEnAvant
                                  ? 'En avant'
                                  : 'Mettre en avant',
                              couleurTexte: couleurTexte,
                              couleurContour: couleurSubtitle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


// boutton d'action réutilisable pour visité , favori , mise en avant
class _ActionButton extends StatelessWidget {
  final bool active;
  final Color color;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color couleurTexte;
  final Color couleurContour;

  const _ActionButton({
    required this.active,
    required this.color,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.couleurTexte,
    required this.couleurContour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? color : couleurContour,
          width: active ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation lors du changement d’icône 
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              active ? activeIcon : icon,
              key: ValueKey(active),
              color: active ? color : couleurContour,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? color : couleurTexte,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
