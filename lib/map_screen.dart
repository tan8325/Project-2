import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class WeatherAlert {
  final String message;
  final LatLng location;
  final DateTime timestamp;
  final String type;
  final String username;

  WeatherAlert({
    required this.message,
    required this.location,
    required this.timestamp,
    required this.type,
    required this.username,
  });
}

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
  List<WeatherAlert> alerts = [];
  final TextEditingController _messageController = TextEditingController();
  String _selectedWeatherType = 'rain';
  bool _showReportPanel = false;
  WeatherAlert? _selectedAlert;
  bool _showLocationCursor = false;

  final List<Map<String, dynamic>> weatherTypes = [
    {'type': 'rain', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'type': 'snow', 'icon': Icons.ac_unit, 'color': Colors.lightBlue},
    {'type': 'sunny', 'icon': Icons.wb_sunny, 'color': Colors.orange},
    {'type': 'fog', 'icon': Icons.cloud, 'color': Colors.grey},
    {'type': 'storm', 'icon': Icons.thunderstorm, 'color': Colors.purple},
    {'type': 'hail', 'icon': Icons.grain, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    loadRadarData();
    alerts = [
      WeatherAlert(
        message: "Heavy rain in downtown",
        location: LatLng(33.7490, -84.3880),
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: 'rain',
        username: 'WeatherWatcher',
      ),
      WeatherAlert(
        message: "Foggy conditions, low visibility",
        location: LatLng(33.8490, -84.2880),
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        type: 'fog',
        username: 'CommuteCaptain',
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> loadRadarData() async {
    try {
      setState(() => isLoading = true);
      
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
            
            final int hour = radarTime.hour;
            final String period = hour >= 12 ? 'PM' : 'AM';
            final int hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            lastUpdated = '${radarTime.month}/${radarTime.day}/${radarTime.year} $hour12:${radarTime.minute.toString().padLeft(2, '0')} $period';
          }
        }
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _addWeatherAlert() {
    if (_messageController.text.trim().isEmpty) return;

    final newAlert = WeatherAlert(
      message: _messageController.text.trim(),
      location: _mapController.camera.center,
      timestamp: DateTime.now(),
      type: _selectedWeatherType,
      username: 'CurrentUser',
    );

    setState(() {
      alerts.add(newAlert);
      _showReportPanel = false;
      _showLocationCursor = false;
      _messageController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weather report submitted. Thank you!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  String _formatDateTime(DateTime timestamp) {
    final int hour = timestamp.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${timestamp.month}/${timestamp.day}/${timestamp.year} $hour12:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }

  IconData _getIconForWeatherType(String type) {
    final weatherType = weatherTypes.firstWhere(
      (element) => element['type'] == type,
      orElse: () => {'type': 'rain', 'icon': Icons.water_drop, 'color': Colors.blue},
    );
    return weatherType['icon'] as IconData;
  }

  Color _getColorForWeatherType(String type) {
    final weatherType = weatherTypes.firstWhere(
      (element) => element['type'] == type,
      orElse: () => {'type': 'rain', 'icon': Icons.water_drop, 'color': Colors.blue},
    );
    return weatherType['color'] as Color;
  }

  void _showAlertDetails(WeatherAlert alert) => setState(() => _selectedAlert = alert);
  void _closeAlertDetails() => setState(() => _selectedAlert = null);

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
            onPressed: () => setState(() => isSatelliteView = !isSatelliteView),
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
              onTap: (_, __) {
                if (_selectedAlert != null) _closeAlertDetails();
              },
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
              MarkerLayer(
                markers: alerts.map((alert) => Marker(
                  width: 80,
                  height: 80,
                  point: alert.location,
                  child: GestureDetector(
                    onTap: () => _showAlertDetails(alert),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _getColorForWeatherType(alert.type).withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIconForWeatherType(alert.type), 
                            color: Colors.white, 
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            alert.type,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          if (_showLocationCursor)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 2, height: 20, color: Colors.white),
                  Container(width: 20, height: 2, color: Colors.white),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                  ),
                ],
              ),
            ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
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
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: "report_weather",
              backgroundColor: Colors.red,
              child: const Icon(Icons.add_alert),
              onPressed: () {
                setState(() {
                  _showReportPanel = !_showReportPanel;
                  _showLocationCursor = _showReportPanel;
                  if (_selectedAlert != null) _selectedAlert = null;
                });
              },
            ),
          ),
          if (_showReportPanel)
            Positioned(
              right: 16,
              bottom: 80,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Report Weather Condition',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_showLocationCursor)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black12,
                              shape: BoxShape.circle,
                            ),
                            child: const Tooltip(
                              message: 'Move map to position your report',
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Weather Type:'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: weatherTypes.map((weatherType) => 
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                weatherType['icon'] as IconData, 
                                size: 16, 
                                color: _selectedWeatherType == weatherType['type'] 
                                  ? Colors.white 
                                  : weatherType['color'] as Color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                weatherType['type'] as String,
                                style: TextStyle(
                                  color: _selectedWeatherType == weatherType['type'] 
                                    ? Colors.white 
                                    : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          selected: _selectedWeatherType == weatherType['type'],
                          selectedColor: weatherType['color'] as Color,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedWeatherType = weatherType['type'] as String;
                              });
                            }
                          },
                        ),
                      ).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your report...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 8,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showReportPanel = false;
                              _showLocationCursor = false;
                              _messageController.clear();
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _addWeatherAlert,
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedAlert != null)
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getIconForWeatherType(_selectedAlert!.type),
                              color: _getColorForWeatherType(_selectedAlert!.type),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedAlert!.type.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _closeAlertDetails,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAlert!.message,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reported by ${_selectedAlert!.username}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          _getTimeAgo(_selectedAlert!.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(_selectedAlert!.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
