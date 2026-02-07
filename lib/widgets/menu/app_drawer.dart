import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ville_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/historique_provider.dart';
import 'header_section.dart';
import 'villes_list_section.dart';
import 'villes_dialog.dart';
import 'rayon_recherche_section.dart';

/* app drawer */
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final couleurPrincipale = const Color.fromARGB(255, 0, 92, 20);

    return Drawer(
      child: _DrawerContent(
        isDark: isDark,
        themeProvider: themeProvider,
        couleurPrincipale: couleurPrincipale,
      ),
    );
  }
}

class _DrawerContent extends StatefulWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final Color couleurPrincipale;

  const _DrawerContent({
    required this.isDark,
    required this.themeProvider,
    required this.couleurPrincipale,
  });

  @override
  State<_DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<_DrawerContent> {
  // Pour l'animation des villes favorites
  final Set<int> _visibleIndices = {}; // Indices des villes visibles
  int _lastCount = 0; // Dernier nombre de villes visibles

  //  apparition des villes favorites
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final villes = Provider.of<VilleProvider>(context, listen: false).villes;
    _triggerAnimation(villes.where((v) => v.id != null && v.isFavorite).length);
  }

  int _animToken = 0;

  void _triggerAnimation(int count) {
    if (count == _lastCount) return; // pas de changement
    _lastCount = count; // mettre à jour le compte

    _animToken++; // incrémenter le token d'animation
    final token = _animToken; // capturer le token actuel

    _visibleIndices.clear(); // vider les indices visibles
    setState(() {});

    _runReveal(count, token); // lance l'animation 
  }

  Future<void> _runReveal(int count, int token) async {
    await Future.delayed(Duration.zero); // attendre le prochain frame

    for (var i = 0; i < count; i++) {

      await Future.delayed(const Duration(milliseconds: 90));

      setState(() => _visibleIndices.add(i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final villeProvider = Provider.of<VilleProvider>(context);
    final villes = villeProvider.villes;

    // Seulement les villes FAVORITES pour le drawer
    final villesFavorites = villes
        .where((v) => v.id != null && v.isFavorite)
        .toList();

    final villeMiseEnAvant = villesFavorites
        .where((v) => v.estMiseEnAvant(villeProvider.villeMiseEnAvantId))
        .firstOrNull;
    _triggerAnimation(villesFavorites.length);


    return Column(
      children: [
        drawerHeaderSection(widget.isDark, villeMiseEnAvant),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                Icons.location_city_outlined,
                color: widget.couleurPrincipale,
              ),
              label: Text(
                'Voir toutes mes villes visitées',
                style: TextStyle(color: widget.couleurPrincipale),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(
                  color: widget.couleurPrincipale.withAlpha(153),
                ),
                backgroundColor: widget.isDark
                    ? Colors.white.withAlpha(13)
                    : Colors.white.withAlpha(204),
              ),
              onPressed: () => showVillesVisiteesDialog(context, villes),
            ),
          ),
        ),
        Expanded(
          child: villesFavorites.isEmpty
              ? _buildEmptyState()
              : villesListSection(
                  context,
                  villesFavorites,
                  villeProvider,
                  widget.isDark,
                  _visibleIndices,
                ),
        ),
        const Divider(),
        _buildDarkModeSwitch(
          widget.themeProvider,
          widget.isDark,
          widget.couleurPrincipale,
        ),
        rayonRechercheSection(widget.couleurPrincipale),
        const Divider(),
        _buildResetButton(context, villeProvider),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune ville favorite',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Marquez une ville comme favorite pour la voir ici',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

}

Widget _buildDarkModeSwitch(
  ThemeProvider themeProvider,
  bool isDark,
  Color couleurPrincipale,
) {
  return SwitchListTile(
    activeThumbColor: couleurPrincipale,
    title: const Text('Mode sombre'),
    secondary: Icon(
      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
    ),
    value: themeProvider.isDarkMode,
    onChanged: (value) {
      themeProvider.toggleTheme();
    },
  );
}



Widget _buildResetButton(BuildContext context, VilleProvider villeProvider) {
  return ListTile(
    leading: const Icon(Icons.restart_alt, color: Colors.red),
    title: const Text(
      'Réinitialiser l\'application',
      style: TextStyle(color: Colors.red),
    ),
    onTap: () async {
      await villeProvider.reinitialiserApplication();
      final historiqueProvider = Provider.of<HistoriqueProvider>(
        context,
        listen: false,
      );
      await historiqueProvider.viderHistorique();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application réinitialisée'),
          duration: Duration(seconds: 2),
        ),
      );
    },
  );
}
