import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commentaire.dart';
import '../../providers/commentaires_provider.dart';
import '../../providers/theme_provider.dart';

class CommentaireListe extends StatelessWidget {
  final int? lieuId;

  const CommentaireListe({
    super.key,
    required this.lieuId,
  });

  @override
  Widget build(BuildContext context) {
    if (lieuId == null) return const SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final commentaireProvider = Provider.of<CommentaireProvider>(context); // listen = true

    final isDark = themeProvider.isDarkMode;

    // IMPORTANT: on lit depuis le provider ici => refresh automatique après notifyListeners()
    final List<Commentaire> commentaires =
        commentaireProvider.getCommentairesByLieu(lieuId!);

    if (commentaires.isEmpty) return const SizedBox.shrink();

    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);
    final couleurTexte = isDark ? Colors.white : Colors.black87;
    final couleurSubtitle = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.comment, color: couleurPrincipale, size: 20),
            const SizedBox(width: 8),
            Text(
              'Commentaires (${commentaires.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: couleurTexte,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...commentaires.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withAlpha(13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            c.note.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${c.dateCreation.day}/${c.dateCreation.month}/${c.dateCreation.year}',
                      style: TextStyle(
                        color: couleurSubtitle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.texte,
                  style: TextStyle(
                    color: couleurTexte,
                    fontSize: 14,
                    height: 1.4,
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
