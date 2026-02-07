import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/lieu_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ville_provider.dart';
import '../providers/suggestion_provider.dart';
import '../models/lieu.dart';
import '../utils/commun.dart';
import '../widgets/commentaire/commentaire_form.dart';
import '../widgets/commentaire/commentaire_liste.dart';
import '../utils/ville_loader.dart';

/* un screen , pour les details d'un lieu --- /main/details/<nom_du_lieu> */

class DetailsScreen extends StatefulWidget {
  final Lieu lieu;

  const DetailsScreen({super.key, required this.lieu});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  // lieu courant
  late Lieu _lieu;

  @override
  void initState() {
    // initialisation du lieu (récupéré en argument)
    super.initState();
    _lieu = widget.lieu;
  }

  // savoir si le lieu est en bdd
  bool get _estEnBase => _lieu.id != null;

  // suppression d'un lieu
  Future<void> _supprimerLieu(
    LieuProvider lieuProvider,
    SuggestionProvider suggestionProvider,
  ) async {
    if (!_estEnBase) return;

    await lieuProvider.supprimerLieu(_lieu.id!);

    // creation un nouveau lieu identique mais pas en bdd
    // et le remettre dans les suggestions
    final lieuSansBDD = Lieu(
      villeId: _lieu.villeId,
      nom: _lieu.nom,
      description: _lieu.description,
      categorie: _lieu.categorie,
      latitude: _lieu.latitude,
      longitude: _lieu.longitude,
      estFavori: false,
      telephone: _lieu.telephone,
      email: _lieu.email,
      siteWeb: _lieu.siteWeb,
      adresse: _lieu.adresse,
      accessibiliteHandicape: _lieu.accessibiliteHandicape,
    );

    suggestionProvider.ajouterAuxSuggestions(lieuSansBDD);

    // on remplace l'ecran actuel de lieu en bdd par le meme lieu mais pas en bdd
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DetailsScreen(lieu: lieuSansBDD)),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lieu supprimé')));
  }

  // basculer le statut favori d'un lieu
  Future<void> _toggleFavori(
    LieuProvider lieuProvider,
    VilleProvider villeProvider,
  ) async {
    final suggestionProvider = Provider.of<SuggestionProvider>(
      context,
      listen: false,
    );

    var ville = villeProvider.villeActuelle;
    if (ville == null) return;

    // si la ville n'est pas en base , on la marque comme visitée (ce qui l'ajoute en bdd)
    if (ville.id == null) {
      ville = await villeProvider.marquerCommeVisitee(ville);
      await applyVilleSelection(context, ville);
    }

    // si le lieu n'est pas en base , on l'ajoute en bdd et on le met en favori sinon on bascule le statut favori
    if (!_estEnBase) {
      final nouveau = await lieuProvider.ajouterLieu(
        _lieu.copie(estFavori: true, villeId: ville.id ?? _lieu.villeId),
      );
      if (nouveau != null) {
        setState(() {
          _lieu = nouveau.copie(estFavori: true);
        });
        suggestionProvider.retirerDesSuggestions(_lieu);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lieu enregistré et ajouté aux favoris.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    await lieuProvider.toggleFavori(_lieu.id!);

    setState(() {
      _lieu = _lieu.copie(estFavori: !_lieu.estFavori);
    });

    // soit message d'ajout ou retrait des suggestions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lieu.estFavori ? 'Ajouté aux favoris ❤️' : 'Retiré des favoris',
        ),
        backgroundColor: _lieu.estFavori ? Colors.red : Colors.grey,
      ),
    );
  }

  // Ouvre un lien web  https:// s'il ne l'a pas
  Future<void> _ouvrirLien(String? url) async {
    if (url == null || url.trim().isEmpty) return;

    final urlComplete = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.tryParse(urlComplete);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final lieuProvider = Provider.of<LieuProvider>(context);
    final villeProvider = Provider.of<VilleProvider>(context);
    final suggestionProvider = Provider.of<SuggestionProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final couleurPrincipale = const Color.fromARGB(255, 0, 92, 20);
    final couleurTexte = isDark ? Colors.white : Colors.black87;

    final imagePath = Commun.getImageCategorie(_lieu.categorie);
    final heroTag =
        'lieu-${_lieu.id ?? '${_lieu.latitude}-${_lieu.longitude}'}';

    //le lieu mis a jour

    Lieu? lieuMaj;

    // si le lieu est en bdd , on cherche la version la plus récente dans le provider
    if (_lieu.id != null) {
      try {
        lieuMaj = lieuProvider.lieux.firstWhere((l) => l.id == _lieu.id);
      } catch (_) {}
    } else {
      try {
        // si le lieu vient d'être créé (ex: via commentaire), on le retrouve par lat/lon dans les lieux en base
        lieuMaj = lieuProvider.lieux.firstWhere(
          (l) => l.latitude == _lieu.latitude && l.longitude == _lieu.longitude,
        );
      } catch (_) {}
      // sinon on cherche par lat/lon dans les suggestions
      if (lieuMaj == null) {
        try {
          lieuMaj = suggestionProvider.suggestions.firstWhere(
            (l) =>
                l.latitude == _lieu.latitude && l.longitude == _lieu.longitude,
          );
        } catch (_) {}
      }
    }

    // on check si on doit m a jour le lieu courant
    final needsUpdate =
        lieuMaj != null &&
        (lieuMaj.id != _lieu.id || lieuMaj.estFavori != _lieu.estFavori);

    if (needsUpdate) {
      setState(() {
        _lieu = lieuMaj!;
      });
    }
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea(
        // sert a faire un scroll avec appbar flexible
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                title: Text(
                  _lieu.nom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Image.asset(
                        'assets/$imagePath',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Bouton supprimer (seulement si en base)
                if (_estEnBase)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: 'Supprimer',
                    onPressed: () =>
                        _supprimerLieu(lieuProvider, suggestionProvider),
                  ),

                // Bouton modifier
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: 'Modifier',
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/main/details/${Uri.encodeComponent(_lieu.nom)}/modification',
                      arguments: _lieu,
                    );
                    // récupérer le lieu modifié
                    if (result != null && result is Lieu) {
                      setState(() {
                        _lieu = result;
                      });
                    }
                  },
                ),

                // Bouton favori
                IconButton(
                  icon: Icon(
                    _lieu.estFavori ? Icons.favorite : Icons.favorite_border,
                    color: _lieu.estFavori ? Colors.red : Colors.white,
                  ),
                  tooltip: _lieu.estFavori
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: () => _toggleFavori(lieuProvider, villeProvider),
                ),
              ],
            ),

            // Contenu de la page
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: couleurPrincipale,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Commun.getIconeCategorie(_lieu.categorie),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _lieu.categorie,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_lieu.noteMoyenne != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _lieu.noteMoyenne!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: couleurTexte,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Description
                    if (_lieu.description != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: couleurPrincipale,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    color: couleurTexte,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _lieu.description!,
                              style: TextStyle(
                                color: couleurTexte,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    //  Informations pratiques
                    if (_lieu.telephone != null ||
                        _lieu.email != null ||
                        _lieu.siteWeb != null ||
                        _lieu.adresse != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: couleurPrincipale),
                                const SizedBox(width: 8),
                                Text(
                                  'Informations pratiques',
                                  style: TextStyle(
                                    color: couleurTexte,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_lieu.adresse != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: couleurTexte),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _lieu.adresse!,
                                      style: TextStyle(color: couleurTexte),
                                    ),
                                  ),
                                ],
                              ),

                            if (_lieu.telephone != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, color: couleurTexte),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _lieu.telephone!,
                                      style: TextStyle(color: couleurTexte),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (_lieu.email != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.email, color: couleurTexte),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _lieu.email!,
                                      style: TextStyle(color: couleurTexte),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (_lieu.siteWeb != null) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _ouvrirLien(_lieu.siteWeb),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.language,
                                      color: couleurPrincipale,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _lieu.siteWeb!,
                                        style: TextStyle(
                                          color: couleurPrincipale,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    //  Accessibilite PMR
                    if (_lieu.accessibiliteHandicape == true) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.accessible,
                                  color: couleurPrincipale,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Accessibilité',
                                  style: TextStyle(
                                    color: couleurTexte,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.accessible,
                                  color: couleurTexte,
                                  size: 30,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Accessible aux personnes à mobilité réduite',
                                    style: TextStyle(
                                      color: couleurTexte,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Row(
                      children: [
                        Icon(Icons.map, color: couleurPrincipale, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Localisation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: couleurTexte,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Carte avec le lieu
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _lieu.latitude,
                              _lieu.longitude,
                            ),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'explorezvotreville',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _lieu.latitude,
                                    _lieu.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    size: 40,
                                    color: _lieu.estFavori
                                        ? Colors.red
                                        : couleurPrincipale,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Section commentaires
                    Row(
                      children: [
                        Icon(
                          Icons.rate_review,
                          color: couleurPrincipale,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ajouter un commentaire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: couleurTexte,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Formulaire d'ajout de commentaire
                    CommentaireForm(lieu: _lieu),
                    // widget pour afficher la liste des commentaires
                    CommentaireListe(lieuId: _lieu.id),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
