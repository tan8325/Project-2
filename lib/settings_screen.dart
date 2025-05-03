import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _rainAlert = true;
  bool _snowAlert = false;
  bool _tempAlert = false;

  Future<void> _pickBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result?.files.single.path != null) {
      print("Picked background image: ${result!.files.single.path!}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF4F4F4);
    final cardColor = Colors.grey[300]!;
    final borderColor = Colors.grey[400]!; 
    final textColor = Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildAlertBanner(cardColor, textColor),
            const SizedBox(height: 28),
            _buildSectionTitle("ALERTS", textColor),
            const SizedBox(height: 10),
            _buildSwitch("Rain", _rainAlert, (val) => setState(() => _rainAlert = val), textColor),
            _buildSwitch("Snow", _snowAlert, (val) => setState(() => _snowAlert = val), textColor),
            _buildSwitch("Temperature", _tempAlert, (val) => setState(() => _tempAlert = val), textColor),
            const SizedBox(height: 8),
            Divider(thickness: 1, color: borderColor),
            const SizedBox(height: 12),
            _buildThemeSelector(borderColor, textColor),
            const SizedBox(height: 12),
            Divider(thickness: 1, color: borderColor),
            const SizedBox(height: 12),
            _buildSectionRow("NOTIFICATIONS", textColor),
            const SizedBox(height: 18),
            _buildUploadButton(borderColor, textColor),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Rain expected in 30 mins",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
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
    return Row(
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
              Text("Default", style: TextStyle(fontSize: 20, color: textColor)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionRow(String title, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        Icon(Icons.arrow_forward_ios_rounded, size: 20, color: textColor),
      ],
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
