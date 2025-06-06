import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _rainAlert = true;
  bool _snowAlert = true;
  bool _tempAlert = true;
  bool _thunderstormAlert = true;
  bool _darkTheme = false;
  bool _notificationsEnabled = true;
  String? _activeAlertMessage;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchWeatherAlert();
    _startAlertTimer(); 
  }

  void _startAlertTimer() {
    _alertTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      _fetchWeatherAlert();
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkTheme = prefs.getBool('isDarkTheme') ?? false;
      _rainAlert = prefs.getBool('rainAlert') ?? true;
      _snowAlert = prefs.getBool('snowAlert') ?? true;
      _tempAlert = prefs.getBool('tempAlert') ?? true;
      _thunderstormAlert = prefs.getBool('thunderstormAlert') ?? true;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
    themeNotifier.value = _darkTheme ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = value);
    await prefs.setBool('isDarkTheme', value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _updateAlertPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _updateNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  Future<void> _fetchWeatherAlert() async {
    final apiKey = '4631382a3fedac89d601b33a9658b30e';
    final lat = 33.7490;  // Latitude for Atlanta
    final lon = -84.3880; // Longitude for Atlanta

    final url = Uri.parse('https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,daily&appid=$apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        String? alert;

        final weatherMain = current['weather']?[0]['main'];
        if (_rainAlert && weatherMain == 'Rain') {
          alert = "Rain Alert: It's currently raining!";
        } else if (_snowAlert && weatherMain == 'Snow') {
          alert = "Snow Alert: It's currently snowing!";
        } else if (_thunderstormAlert && weatherMain == 'Thunderstorm') {
          alert = "Thunderstorm Alert: It's currently thundering!";
        } else if (_tempAlert) {
          final tempKelvin = current['temp'];
          final tempF = (tempKelvin - 273.15) * 9 / 5 + 32;

          if (tempF <= 41) {
            alert = "Cold Temperature Alert: ${tempF.toStringAsFixed(1)}°F";
          } else if (tempF >= 86) {
            alert = "Heat Alert: ${tempF.toStringAsFixed(1)}°F";
          }
        }

        setState(() {
          _activeAlertMessage = alert ?? "No weather alerts at this time";
        });
      }
    } catch (e) {
      print("Failed to fetch alert: $e");
    }
  }

  Future<void> _pickBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result?.files.single.path != null) {
      print("Picked background image: ${result!.files.single.path!}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4);
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildAlertBanner(cardColor, textColor),
            _buildSwitches(textColor),
            _buildThemeSelector(borderColor, textColor),
            _buildNotificationToggle(textColor),
            _buildUploadButton(borderColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _activeAlertMessage ?? "No weather alerts at this time",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade700),
            onPressed: _fetchWeatherAlert,
            tooltip: "Refresh Alerts",
          ),
        ],
      ),
    );
  }

  Widget _buildSwitches(Color textColor) {
    return Column(
      children: [
        _buildSwitch("Rain", _rainAlert, (val) {
          setState(() => _rainAlert = val);
          _updateAlertPref('rainAlert', val);
        }, textColor),
        _buildSwitch("Snow", _snowAlert, (val) {
          setState(() => _snowAlert = val);
          _updateAlertPref('snowAlert', val);
        }, textColor),
        _buildSwitch("Temperature", _tempAlert, (val) {
          setState(() => _tempAlert = val);
          _updateAlertPref('tempAlert', val);
        }, textColor),
        _buildSwitch("Thunderstorm", _thunderstormAlert, (val) {
          setState(() => _thunderstormAlert = val);
          _updateAlertPref('thunderstormAlert', val);
        }, textColor),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged, Color textColor) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
      value: value,
      activeColor: Colors.grey.shade800,
      onChanged: onChanged,
    );
  }

  Widget _buildThemeSelector(Color borderColor, Color textColor) {
    return GestureDetector(
      onTap: () => _toggleTheme(!_darkTheme),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("THEME", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(_darkTheme ? "Dark" : "Light", style: TextStyle(fontSize: 20, color: textColor)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(Color textColor) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text("NOTIFICATIONS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
      value: _notificationsEnabled,
      activeColor: Colors.grey.shade800,
      onChanged: (val) {
        setState(() => _notificationsEnabled = val);
        _updateNotificationPref(val);
      },
    );
  }

  Widget _buildUploadButton(Color borderColor, Color textColor) {
    return GestureDetector(
      onTap: _pickBackground,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload, size: 36, color: textColor),
            const SizedBox(height: 10),
            Text("Upload background", style: TextStyle(fontSize: 20, color: textColor)),
          ],
        ),
      ),
    );
  }
}
