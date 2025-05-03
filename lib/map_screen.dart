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
  // Default to Atlanta, GA coordinates
  final double defaultLatitude = 33.7490;
  final double defaultLongitude = -84.3880;
  final double defaultZoom = 7;
  
  // Direct static URL to RainViewer latest radar data
  String radarUrl = '';
  bool isLoading = true;
  String debugMessage = "";
  
  // Map type toggle
  bool isSatelliteView = false;
  
  // Color schemes available in RainViewer
  // 1: Original
  // 2: Universal Blue
  // 3: TITAN
  // 4: The Weather Channel
  // 5: NEXRAD Level-3
  // 6: Rainbow @ SELEX-SI
  // 7: Dark Sky
  final int colorScheme = 2; // Using Universal Blue for better visibility

  @override
  void initState() {
    super.initState();
    loadRadarData();
  }

  Future<void> loadRadarData() async {
    try {
      setState(() {
        isLoading = true;
        debugMessage = "Loading radar data...";
      });
      
      // Fetch the latest radar data information from RainViewer API
      final response = await http.get(
        Uri.parse('https://api.rainviewer.com/public/weather-maps.json'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Extract required data for constructing the URL
        if (data.containsKey('host') && 
            data.containsKey('radar') && 
            data['radar'] is Map &&
            data['radar'].containsKey('past') &&
            data['radar']['past'] is List &&
            data['radar']['past'].isNotEmpty) {
          
          // Get the latest radar frame from the past data
          final latestFrame = data['radar']['past'].last;
          
          if (latestFrame != null && 
              latestFrame.containsKey('path') && 
              latestFrame['path'] != null) {
            
            final String host = data['host'];
            final String path = latestFrame['path'];
            
            // Format the complete URL - Using the standard tile format instead of lat/lon
            // Format: {host}{path}/256/{z}/{x}/{y}/{colorScheme}/1_1.png
            // where 1_1 means: smoothed (1) with snow display (1)
            radarUrl = '$host$path/256/{z}/{x}/{y}/$colorScheme/1_1.png';
            
            setState(() {
              isLoading = false;
              debugMessage = "Radar loaded successfully";
            });
          } else {
            setState(() {
              isLoading = false;
              debugMessage = "Invalid frame data in API response";
            });
          }
        } else {
          setState(() {
            isLoading = false;
            debugMessage = "Invalid API response format or no radar data available";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          debugMessage = "API Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        debugMessage = "Error: $e";
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
          // Map type toggle button
          IconButton(
            icon: Icon(isSatelliteView ? Icons.map : Icons.satellite_alt),
            tooltip: isSatelliteView ? 'Switch to Map View' : 'Switch to Satellite View',
            onPressed: () {
              setState(() {
                isSatelliteView = !isSatelliteView;
              });
            },
          ),
          // Refresh button
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
            options: MapOptions(
              initialCenter: LatLng(defaultLatitude, defaultLongitude),
              initialZoom: defaultZoom,
              interactionOptions: const InteractionOptions(
                enableScrollWheel: true,
                enableMultiFingerGestureRace: true,
              ),
            ),
            children: [
              // Base map layer (OpenStreetMap or Satellite)
              TileLayer(
                urlTemplate: isSatelliteView 
                  // Use Esri World Imagery for satellite view
                  ? 'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                tileProvider: NetworkTileProvider(),
              ),
              // RainViewer radar layer
              if (!isLoading && radarUrl.isNotEmpty)
                Opacity(
                  opacity: 0.8, // Slightly higher opacity for better visibility
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
          // Error display if needed
          if (!isLoading && radarUrl.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No radar data available",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    debugMessage,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loadRadarData,
                    child: const Text("Try Again"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
