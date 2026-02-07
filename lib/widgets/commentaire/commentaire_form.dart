import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commentaire.dart';
import '../../models/lieu.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ville_provider.dart';
import '../../providers/commentaires_provider.dart';
import '../../utils/ville_loader.dart';

// formulaire permettant de commenter et d'ajouter une note à un lieu
class CommentaireForm extends StatefulWidget {
  final Lieu lieu;

  const CommentaireForm({
    super.key,
    required this.lieu,
  });

  @override
  State<CommentaireForm> createState() => _CommentaireFormState();
}

class _CommentaireFormState extends State<CommentaireForm> {
  final TextEditingController _commentaireController = TextEditingController();
  double _noteSelectionnee = 3.0; // par défaut
  late Lieu _lieuCourant;

  @override
  void initState() {
    super.initState();
    _lieuCourant = widget.lieu;
  }

  @override
  void didUpdateWidget(covariant CommentaireForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // si le parent passe un nouveau lieu (ex: après insertion), on met à jour
    if (oldWidget.lieu.id != widget.lieu.id) {
      _lieuCourant = widget.lieu;
    }
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _ajouterCommentaire() async {
    final texte = _commentaireController.text.trim();
    if (texte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le commentaire ne peut pas être vide')),
      );
      return;
    }

    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    final commentaireProvider =
        Provider.of<CommentaireProvider>(context, listen: false);

    // Ville obligatoire
    var ville = villeProvider.villeActuelle;
    if (ville == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune ville sélectionnée.')),
      );
      return;
    }

    // Ville doit être en base
    if (ville.id == null) {
      ville = await villeProvider.marquerCommeVisitee(ville);
      await applyVilleSelection(context, ville);
    }

    if (ville.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'enregistrer la ville.")),
      );
      return;
    }

    // Lieu doit être en base
    var lieuCourant = _lieuCourant;

    if (lieuCourant.id == null) {
      final sauvegarde = await lieuProvider.ajouterLieu(
        lieuCourant.copie(
          villeId: ville.id!, // assurer la liaison
          estFavori: false,
        ),
      );

      if (sauvegarde == null || sauvegarde.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'enregistrer le lieu.")),
        );
        return;
      }

      setState(() {
        _lieuCourant = sauvegarde;
      });
      lieuCourant = sauvegarde;
    }

    // Ajouter le commentaire
    final commentaire = Commentaire(
      lieuId: lieuCourant.id!,
      texte: texte,
      note: _noteSelectionnee,
      dateCreation: DateTime.now(),
    );

    await commentaireProvider.ajouterCommentaire(commentaire);
    await lieuProvider.rafraichirNoteMoyenne(lieuCourant.id!);
    await commentaireProvider.rechargerCommentairesDuLieu(lieuCourant.id!);

    _commentaireController.clear();
    setState(() => _noteSelectionnee = 3.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commentaire ajouté'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
    final couleurTexte = isDark ? Colors.white : Colors.black87;
    final couleurSubtitle = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Note :',
              style: TextStyle(
                color: couleurTexte,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Slider(
                value: _noteSelectionnee,
                min: 0,
                max: 5,
                divisions: 10,
                label: _noteSelectionnee.toStringAsFixed(1),
                activeColor: couleurPrincipale,
                onChanged: (value) => setState(() => _noteSelectionnee = value),
              ),
            ),
            Text(
              _noteSelectionnee.toStringAsFixed(1),
              style: TextStyle(color: couleurTexte),
            ),
          ],
        ),
        TextField(
          controller: _commentaireController,
          style: TextStyle(color: couleurTexte),
          decoration: InputDecoration(
            hintText: 'Votre commentaire...',
            hintStyle: TextStyle(color: couleurSubtitle),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _ajouterCommentaire,
            icon: const Icon(Icons.send),
            label: const Text('Envoyer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: couleurPrincipale,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
