import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/*ecran d'accueil avec animation texte + lottie
/la lottie nous l'avons modifié à notre facon dans l'editeur en ligne lottiefiles.com
*/
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isStarting = false;

  void _onStart() {
    if (_isStarting) return;

    setState(() => _isStarting = true);

    // on attends 2 secondes avant de naviguer vers le mainscreen
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // fond avec un dégradé selon vert <-> noir selon (sombre / clair)
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
        // transparent pour apparaitre le degrader
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Container(
            // 24 pixels padding autour
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: themeProvider.toggleTheme,
                  ),
                ),
                const Spacer(),

                // message bienvenue avec animatedTextkit
                AnimatedTextKit(
                  repeatForever: true,
                  animatedTexts: [
                    TyperAnimatedText(
                      'Bienvenue dans\nExplorez Votre Ville',
                      speed: const Duration(milliseconds: 80),
                      textAlign: TextAlign.center,
                      textStyle: const TextStyle(
                        fontFamily: 'ScienceGothic',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Découvrez les lieux qui vous entourent',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ScienceGothic',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),

                // animation lottie
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(70)
                        : Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    // ombre
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ville en fond
                      Lottie.asset(
                        'assets/ville_panorama.json',
                        repeat: !_isStarting,
                      ),
                      // Voiture qui ne bouge pas
                      if (!_isStarting)
                        Lottie.asset('assets/static_car.json', repeat: true),
                      // Voiture qui bouge et sort de la boxe
                      if (_isStarting)
                        Lottie.asset('assets/moving_car.json', repeat: false),
                    ],
                  ),
                ),

                const Spacer(),

                // Bouton Commencer
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: Icon(
                      _isStarting ? Icons.hourglass_empty : Icons.explore,
                    ),
                    label: Text(
                      _isStarting ? 'Démarrage...' : 'Commencer',
                      style: const TextStyle(
                        fontFamily: 'ScienceGothic',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isStarting ? null : _onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 92, 20),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
