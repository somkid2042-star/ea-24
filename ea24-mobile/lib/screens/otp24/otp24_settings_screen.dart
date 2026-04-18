import 'package:flutter/material.dart';
import 'otp24_service.dart';

class OTP24SettingsScreen extends StatefulWidget {
  const OTP24SettingsScreen({super.key});

  @override
  State<OTP24SettingsScreen> createState() => _OTP24SettingsScreenState();
}

class _OTP24SettingsScreenState extends State<OTP24SettingsScreen> {
  final _deviceIdController = TextEditingController();
  final _licenseKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final deviceId = _deviceIdController.text.trim();
    final licenseKey = _licenseKeyController.text.trim();

    if (deviceId.isEmpty && licenseKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลอย่างน้อย 1 ช่อง')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await OTP24Service.updateAdminSettings(deviceId, licenseKey);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'บันทึกสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success/refresh needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'เกิดข้อผิดพลาด'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ตั้งค่าขั้นสูง (Admin)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ฟังก์ชันนี้จะเขียนทับฐานข้อมูลเซิร์ฟเวอร์โดนตรง ข้ามกฎการล็อค 1 ครั้ง หากกรอกค่าเดิมที่มีระบบจะทำการอัพเดทใหม่ให้',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _deviceIdController,
              label: 'Device ID',
              hint: 'กรอก Device ID ปลายทาง (เว้นว่างหากไม่ต้องการแก้)',
              icon: Icons.devices,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _licenseKeyController,
              label: 'License Key',
              hint: 'กรอก License Key ปลายทาง (เว้นว่างหากไม่ต้องการแก้)',
              icon: Icons.key,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'บันทึกลงฐานข้อมูล',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF5E13)),
            ),
          ),
        ),
      ],
    );
  }
}
