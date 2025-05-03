import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class WeatherAlert {
  final String? id;
  final String message;
  final LatLng location;
  final DateTime timestamp;
  final String type;
  final String username;

  WeatherAlert({
    this.id,
    required this.message,
    required this.location,
    required this.timestamp,
    required this.type,
    required this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'location': GeoPoint(location.latitude, location.longitude),
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'username': username,
    };
  }

  factory WeatherAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final GeoPoint geoPoint = data['location'];
    
    return WeatherAlert(
      id: doc.id,
      message: data['message'],
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'],
      username: data['username'],
    );
  }
} 