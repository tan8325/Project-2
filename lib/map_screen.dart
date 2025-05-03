import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final double defaultLatitude = 33.7490;
  final double defaultLongitude = -84.3880;
  final double defaultZoom = 7;
  
  String radarUrl = '';
  bool isLoading = true;
  bool isSatelliteView = false;
  final int colorScheme = 2;
  String lastUpdated = '';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    loadRadarData();
  }

  Future<void> loadRadarData() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final response = await http.get(
        Uri.parse('https://api.rainviewer.com/public/weather-maps.json'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data.containsKey('host') && 
            data.containsKey('radar') && 
            data['radar'] is Map &&
            data['radar'].containsKey('past') &&
            data['radar']['past'] is List &&
            data['radar']['past'].isNotEmpty) {
          
          final latestFrame = data['radar']['past'].last;
          
          if (latestFrame != null && 
              latestFrame.containsKey('path') && 
              latestFrame['path'] != null &&
              latestFrame.containsKey('time')) {
            
            final String host = data['host'];
            final String path = latestFrame['path'];
            final int timestamp = latestFrame['time'];
            
            radarUrl = '$host$path/256/{z}/{x}/{y}/$colorScheme/1_1.png';
            
            final DateTime radarTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            
            // Convert to 12-hour format with AM/PM
            final int hour = radarTime.hour;
            final String period = hour >= 12 ? 'PM' : 'AM';
            final int hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            lastUpdated = '${radarTime.month}/${radarTime.day}/${radarTime.year} $hour12:${radarTime.minute.toString().padLeft(2, '0')} $period';
            
            setState(() {
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Radar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isSatelliteView ? Icons.map : Icons.satellite_alt),
            tooltip: isSatelliteView ? 'Switch to Map View' : 'Switch to Satellite View',
            onPressed: () {
              setState(() {
                isSatelliteView = !isSatelliteView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Radar',
            onPressed: loadRadarData,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(defaultLatitude, defaultLongitude),
              initialZoom: defaultZoom,
              interactionOptions: const InteractionOptions(
                enableScrollWheel: true,
                enableMultiFingerGestureRace: true,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isSatelliteView 
                  ? 'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                tileProvider: NetworkTileProvider(),
              ),
              if (!isLoading && radarUrl.isNotEmpty)
                Opacity(
                  opacity: 0.8,
                  child: TileLayer(
                    urlTemplate: radarUrl,
                    userAgentPackageName: 'com.example.app',
                    tileProvider: NetworkTileProvider(),
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom - 1);
                  },
                ),
              ],
            ),
          ),
          if (!isLoading && lastUpdated.isNotEmpty)
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Radar data: $lastUpdated',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
