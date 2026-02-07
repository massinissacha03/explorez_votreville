import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/lieu.dart';
import '../../models/ville.dart';
import '../../providers/lieu_provider.dart';
import '../../utils/commun.dart';
import '../../providers/ville_provider.dart';
import '../lieu/lieu_card.dart';
import '../../providers/suggestion_provider.dart';
import '../../utils/ville_loader.dart';

/* un widget interactif pour afficher une carte avec des marqueurs de lieux */
class CarteInteractive extends StatefulWidget {
  final List<Lieu> lieux;
  final LatLng centre;

  const CarteInteractive({
    super.key,
    required this.lieux,
    required this.centre,
  });

  @override
  State<CarteInteractive> createState() => _CarteInteractiveState();
}

class _CarteInteractiveState extends State<CarteInteractive> {
  final MapController _mapController = MapController();
  late List<Marker> _markers;

  // initialiser les marqueurs
  @override
  void initState() {
    super.initState();

    _buildMarkers();
  }


  // mettre à jour , si les lieux ou le centre changent
  @override
  void didUpdateWidget(CarteInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lieux.length != widget.lieux.length ||
        oldWidget.lieux != widget.lieux) {
      _buildMarkers();
    }

    if (oldWidget.centre.latitude != widget.centre.latitude ||
        oldWidget.centre.longitude != widget.centre.longitude) {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(widget.centre, currentZoom == 0 ? 13.0 : currentZoom);
    }
  }

  // construire les marqueurs à partir des lieux 
  void _buildMarkers() {
    _markers = widget.lieux.map((lieu) {
      return Marker(
        point: LatLng(lieu.latitude, lieu.longitude),
        width: 40,
        height: 40,
        child: _MarkerWidget(lieu: lieu),
      );
    }).toList();
  }



  @override
  Widget build(BuildContext context) {
    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.centre,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'explorezvotreville',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: couleurPrincipale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${widget.lieux.length} lieu${widget.lieux.length > 1 ? 'x' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// un widget d'un marqueur individuel 
// stack de deux icones , cliquable pour afficher le dialog du lieu (rouge si favori , vert sinon)
class _MarkerWidget extends StatelessWidget {
  final Lieu lieu;

  const _MarkerWidget({required this.lieu});

  @override
  Widget build(BuildContext context) {
    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);

    return GestureDetector(
      onTap: () => _showLieuDialog(context, lieu),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 40,
            color: lieu.estFavori ? Colors.red : couleurPrincipale,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
          Positioned(
            top: 8,
            child: Icon(
              Commun.getIconeCategorie(lieu.categorie),
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  // afficher le dialog du lieu
  void _showLieuDialog(BuildContext context, Lieu lieu) {
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final villeActuelle = villeProvider.villeActuelle;
    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // La LieuCard
              lieuCard(context, lieu),

              const SizedBox(height: 8),

              // Petits boutons en bas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fermer
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(dialogContext),
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(width: 12),

                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        lieu.estFavori ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                      ),
                      onPressed: () async {
                        if (villeActuelle == null) return;

                        final lieuProvider = Provider.of<LieuProvider>(
                          dialogContext,
                          listen: false,
                        );

                        final suggestionProvider =
                            Provider.of<SuggestionProvider>(
                              dialogContext,
                              listen: false,
                            );
                        final etaitFavori = lieu.estFavori;
                        // S'assurer que la ville est enregistrée comme visitée
                        Ville villeReady = villeActuelle;
                        if (villeReady.id == null) {
                          villeReady = await villeProvider.marquerCommeVisitee(
                            villeReady,
                          );
                          await applyVilleSelection(dialogContext, villeReady);
                        }

                        final lieuExisteDansBDD = lieuProvider.lieux.any(
                          (l) => l.id == lieu.id,
                        );

                        if (lieu.id == null || !lieuExisteDansBDD) {
                          await lieuProvider.ajouterLieu(
                            lieu.copie(
                              estFavori: true,
                              villeId: villeReady.id ?? lieu.villeId,
                            ),
                            villeFavorite: true,
                          );
                          suggestionProvider.retirerDesSuggestions(lieu);
                        } else {
                          await lieuProvider.toggleFavori(lieu.id!);

                          if (etaitFavori) {
                            suggestionProvider.ajouterAuxSuggestions(
                              lieu.copie(
                                id: null,
                                estFavori: false,
                                noteMoyenne: null,
                              ),
                            );
                          } else {
                            suggestionProvider.retirerDesSuggestions(lieu);
                          }
                        }

                        Navigator.pop(dialogContext);
                      },
                      color: lieu.estFavori ? Colors.red : couleurPrincipale,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Détails
                  Container(
                    decoration: BoxDecoration(
                      color: couleurPrincipale,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.zoom_out_map, size: 20),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.of(context).pushNamed(
                          '/main/details/${Uri.encodeComponent(lieu.nom)}',
                          arguments: lieu,
                        );
                      },
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


/* le dialog a trois boutton en dessous de la cardLieu , fermer , aimer (le lieu) , 
            details(naviguer vers la page details) */
