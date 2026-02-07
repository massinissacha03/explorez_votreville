import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// widget pour selectionner la position d'un lieu sur une carte
class SelectionPositionCarte extends StatefulWidget {
  // position initiale de la carte
  final LatLng positionInitiale;

  const SelectionPositionCarte({super.key, required this.positionInitiale});

  @override
  State<SelectionPositionCarte> createState() => _SelectionPositionCarteState();
}

class _SelectionPositionCarteState extends State<SelectionPositionCarte> {
  late LatLng _position;

  @override
  void initState() {
    super.initState();
    _position = widget.positionInitiale;
  }

  @override
  Widget build(BuildContext context) {
    const couleurPrincipale = Color.fromARGB(255, 0, 92, 20);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la position'),
        backgroundColor: couleurPrincipale,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _position,
          initialZoom: 13.0,
          minZoom: 13.0,
          // à chaque tap on change la position
          onTap: (tapPosition, point) {
            setState(() {
              _position = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _position,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  size: 40,
                  color: couleurPrincipale,
                ),
              ),
            ],
          ),
        ],
      ),
      // utilisateur valide et retourne la position avec un pop
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: couleurPrincipale,
        icon: const Icon(Icons.check, color: Colors.white),
        label: Text(
          'Valider la position',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.pop(context, _position);
        },
      ),
    );
  }
}
