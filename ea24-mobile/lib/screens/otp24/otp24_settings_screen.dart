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
  final _serverIpController = TextEditingController();
  bool _isLoading = false;
  bool _isSavingIp = false;

  @override
  void initState() {
    super.initState();
    _loadServerIp();
  }

  Future<void> _loadServerIp() async {
    final ip = await OTP24Service.getSavedServerIp();
    if (mounted) {
      _serverIpController.text = ip;
    }
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _licenseKeyController.dispose();
    _serverIpController.dispose();
    super.dispose();
  }

  Future<void> _saveServerIp() async {
    final ip = _serverIpController.text.trim();
    setState(() { _isSavingIp = true; });

    await OTP24Service.setServerBase(ip);

    if (mounted) {
      setState(() { _isSavingIp = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ip.isEmpty
              ? 'รีเซ็ตกลับเป็น localhost:4173'
              : 'บันทึก Server IP: $ip สำเร็จ'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    }
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
          'ตั้งค่า',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section 1: Server IP ───────────────────
            _buildSectionHeader(
              icon: Icons.dns_rounded,
              title: 'Server IP',
              subtitle: 'กรอก IP ของเซิร์ฟเวอร์ EA-24 (เช่น 192.168.1.100:4173)',
              color: const Color(0xFF00BCD4),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _serverIpController,
              label: 'Server IP',
              hint: 'เช่น 192.168.1.100:4173 หรือ http://35.201.156.240:4173',
              icon: Icons.language,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSavingIp ? null : _saveServerIp,
                icon: _isSavingIp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _isSavingIp ? 'กำลังบันทึก...' : 'บันทึก Server IP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ─── Section 2: Admin Settings ──────────────
            _buildSectionHeader(
              icon: Icons.admin_panel_settings,
              title: 'ตั้งค่าขั้นสูง (Admin)',
              subtitle: 'ฟังก์ชันนี้จะเขียนทับฐานข้อมูลเซิร์ฟเวอร์โดยตรง',
              color: const Color(0xFFFF5E13),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSettings,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload_rounded, size: 20),
                label: Text(
                  _isLoading ? 'กำลังบันทึก...' : 'บันทึกลงฐานข้อมูล',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
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
