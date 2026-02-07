import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ville_provider.dart';
import '../../models/lieu.dart';
import '../../utils/commun.dart';

import '../../providers/suggestion_provider.dart';
import '../../providers/lieu_provider.dart';
import '../../utils/ville_loader.dart';

/* dialog pour rechercher un lieu par nom */

class LieuSearchDialog extends StatefulWidget {
  const LieuSearchDialog({super.key});

  @override
  State<LieuSearchDialog> createState() => _LieuSearchDialogState();
}

class _LieuSearchDialogState extends State<LieuSearchDialog> {
  final TextEditingController _nomController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    final nom = _nomController.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de lieu')),
      );
      return;
    }

    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final suggestionProvider = Provider.of<SuggestionProvider>(
      context,
      listen: false,
    );
    final ville = villeProvider.villeActuelle;

    if (ville == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune ville sélectionnée')),
      );
      return;
    }

    setState(() => _isSearching = true);

    // Appel API sans filtre de catégorie
    final resultats = await suggestionProvider.rechercherLieuParNom(
      nom,
      'Autre',
      ville.latitude,
      ville.longitude,
    );

    setState(() => _isSearching = false);

    if (resultats.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucun lieu trouvé')));
    } else {
      Navigator.pop(context);
      _afficherResultats(resultats);
    }
  }

  // afficher les résultats dans un dialog avec choix de catégorie
  void _afficherResultats(List<Lieu> resultats) {
    showDialog(
      context: context,
      builder: (context) => _DialogResultats(resultats: resultats),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.search, color: Color.fromARGB(255, 0, 92, 20)),
          SizedBox(width: 8),
          Text('Rechercher un lieu'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'Nom du lieu',
              hintText: 'Ex: Tour Eiffel, Louvre...',
              prefixIcon: const Icon(Icons.place),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _isSearching ? null : _rechercher,
          icon: _isSearching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(_isSearching ? 'Recherche...' : 'Rechercher'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 92, 20),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Dialog pour afficher les résultats avec choix de catégorie
class _DialogResultats extends StatefulWidget {
  final List<Lieu> resultats;

  const _DialogResultats({required this.resultats});

  @override
  State<_DialogResultats> createState() => _DialogResultatsState();
}

class _DialogResultatsState extends State<_DialogResultats> {
  final Map<int, String> _categoriesChoisies = {};

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < widget.resultats.length; i++) {
      _categoriesChoisies[i] = widget.resultats[i].categorie;
    }
  }

  void _ajouterAuxSuggestions(int index) async {
    final lieu = widget.resultats[index];
    final categorieChoisie = _categoriesChoisies[index]!;

    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
    var ville = villeProvider.villeActuelle;

    if (ville == null) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Aucune ville sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ville.id == null) {
      ville = await villeProvider.marquerCommeVisitee(ville);
      await applyVilleSelection(context, ville);
    }

    // Créer le lieu avec la catégorie choisie et en favori
    final lieuAvecCategorie = lieu.copie(
      villeId: ville.id ?? 0,
      categorie: categorieChoisie,
      estFavori: true, // ajouté aux favoris
    );

    final ajout = await lieuProvider.ajouterLieu(lieuAvecCategorie);

    // Retirer des suggestions pour éviter les doublons (liste + carte)
    final suggestionProvider = Provider.of<SuggestionProvider>(
      context,
      listen: false,
    );
    if (ajout != null) {
      suggestionProvider.retirerDesSuggestions(ajout);
      await lieuProvider.chargerLieux(ville);
      await suggestionProvider.chargerSuggestions(ville, lieuProvider.lieux);
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    if (ajout != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${lieu.nom} ajouté aux favoris ❤️'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ajouter ce lieu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.list_alt_outlined,
            color: Color.fromARGB(255, 0, 92, 20),
          ),
          const SizedBox(width: 8),
          const Text('Lieux trouvés'),
          const Spacer(),
          Chip(
            label: Text('${widget.resultats.length}'),
            backgroundColor: const Color.fromARGB(255, 0, 92, 20),
            labelStyle: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.resultats.length,
          itemBuilder: (context, index) {
            final lieu = widget.resultats[index];
            final categorieChoisie = _categoriesChoisies[index]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du lieu
                    Row(
                      children: [
                        Icon(
                          Commun.getIconeCategorie(categorieChoisie),
                          size: 24,
                          color: const Color.fromARGB(255, 0, 92, 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lieu.nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Dropdown pour choisir catégorie
                    DropdownButtonFormField<String>(
                      initialValue: categorieChoisie,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: Commun.categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(Commun.getIconeCategorie(cat), size: 16),
                              const SizedBox(width: 8),
                              Text(cat, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newCat) {
                        setState(() {
                          _categoriesChoisies[index] = newCat!;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    // Bouton ajouter
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _ajouterAuxSuggestions(index),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Ajouter à la carte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 92, 20),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
