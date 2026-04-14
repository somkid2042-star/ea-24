import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../notifier/theme_provider.dart';
import '../notifier/trading_provider.dart';
import '../utils/app_layout.dart';
import '../utils/app_style.dart';
import '../utils/color_utils.dart';
import '../utils/slide_page_route.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLayout.screenPortrait();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: ColorUtils.getBackGround(context),
          appBar: AppBar(
            backgroundColor: ColorUtils.getBackGround(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0.0,
            title: Text(
              'Dashboard',
              style: Styles.textStyle.copyWith(
                fontSize: 24.0,
                color: ColorUtils.getPrimaryText(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    FadePageRoute(page: const SettingsScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Icon(
                    Icons.settings_outlined,
                    color: ColorUtils.getPrimaryText(context),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          body: Consumer<TradingProvider>(
            builder: (context, trading, child) {
              return RefreshIndicator(
                onRefresh: () async {
                  trading.disconnect();
                  trading.connect();
                },
                color: Styles.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(8),
                      // Connection status
                      _ConnectionBanner(trading: trading),
                      const Gap(16),
                      // Account overview card
                      _AccountCard(trading: trading),
                      const Gap(16),
                      // Profit/Drawdown row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total P&L',
                              value:
                                  '\$${trading.totalProfit.toStringAsFixed(2)}',
                              valueColor: trading.totalProfit >= 0
                                  ? Styles.profitGreen
                                  : Styles.lossRed,
                              icon: trading.totalProfit >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: _StatCard(
                              label: 'Drawdown',
                              value:
                                  '${trading.drawdownPercent.toStringAsFixed(1)}%',
                              valueColor: trading.drawdownPercent > 5
                                  ? Styles.lossRed
                                  : trading.drawdownPercent > 2
                                      ? Styles.warningOrange
                                      : Styles.profitGreen,
                              icon: Icons.shield_outlined,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      // Positions count + EA version row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Positions',
                              value: '${trading.openPositionCount}',
                              valueColor: Styles.primaryColor,
                              icon: Icons.candlestick_chart,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: _StatCard(
                              label: 'EA Version',
                              value: trading.eaVersion,
                              valueColor: ColorUtils.getPrimaryText(context),
                              icon: Icons.memory,
                            ),
                          ),
                        ],
                      ),
                      const Gap(24),
                      // Recent AI Activity
                      Text(
                        'Recent AI Activity',
                        style: Styles.textStyle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.getPrimaryText(context),
                        ),
                      ),
                      const Gap(12),
                      if (trading.pipelineResults.isEmpty &&
                          trading.agentLogs.isEmpty)
                        _EmptyState(
                          message: 'No activity yet',
                          icon: Icons.auto_awesome_outlined,
                        ),
                      ...trading.pipelineResults.take(5).map(
                            (r) => _PipelineCard(result: r),
                          ),
                      const Gap(80),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  Connection Status Banner
// ─────────────────────────────────────────────────────
class _ConnectionBanner extends StatelessWidget {
  final TradingProvider trading;
  const _ConnectionBanner({required this.trading});

  @override
  Widget build(BuildContext context) {
    final connected = trading.isConnected;
    final eaConnected = trading.eaConnected;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!connected) {
      statusColor = Styles.lossRed;
      statusText = 'Disconnected';
      statusIcon = Icons.cloud_off;
    } else if (!eaConnected) {
      statusColor = Styles.warningOrange;
      statusText = 'Server OK · EA Offline';
      statusIcon = Icons.cloud_outlined;
    } else {
      statusColor = Styles.profitGreen;
      statusText = 'Connected · EA Online';
      statusIcon = Icons.cloud_done;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const Gap(10),
          Text(
            statusText,
            style: Styles.textStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Account Card — Balance / Equity
// ─────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final TradingProvider trading;
  const _AccountCard({required this.trading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Styles.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Styles.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Overview',
                style: Styles.textStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE',
                  style: Styles.textStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          // Balance
          Text(
            'Balance',
            style: Styles.textStyle.copyWith(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const Gap(4),
          Text(
            '\$${trading.balance.toStringAsFixed(2)}',
            style: Styles.textStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const Gap(16),
          // Equity row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equity',
                      style: Styles.textStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      '\$${trading.equity.toStringAsFixed(2)}',
                      style: Styles.textStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Floating P&L',
                      style: Styles.textStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      '${trading.totalProfit >= 0 ? '+' : ''}\$${trading.totalProfit.toStringAsFixed(2)}',
                      style: Styles.textStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white, // In MightyFitness, keep contrast on orange cards
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Stat Card
// ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorUtils.getLineColor(context).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: valueColor, size: 18),
              const Gap(6),
              Text(
                label,
                style: Styles.textStyle.copyWith(
                  fontSize: 12,
                  color: ColorUtils.getSecondText(context),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            value,
            style: Styles.textStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Pipeline Result Card
// ─────────────────────────────────────────────────────
class _PipelineCard extends StatelessWidget {
  final PipelineResult result;
  const _PipelineCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isBuy = result.decision == 'BUY';
    final isHold = result.decision == 'HOLD';
    final color = isHold
        ? ColorUtils.getSecondText(context)
        : isBuy
            ? Styles.profitGreen
            : Styles.lossRed;
    final timeAgo = _formatTimeAgo(result.time);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorUtils.getLineColor(context).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Signal badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                result.decision,
                style: Styles.textStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.symbol,
                  style: Styles.textStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorUtils.getPrimaryText(context),
                  ),
                ),
                const Gap(2),
                Text(
                  '${result.strategyName} · ${result.timeframe}',
                  style: Styles.textStyle.copyWith(
                    fontSize: 12,
                    color: ColorUtils.getSecondText(context),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.confidence.toStringAsFixed(0)}%',
                style: Styles.textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                timeAgo,
                style: Styles.textStyle.copyWith(
                  fontSize: 11,
                  color: ColorUtils.getSecondText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────
//  Empty State
// ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: ColorUtils.getSecondText(context).withOpacity(0.3)),
          const Gap(12),
          Text(
            message,
            style: Styles.textStyle.copyWith(
              fontSize: 14,
              color: ColorUtils.getSecondText(context),
            ),
          ),
        ],
      ),
    );
  }
}
