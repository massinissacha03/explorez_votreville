import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/commun.dart';
import '../../models/meteo.dart';


// details meteo avec animation fade in et fade out 
class MeteoDetailsDialog extends StatefulWidget {
  final String nomVille;
  final Meteo meteo;

  const MeteoDetailsDialog({
    super.key,
    required this.nomVille,
    required this.meteo,
  });

  @override
  State<MeteoDetailsDialog> createState() => _MeteoDetailsDialogState();

 
}

class _MeteoDetailsDialogState extends State<MeteoDetailsDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    // controler pour l'animation d'entrée / sortie du dialog
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // 
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Lance l'animation d'apparition
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Ferme le dialog avec une animation de disparition (fade-out)
  Future<void> _fermerAvecAnim() async {
    await _controller.reverse();
      Navigator.pop(context);
    
  }

 

  

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final couleurPrincipale = const Color.fromARGB(255, 0, 92, 20);
    final couleurFond = isDark ? Colors.grey.shade900 : Colors.white;
    final couleurTexte = isDark ? Colors.white : Colors.black87;
    final couleurSubtitle = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
    final couleurCard = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    final meteo = widget.meteo.extraireMeteo();
    final temp = meteo['temp']!;
    final tempMin = meteo['tempMin']!;
    final tempMax = meteo['tempMax']!;
    final description = meteo['description']!;
    final humidite = meteo['humidite']!;
    final vitesseVent = meteo['vent']!;

    return FadeTransition(
      opacity: _opacity,
      child: Dialog(
        backgroundColor: couleurFond,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Météo détaillée',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: couleurTexte,
                    ),
                  ),
                
                ],
              ),
              const SizedBox(height: 16),

              // Nom ville
              Text(
                widget.nomVille,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: couleurPrincipale,
                ),
              ),
              const SizedBox(height: 16),

              // Icône + température
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    Commun.getAnimationMeteo(description),
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$temp°',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: couleurTexte,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // description
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: couleurSubtitle),
              ),
              const SizedBox(height: 24),

              // temp min / max et humidite
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                
                child: Row(
                  children: [
                    Expanded(
                      child: _ItemDetail(
                        icone: Icons.thermostat,
                        label: 'Min/Max',
                        valeur: '$tempMin° / $tempMax°',
                        couleurFond: couleurCard,
                        couleurIcone: couleurPrincipale,
                        couleurTexte: couleurTexte,
                        couleurLabel: couleurSubtitle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ItemDetail(
                        icone: Icons.water_drop,
                        label: 'Humidité',
                        valeur: '$humidite%',
                        couleurFond: couleurCard,
                        couleurIcone: couleurPrincipale,
                        couleurTexte: couleurTexte,
                        couleurLabel: couleurSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ligne Vent
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: _ItemDetail(
                        icone: Icons.air,
                        label: 'Vent',
                        valeur: '$vitesseVent km/h',
                        couleurFond: couleurCard,
                        couleurIcone: couleurPrincipale,
                        couleurTexte: couleurTexte,
                        couleurLabel: couleurSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bouton fermer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _fermerAvecAnim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: couleurPrincipale,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Widget pour afficher un détail météo  
class _ItemDetail extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;
  final Color couleurFond;
  final Color couleurIcone;
  final Color couleurTexte;
  final Color couleurLabel;

  const _ItemDetail({
    required this.icone,
    required this.label,
    required this.valeur,
    required this.couleurFond,
    required this.couleurIcone,
    required this.couleurTexte,
    required this.couleurLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icone, color: couleurIcone, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: couleurLabel)),
          const SizedBox(height: 4),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: couleurTexte,
            ),
          ),
        ],
      ),
    );
  }
}
