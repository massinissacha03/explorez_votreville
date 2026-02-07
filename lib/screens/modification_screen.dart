import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lieu_provider.dart';
import '../providers/ville_provider.dart';
import '../providers/theme_provider.dart';
import '../models/lieu.dart';
import '../utils/commun.dart';
import '../utils/ville_loader.dart';

/* ecran de modification d'un lieu */
class ModificationScreen extends StatefulWidget {
  final Lieu lieu;

  const ModificationScreen({super.key, required this.lieu});

  @override
  State<ModificationScreen> createState() => _ModificationScreenState();
}

class _ModificationScreenState extends State<ModificationScreen> {
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _siteWebController;
  late TextEditingController _adresseController;

  late String _categorieSelectionnee;
  late bool _accessibilite;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nomController = TextEditingController(text: widget.lieu.nom);
    _descriptionController = TextEditingController(
      text: widget.lieu.description ?? '',
    );
    _telephoneController = TextEditingController(
      text: widget.lieu.telephone ?? '',
    );
    _emailController = TextEditingController(text: widget.lieu.email ?? '');
    _siteWebController = TextEditingController(text: widget.lieu.siteWeb ?? '');
    _adresseController = TextEditingController(text: widget.lieu.adresse ?? '');

    _categorieSelectionnee = widget.lieu.categorie;
    _accessibilite = widget.lieu.accessibiliteHandicape == true;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _siteWebController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  bool _validerFormulaire() {
    final nom = _nomController.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le nom est obligatoire')));
      return false;
    }
    return true;
  }

  // decoration des champs de texte
  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    required Color couleurPrincipale,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: couleurPrincipale,
        fontWeight: FontWeight.w700,
      ),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.withAlpha(180)),
      prefixIcon: Icon(icon),
      prefixIconColor: couleurPrincipale,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withAlpha(80)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: couleurPrincipale, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.withAlpha(25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // section reusable
  Widget _section({
    required String title,
    required IconData icon,
    required Color accent,
    required bool isDark,
    required List<Widget> children,
  }) {
    final bg = isDark ? Colors.grey.shade900.withAlpha(160) : Colors.white;
    final border = isDark
        ? Colors.white.withAlpha(25)
        : Colors.black.withAlpha(15);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),

            //
            const SizedBox(height: 12),
            Column(children: children),
          ],
        ),
      ),
    );
  }

  // enregistrer les modifications
  Future<void> _enregistrer() async {
    if (_saving) return;
    if (!_validerFormulaire()) return;

    setState(() => _saving = true);

    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);

    final lieuModifie = widget.lieu.copie(
      nom: _nomController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categorie: _categorieSelectionnee,
      telephone: _telephoneController.text.trim().isEmpty
          ? null
          : _telephoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      siteWeb: _siteWebController.text.trim().isEmpty
          ? null
          : _siteWebController.text.trim(),
      adresse: _adresseController.text.trim().isEmpty
          ? null
          : _adresseController.text.trim(),
      accessibiliteHandicape: _accessibilite,
    );

    // si le lieu est déjà en base on modifie juste
    if (widget.lieu.id != null) {
      try {
        await lieuProvider.modifierLieu(lieuModifie);
      } catch (_) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la modification'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _saving = false);

      Navigator.pop(context, lieuModifie);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lieu modifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // sinon on ajoute le lieu en base donc on doit s'assurer que la ville est visitée
    var ville = villeProvider.villeActuelle;
    if (ville == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Aucune ville sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Assurer que la ville est visitée
    if (ville.id == null) {
      try {
        ville = await villeProvider.marquerCommeVisitee(ville);
        await applyVilleSelection(context, ville);
      } catch (_) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de la ville'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Enregistrer le lieu en base
    Lieu? lieuEnregistre;
    try {
      lieuEnregistre = await lieuProvider.ajouterLieu(
        lieuModifie.copie(
          estFavori: false,
          villeId: ville.id ?? lieuModifie.villeId,
        ),
      );
    } catch (_) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l’enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    
    setState(() => _saving = false);

    if (lieuEnregistre != null) {
      Navigator.pop(context, lieuEnregistre);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lieu modifié et enregistré'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur lors de l’enregistrement'),
        backgroundColor: Colors.red,
      ),
    );
  }


  // 
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
    final bg = isDark ? const Color(0xFF0B0B0B) : const Color(0xFFF4F6F8);
    final inputTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: inputTextColor,
        title: const Text('Modifier le lieu'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _enregistrer,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            color: couleurPrincipale,
            tooltip: 'Enregistrer',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          children: [
            _section(
              title: 'Informations principales',
              icon: Icons.place,
              accent: couleurPrincipale,
              isDark: isDark,
              children: [
                TextField(
                  controller: _nomController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: inputTextColor),
                  decoration: _decoration(
                    label: 'Nom *',
                    icon: Icons.place,
                    hint: 'Ex: Musée des Beaux-Arts',
                    couleurPrincipale: couleurPrincipale,
                  ),
                ),
                const SizedBox(height: 12),

                
                DropdownButtonFormField<String>(
                  initialValue: _categorieSelectionnee,
                  dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                  style: TextStyle(color: inputTextColor),
                  decoration: _decoration(
                    label: 'Catégorie',
                    icon: Icons.category,
                    couleurPrincipale: couleurPrincipale,
                  ),
                  items: Commun.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            Commun.getIconeCategorie(cat),
                            size: 18,
                            color: couleurPrincipale,
                          ),
                          const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _categorieSelectionnee = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: TextStyle(color: inputTextColor),
                  decoration: _decoration(
                    label: 'Description',
                    icon: Icons.description,
                    hint: 'Quelques mots sur ce lieu (optionnel)',
                    couleurPrincipale: couleurPrincipale,
                  ),
                ),
              ],
    
            ),
            _section(
              title: 'Informations pratiques',
              icon: Icons.info_outline,
              accent: couleurPrincipale,
              isDark: isDark,
              children: [
                TextField(
                  controller: _adresseController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: inputTextColor),
                  decoration: _decoration(
                    label: 'Adresse',
                    icon: Icons.location_on,
                    hint: 'Rue, code postal, ville',
                    couleurPrincipale: couleurPrincipale,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: inputTextColor),
                  decoration: _decoration(
                    label: 'Téléphone',
                    icon: Icons.phone,
                    hint: '+33 ...',
                    couleurPrincipale: couleurPrincipale,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: inputTextColor),
                  decoration: _decoration(
                    label: 'Email',
                    icon: Icons.email,
                    hint: 'contact@exemple.com',
                    couleurPrincipale: couleurPrincipale,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _siteWebController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: inputTextColor),
                  decoration: _decoration(
                    label: 'Site web',
                    icon: Icons.language,
                    hint: 'https://...',
                    couleurPrincipale: couleurPrincipale,
                  ),
                ),
              ],
            ),
            _section(
              title: 'Accessibilité',
              icon: Icons.accessible,
              accent: couleurPrincipale,
              isDark: isDark,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withAlpha(
                        18,
                      ),
                    ),
                  ),
                  child: SwitchListTile(
                    value: _accessibilite,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _accessibilite = v),
                    activeThumbColor: couleurPrincipale,
                    title: Text(
                      'Accessible aux personnes à mobilité réduite',
                      style: TextStyle(
                        color: couleurPrincipale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _accessibilite ? 'Oui' : 'Non',
                      style: TextStyle(color: Colors.grey.withAlpha(200)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _saving ? null : _enregistrer,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Enregistrer les modifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: couleurPrincipale,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: couleurPrincipale.withAlpha(140)),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: couleurPrincipale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
