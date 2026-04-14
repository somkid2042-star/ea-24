import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../notifier/theme_provider.dart';
import '../notifier/trading_provider.dart';
import '../utils/app_style.dart';
import '../utils/color_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final trading = context.read<TradingProvider>();
    _urlController = TextEditingController(text: trading.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: ColorUtils.getBackGround(context),
          appBar: AppBar(
            backgroundColor: ColorUtils.getBackGround(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: ColorUtils.getPrimaryText(context),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Settings',
              style: Styles.textStyle.copyWith(
                fontSize: 24.0,
                color: ColorUtils.getPrimaryText(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(16),
                // ── Connection Section ───────────────
                _SectionTitle(title: 'Connection'),
                const Gap(12),
                _SettingsCard(
                  children: [
                    // Server URL
                    _buildUrlField(context),
                    Divider(color: ColorUtils.getLineColor(context).withOpacity(0.3)),
                    // Connection status
                    Consumer<TradingProvider>(
                      builder: (context, trading, _) {
                        return _SettingsRow(
                          icon: Icons.cloud_outlined,
                          title: 'Status',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                trading.isConnected
                                    ? 'Connected'
                                    : 'Disconnected',
                                style: Styles.textStyle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: trading.isConnected
                                      ? Styles.profitGreen
                                      : Styles.lossRed,
                                ),
                              ),
                              const Gap(8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: trading.isConnected
                                      ? Styles.profitGreen
                                      : Styles.lossRed,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(color: ColorUtils.getLineColor(context).withOpacity(0.3)),
                    // Reconnect
                    Consumer<TradingProvider>(
                      builder: (context, trading, _) {
                        return _SettingsRow(
                          icon: Icons.refresh,
                          title: 'Reconnect',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            trading.disconnect();
                            trading.connect();
                          },
                        );
                      },
                    ),
                  ],
                ),
                const Gap(24),
                // ── Appearance Section ───────────────
                _SectionTitle(title: 'Appearance'),
                const Gap(12),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: themeProvider.currentTheme
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      title: 'Dark Mode',
                      trailing: Switch.adaptive(
                        value: themeProvider.currentTheme,
                        onChanged: (v) => themeProvider.changeTheme(v),
                        activeColor: Styles.primaryColor,
                        activeTrackColor: Styles.primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                // ── Notifications Section ───────────
                _SectionTitle(title: 'Notifications'),
                const Gap(12),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: Icons.notifications_outlined,
                      title: 'Trade Signals',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) {},
                        activeColor: Styles.primaryColor,
                        activeTrackColor: Styles.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    Divider(color: ColorUtils.getLineColor(context).withOpacity(0.3)),
                    _SettingsRow(
                      icon: Icons.newspaper_outlined,
                      title: 'News Alerts',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) {},
                        activeColor: Styles.primaryColor,
                        activeTrackColor: Styles.primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                // ── About Section ───────────────────
                _SectionTitle(title: 'About'),
                const Gap(12),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: Icons.info_outline,
                      title: 'Version',
                      trailing: Text(
                        '1.0.0',
                        style: Styles.textStyle.copyWith(
                          fontSize: 14,
                          color: ColorUtils.getSecondText(context),
                        ),
                      ),
                    ),
                    Divider(color: ColorUtils.getLineColor(context).withOpacity(0.3)),
                    Consumer<TradingProvider>(
                      builder: (context, trading, _) {
                        return _SettingsRow(
                          icon: Icons.memory,
                          title: 'EA Version',
                          trailing: Text(
                            trading.eaVersion,
                            style: Styles.textStyle.copyWith(
                              fontSize: 14,
                              color: ColorUtils.getSecondText(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Gap(40),
                // App name
                Center(
                  child: Text(
                    'EA24 MOBILE',
                    style: Styles.textStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: ColorUtils.getSecondText(context).withOpacity(0.3),
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const Gap(40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrlField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.link, color: ColorUtils.getSecondText(context), size: 22),
          const Gap(12),
          Expanded(
            child: TextField(
              controller: _urlController,
              style: Styles.textStyle.copyWith(
                fontSize: 14,
                color: ColorUtils.getPrimaryText(context),
              ),
              decoration: InputDecoration(
                hintText: 'ws://server-ip:8080',
                hintStyle: Styles.textStyle.copyWith(
                  color: ColorUtils.getSecondText(context).withOpacity(0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: () {
              final trading = context.read<TradingProvider>();
              trading.setServerUrl(_urlController.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server URL updated',
                      style: Styles.textStyle.copyWith(color: Colors.white)),
                  backgroundColor: Styles.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Styles.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Save',
                style: Styles.textStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Styles.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Section Title
// ─────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Styles.textStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorUtils.getSecondText(context),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Settings Card Container
// ─────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorUtils.getLineColor(context).withOpacity(0.4),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Settings Row
// ─────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: ColorUtils.getSecondText(context), size: 22),
            const Gap(12),
            Expanded(
              child: Text(
                title,
                style: Styles.textStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: ColorUtils.getPrimaryText(context),
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
