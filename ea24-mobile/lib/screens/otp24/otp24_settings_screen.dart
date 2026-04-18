import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp24_service.dart';

/// OTP24 Settings Screen — Elite Quiz-inspired clean design
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

  static const _primaryColor = Color(0xFFEF5388);
  static const _textColor = Color(0xFF45536D);
  static const _cardColor = Colors.white;
  static const _successColor = Color(0xFF5DB760);

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
          content: Text(
            ip.isEmpty
                ? 'Reset to localhost:4173'
                : 'Server IP saved: $ip',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        SnackBar(
          content: Text('Please fill at least one field',
              style: GoogleFonts.nunito()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final result = await OTP24Service.updateAdminSettings(deviceId, licenseKey);

    if (mounted) {
      setState(() { _isLoading = false; });

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Saved successfully',
                style: GoogleFonts.nunito()),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error occurred',
                style: GoogleFonts.nunito()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(),
        title: Text(
          'Settings',
          style: GoogleFonts.nunito(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section 1: Server IP ───────────────
            _buildSectionCard(
              icon: Icons.dns_outlined,
              iconColor: _primaryColor,
              title: 'Server Connection',
              subtitle: 'Configure EA-24 Server IP address',
              children: [
                _buildInput(
                  controller: _serverIpController,
                  label: 'Server IP',
                  hint: 'e.g. 192.168.1.100:4173',
                  icon: Icons.language_outlined,
                ),
                const SizedBox(height: 16),
                _buildButton(
                  text: 'Save Server IP',
                  icon: Icons.save_outlined,
                  isLoading: _isSavingIp,
                  color: _primaryColor,
                  onTap: _isSavingIp ? null : _saveServerIp,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ─── Section 2: Admin ───────────────────
            _buildSectionCard(
              icon: Icons.admin_panel_settings_outlined,
              iconColor: Colors.orange[700]!,
              title: 'Admin Settings',
              subtitle: 'Force update server database directly',
              children: [
                _buildInput(
                  controller: _deviceIdController,
                  label: 'Device ID',
                  hint: 'Enter target device ID',
                  icon: Icons.devices_outlined,
                ),
                const SizedBox(height: 14),
                _buildInput(
                  controller: _licenseKeyController,
                  label: 'License Key',
                  hint: 'Enter target license key',
                  icon: Icons.key_outlined,
                ),
                const SizedBox(height: 16),
                _buildButton(
                  text: 'Save to Database',
                  icon: Icons.upload_outlined,
                  isLoading: _isLoading,
                  color: Colors.orange[700]!,
                  onTap: _isLoading ? null : _saveSettings,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Back Button (ui2 style) ────────────────────────
  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: _textColor),
          ),
        ),
      ),
    );
  }

  // ── Section Card ───────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: _textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        color: _textColor.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ── Input Field ────────────────────────────────────
  Widget _buildInput({
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
          style: GoogleFonts.nunito(
            color: _textColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.nunito(color: _textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
                color: _textColor.withOpacity(0.3), fontSize: 13),
            prefixIcon: Icon(icon, color: _textColor.withOpacity(0.3), size: 20),
            filled: true,
            fillColor: const Color(0xFFF3F7FA),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Button ─────────────────────────────────────────
  Widget _buildButton({
    required String text,
    required IconData icon,
    required bool isLoading,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(text,
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
      ),
    );
  }
}
