import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ville_provider.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/historique_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/commentaires_provider.dart';
import 'ville_selector_dialog.dart';
import '../../utils/ville_loader.dart';

/* barre de recherche de ville */
class VilleSearchBar extends StatefulWidget {
  const VilleSearchBar({super.key});

  @override
  State<VilleSearchBar> createState() => _VilleSearchBarState();
}

class _VilleSearchBarState extends State<VilleSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false; // utilisée pour colorer l'icône de recherche
  bool _estEnChargement = false; // indique si une recherche est en cours

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _rechercherVille() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _estEnChargement = true);

    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final results = await villeProvider.rechercherVille(query);

    setState(() => _estEnChargement = false);

    if (results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune ville trouvée')));
      return;
    }

    // si une seule ville trouvée , on la sélectionne directement
    if (results.length == 1) {
      await villeProvider.selectionnerVille(results.first);
      final historiqueProvider = Provider.of<HistoriqueProvider>(
        context,
        listen: false,
      );

      if (villeProvider.villeActuelle != null) {
        await applyVilleSelection(context, villeProvider.villeActuelle!);
      }
      await historiqueProvider.ajouterRecherche(query);
    } else {
      // sinon on affiche le dialog de sélection
      showDialog(
        context: context,
        builder: (context) => villeSelectorDialog(context, results),
      );
    }

    _controller.clear();
  }

  // passer par gps
  Future<void> _utiliserGPS() async {
    setState(() => _estEnChargement = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() => _estEnChargement = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service de localisation désactivé')),
      );

      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _estEnChargement = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permission refusée')));

        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final villeProvider = Provider.of<VilleProvider>(context, listen: false);

      await villeProvider.selectionnerVilleParPosition(
        position.latitude,
        position.longitude,
      );

      if (villeProvider.villeActuelle != null) {
        final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
        final suggestionProvider = Provider.of<SuggestionProvider>(
          context,
          listen: false,
        );
        final commentaireProvider = Provider.of<CommentaireProvider>(
          context,
          listen: false,
        );
        await lieuProvider.chargerLieux(villeProvider.villeActuelle!);
        await commentaireProvider.chargerCommentaires(lieuProvider.lieux);
        await suggestionProvider.chargerSuggestions(
          villeProvider.villeActuelle!,
          lieuProvider.lieux,
        );
        final historiqueProvider = Provider.of<HistoriqueProvider>(
          context,
          listen: false,
        );
        await historiqueProvider.ajouterRecherche(
          villeProvider.villeActuelle!.name,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur GPS: $e')));
    }

    setState(() => _estEnChargement = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
    final couleurFond = isDark ? Colors.grey[800] : Colors.white;
    final couleurTexte = isDark ? Colors.white : Colors.black87;
    final couleurHint = isDark ? Colors.grey[400] : Colors.grey[600];
    final couleurBordure = isDark ? Colors.grey[600] : Colors.grey[300];

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _controller,
              style: TextStyle(color: couleurTexte),
              onTap: () => setState(() => _isFocused = true),
              onEditingComplete: () => setState(() => _isFocused = false),
              onSubmitted: (_) {
                setState(() => _isFocused = false);
                _rechercherVille();
              },
              decoration: InputDecoration(
                hintText: 'Rechercher une ville...',
                hintStyle: TextStyle(color: couleurHint),
                prefixIcon: Icon(
                  Icons.search,
                  color: _isFocused ? couleurPrincipale : couleurHint,
                ),
                suffixIcon: _estEnChargement
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.loop,
                          color: couleurPrincipale,
                          size: 20,
                        ),
                      )
                    : (_controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: couleurHint),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            )
                          : null),
                filled: true,
                fillColor: couleurFond,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: couleurBordure!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: couleurBordure),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: couleurPrincipale, width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: couleurFond,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(
              Icons.my_location,
              color: _estEnChargement
                  ? couleurPrincipale.withOpacity(0.5)
                  : couleurPrincipale,
            ),
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            onPressed: _estEnChargement ? null : _utiliserGPS,
            tooltip: 'Utiliser ma position',
          ),
        ),
      ],
    );
  }
}
