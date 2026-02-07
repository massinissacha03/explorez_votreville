import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ville_provider.dart';
import '../providers/lieu_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/menu/app_drawer.dart';
import '../widgets/ville/ville_search_bar.dart';
import '../widgets/ville/ville_historique.dart';
import '../widgets/lieu/categories_filter_row.dart';
import '../widgets/meteo/meteo_card.dart';
import '../widgets/lieu/liste_de_lieux.dart';
import '../widgets/carte/carte_des_lieux.dart';
import '../widgets/lieu/lieu_form.dart';
import '../widgets/lieu/lieu_search_dialog.dart';
import '../providers/suggestion_provider.dart';
import '../providers/commentaires_provider.dart';
import '../models/ville.dart';
import '../utils/ville_loader.dart';

/* ecran principal qui rassemble les differentes parties de l'application */
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // true au demarrage de l'appli  , pour afficher le spinner
  bool _premiereCharge = true;
  bool _fabOuvert = false; // pour savoir si le  est ouvert ou non
  bool _listenerRegistered = false;
  String? _lastVilleKey;

  // cle unique pour une ville afin de detecter un changement
  String _villeKey(Ville? ville) {
    if (ville == null) return 'null';
    return '${ville.id ?? 'tmp'}-${ville.latitude}-${ville.longitude}';
  }

  // appelée à chaque fois que le provider change
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      villeProvider.addListener(_onVilleChange);
    }
    // si ville provider fini son initialisation et c'est la première fois
    // au début ça me donne ville=null car le provider n'est pas encore initialisé
    if (_premiereCharge && villeProvider.isInitialized) {
      _chargerLieux();
    }
  }

  @override
  void dispose() {
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    villeProvider.removeListener(_onVilleChange);
    super.dispose();
  }

  // declenchee quand la ville courante change (selection ou mise a jour)
  Future<void> _onVilleChange() async {
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
    final suggestionProvider = Provider.of<SuggestionProvider>(
      context,
      listen: false,
    );
    final commentaireProvider = Provider.of<CommentaireProvider>(
      context,
      listen: false,
    );
    // rien a faire s'il n'y a aucune ville sélectionnee
    final ville = villeProvider.villeActuelle;
    final currentKey = _villeKey(ville);
    if (_lastVilleKey == currentKey) return;
    _lastVilleKey = currentKey;

    if (ville == null) return;

    await lieuProvider.chargerLieux(ville);
    await commentaireProvider.chargerCommentaires(lieuProvider.lieux);
    await suggestionProvider.chargerSuggestions(ville, lieuProvider.lieux);
    setState(() {});
  }

  // fonction pour recharger les lieux de la ville courante
  Future<void> _chargerLieux() async {
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
    final suggestionProvider = Provider.of<SuggestionProvider>(
      context,
      listen: false,
    );
    final commentaireProvider = Provider.of<CommentaireProvider>(
      context,
      listen: false,
    );

    final ville = villeProvider.villeActuelle;
    if (ville != null) {
      // Si une ville est sélectionnée, on charge ses lieux
      await lieuProvider.chargerLieux(ville);
      await commentaireProvider.chargerCommentaires(lieuProvider.lieux);
      await suggestionProvider.chargerSuggestions(ville, lieuProvider.lieux);
    }
    // on a fini la première charge
    if (_premiereCharge) {
      setState(() => _premiereCharge = false);
    }
  }

  // fonction pour creer un nouveau lieu
  // en appelant le LieuForm
  Future<void> _creationLieu() async {
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    var ville = villeProvider.villeActuelle;
    if (ville == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune ville sélectionnée')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => LieuForm(ville: ville!),
    );

    // si la ville actuelle n'est pas en BDD on la crée d'abord
    if (ville.id == null) {
      ville = await villeProvider.marquerCommeVisitee(ville);
      await applyVilleSelection(context, ville);
    }

    setState(() => _fabOuvert = false); // fermer le FAB
  }

  // fonction pour ouvrir le dialog de recherche
  void _rechercherLieu() {
    setState(() => _fabOuvert = false); // fermer le FAB

    showDialog(
      context: context,
      builder: (context) => const LieuSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final villeProvider = Provider.of<VilleProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final ville = villeProvider.villeActuelle;

    // on affiche le spinner si le provider n'est pas initialisé ou si c'est la première charge
    final afficherSpinner = !villeProvider.isInitialized || _premiereCharge;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color.fromARGB(255, 0, 0, 0),
                  Color.fromARGB(255, 0, 92, 20),
                ]
              : const [
                  Color.fromARGB(255, 0, 92, 20),
                  Color.fromARGB(255, 0, 0, 0),
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white, // tout en blanc
          title: const Text('Explorez Votre Ville'),
        ),
        body: SafeArea(
          child: afficherSpinner
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : ListView(
                  // contenu principal quand tout est prêt
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: VilleSearchBar(),
                    ),
                    Padding(
                      // centrer l'historique avec padding geuche droite
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: villeHistorique(context),
                    ),
                    // affichage spécifique selon qu'une ville est choisie ou non
                    if (ville == null)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_city,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucune ville sélectionnée',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Recherchez une ville ci-dessus',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    if (ville != null) ...[
                      // carte météo 
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: MeteoCard(
                          nomVille: ville.name,
                          meteo: villeProvider.meteoActuelle,
                          ville: ville,
                        ),
                      ),
                      // filtres des catégories pour affiner les lieux
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: categoriesFilterRow(context),
                      ),
                      const SizedBox(height: 16),
                      // on appelle la carte des lieux
                      carteDesLieux(context),
                      // la liste des lieux favoris
                      listDeLieux(context),
                    ],
                  ],
                ),
        ),
        // le floating button sert à chercher ou créer un lieu
        floatingActionButton: ville == null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Action 1 : Rechercher
                  if (_fabOuvert) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Rechercher un lieu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          mini: true,
                          onPressed: _rechercherLieu,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromARGB(255, 0, 92, 20),
                          child: const Icon(Icons.search),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    //  Creer manuellement
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Créer manuellement',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          mini: true,
                          onPressed: _creationLieu,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromARGB(255, 0, 92, 20),
                          child: const Icon(Icons.add_location_alt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  FloatingActionButton(
                    onPressed: () {
                      setState(() => _fabOuvert = !_fabOuvert);
                    },
                    backgroundColor: const Color.fromARGB(255, 0, 92, 20),
                    child: Icon(
                      _fabOuvert ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
