import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../models/lieu.dart';
import '../../models/ville.dart';
import '../../providers/theme_provider.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../utils/commun.dart';
import '../carte/selection_position_carte.dart';
import '../../providers/ville_provider.dart';
import '../../utils/ville_loader.dart';

// formuulaire appelé avec AlertiDialog pour créer un nouveau lieu non trouvé avec api

class LieuForm extends StatefulWidget {
  final Ville ville;

  const LieuForm({super.key, required this.ville});

  @override
  State<LieuForm> createState() => _LieuFormState();
}

class _LieuFormState extends State<LieuForm> {
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _categorieSelectionnee = Commun.categories.first; // par defaut
  late double _latitude;
  late double _longitude;
  bool _positionChoisie = false;

  @override
  void initState() {
    super.initState();
    // par defaut la position de la ville
    _latitude = widget.ville.latitude;
    _longitude = widget.ville.longitude;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    final nom = _nomController.text.trim();

    if (nom.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le nom est obligatoire')));
      return;
    }

    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final suggestionProvider = Provider.of<SuggestionProvider>(
      context,
      listen: false,
    );
    var ville = widget.ville;

    if (ville.id == null) {
      ville = await villeProvider.marquerCommeVisitee(ville);
      await applyVilleSelection(context, ville);
    }

    final lieu = Lieu(
      villeId: ville.id ?? 0,
      nom: nom,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categorie: _categorieSelectionnee,
      latitude: _latitude,
      longitude: _longitude,
      estFavori: true,
    );

    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);

    final ajout = await lieuProvider.ajouterLieu(
      lieu,
      villeFavorite: ville.isFavorite,
    );

    if (ajout != null) {
      // Retirer des suggestions pour éviter le doublon (liste + carte)
      suggestionProvider.retirerDesSuggestions(ajout);
      // Rafraîchir les listes locales pour la carte et les favoris
      await lieuProvider.chargerLieux(ville);
      await suggestionProvider.chargerSuggestions(ville, lieuProvider.lieux);
    }

    Navigator.pop(context);

    if (ajout != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${lieu.nom} ajouté')));
    }
  }

  // on fait appel à la carte pour choisir la position en lui passant
  // la position initiale actuelle modifiable
  Future<void> _ouvrirCarte(bool isDark) async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionPositionCarte(
          positionInitiale: LatLng(_latitude, _longitude),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _positionChoisie = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
    final couleurFond = isDark ? Colors.grey[900] : Colors.white;
    final couleurTexte = isDark ? Colors.white : Colors.black87;
    final couleurSubtitle = isDark ? Colors.grey[400] : Colors.grey[600];
    final couleurChamp = isDark ? Colors.grey[800] : Colors.grey[50];

    return AlertDialog(
      backgroundColor: couleurFond,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),

            child: const Icon(
              Icons.add_location,
              color: couleurPrincipale,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ajouter un lieu',
              style: TextStyle(
                color: couleurTexte,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomController,
            autofocus: true,
            style: TextStyle(color: couleurTexte),
            decoration: InputDecoration(
              hintText: 'Nom du lieu *',
              hintStyle: TextStyle(color: couleurSubtitle),
              prefixIcon: const Icon(Icons.place, color: couleurPrincipale),
              filled: true,
              fillColor: couleurChamp,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: couleurPrincipale, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _categorieSelectionnee,
            dropdownColor: couleurChamp,
            style: TextStyle(color: couleurTexte),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category, color: couleurPrincipale),
              filled: true,
              fillColor: couleurChamp,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: couleurPrincipale, width: 2),
              ),
            ),
            items: Commun.categories.map((categorie) {
              return DropdownMenuItem(value: categorie, child: Text(categorie));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _categorieSelectionnee = value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: TextStyle(color: couleurTexte),
            decoration: InputDecoration(
              hintText: 'Description (optionnel)',
              hintStyle: TextStyle(color: couleurSubtitle),
              prefixIcon: const Icon(
                Icons.description,
                color: couleurPrincipale,
              ),
              filled: true,
              fillColor: couleurChamp,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: couleurPrincipale, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.map, color: couleurPrincipale),
            label: Text(
              _positionChoisie
                  ? 'Modifier la position sur la carte'
                  : 'Choisir la position sur la carte',
              style: TextStyle(color: couleurTexte),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _ouvrirCarte(isDark),
          ),
          if (_positionChoisie) ...[
            const SizedBox(height: 8),
            Text(
              'Lat: ${_latitude.toStringAsFixed(4)}  |  Lon: ${_longitude.toStringAsFixed(4)}',
              style: TextStyle(color: couleurSubtitle, fontSize: 12),
            ),
          ],
        ],
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: couleurSubtitle)),
        ),

        ElevatedButton.icon(
          onPressed: () => {_sauvegarder(), Navigator.pop(context)},

          icon: const Icon(Icons.save, size: 18),
          label: const Text('Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: couleurPrincipale,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
