import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/weather_alert.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _weatherReportsCollection = 'weather_reports';

  Future<String> addWeatherReport(WeatherAlert alert) async {
    try {
      final docRef = await _firestore.collection(_weatherReportsCollection).add({
        'message': alert.message,
        'location': GeoPoint(alert.location.latitude, alert.location.longitude),
        'timestamp': alert.timestamp,
        'type': alert.type,
        'username': alert.username,
      });
      
      return docRef.id;
    } catch (e) {
      print('Error adding weather report: $e');
      throw Exception('Failed to add weather report');
    }
  }

  Stream<List<WeatherAlert>> getWeatherReports() {
    return _firestore
        .collection(_weatherReportsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final GeoPoint geoPoint = data['location'];
            
            return WeatherAlert(
              id: doc.id,
              message: data['message'],
              location: LatLng(geoPoint.latitude, geoPoint.longitude),
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              type: data['type'],
              username: data['username'],
            );
          }).toList();
        });
  }

  Stream<List<WeatherAlert>> getNearbyReports(LatLng center, double radiusInKm) {
    return getWeatherReports().map((reports) {
      return reports.where((report) {
        final distance = const Distance().as(
          LengthUnit.Kilometer,
          center,
          report.location,
        );
        return distance <= radiusInKm;
      }).toList();
    });
  }

  Future<void> deleteWeatherReport(String reportId) async {
    try {
      await _firestore.collection(_weatherReportsCollection).doc(reportId).delete();
    } catch (e) {
      print('Error deleting weather report: $e');
      throw Exception('Failed to delete weather report');
    }
  }

  Stream<List<WeatherAlert>> getReportsByType(String type) {
    return _firestore
        .collection(_weatherReportsCollection)
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final GeoPoint geoPoint = data['location'];
            
            return WeatherAlert(
              id: doc.id,
              message: data['message'],
              location: LatLng(geoPoint.latitude, geoPoint.longitude),
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              type: data['type'],
              username: data['username'],
            );
          }).toList();
        });
  }
} 