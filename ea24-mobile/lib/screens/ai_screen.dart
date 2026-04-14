import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../notifier/theme_provider.dart';
import '../notifier/trading_provider.dart';
import '../utils/app_style.dart';
import '../utils/color_utils.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

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
            title: Text(
              'AI Autopilot',
              style: Styles.textStyle.copyWith(
                fontSize: 24.0,
                color: ColorUtils.getPrimaryText(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Consumer<TradingProvider>(
            builder: (context, trading, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(8),
                    // Auto-Analyze Toggle
                    _AutoAnalyzeCard(trading: trading),
                    const Gap(20),
                    // Pipeline Results
                    Text(
                      'Analysis History',
                      style: Styles.textStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.getPrimaryText(context),
                      ),
                    ),
                    const Gap(12),
                    if (trading.pipelineResults.isEmpty)
                      _buildEmptyState(context, 'No analysis results yet',
                          Icons.analytics_outlined),
                    ...trading.pipelineResults
                        .map((r) => _AnalysisCard(result: r)),
                    const Gap(24),
                    // Agent Logs
                    Text(
                      'Agent Logs',
                      style: Styles.textStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.getPrimaryText(context),
                      ),
                    ),
                    const Gap(12),
                    if (trading.agentLogs.isEmpty)
                      _buildEmptyState(
                          context, 'No agent activity', Icons.smart_toy_outlined),
                    ...trading.agentLogs.take(20).map((l) => _LogCard(log: l)),
                    const Gap(80),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon,
              size: 40,
              color: ColorUtils.getSecondText(context).withOpacity(0.3)),
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

// ─────────────────────────────────────────────────────
//  Auto-Analyze Toggle Card
// ─────────────────────────────────────────────────────
class _AutoAnalyzeCard extends StatelessWidget {
  final TradingProvider trading;
  const _AutoAnalyzeCard({required this.trading});

  @override
  Widget build(BuildContext context) {
    final enabled = trading.autoAnalyzeEnabled;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: enabled ? Styles.primaryColor : ColorUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? Styles.primaryColor.withOpacity(0.3)
              : ColorUtils.getLineColor(context).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.white.withOpacity(0.2)
                  : ColorUtils.getSecondText(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: enabled
                  ? Colors.white
                  : ColorUtils.getSecondText(context),
              size: 28,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Auto-Analyze',
                  style: Styles.textStyle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? Colors.white
                        : ColorUtils.getPrimaryText(context),
                  ),
                ),
                const Gap(4),
                Text(
                  enabled
                      ? 'Actively scanning markets'
                      : 'Tap to enable AI analysis',
                  style: Styles.textStyle.copyWith(
                    fontSize: 13,
                    color: enabled
                        ? Colors.white.withOpacity(0.8)
                        : ColorUtils.getSecondText(context),
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          Switch.adaptive(
            value: enabled,
            onChanged: (v) => trading.toggleAutoAnalyze(v),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Analysis Result Card
// ─────────────────────────────────────────────────────
class _AnalysisCard extends StatefulWidget {
  final PipelineResult result;
  const _AnalysisCard({required this.result});

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isBuy = r.decision == 'BUY';
    final isHold = r.decision == 'HOLD';
    final color = isHold
        ? ColorUtils.getSecondText(context)
        : isBuy
            ? Styles.profitGreen
            : Styles.lossRed;
    final timeAgo = _formatTimeAgo(r.time);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorUtils.getCardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Direction badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      r.decision,
                      style: Styles.textStyle.copyWith(
                        fontSize: 10,
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
                        r.symbol,
                        style: Styles.textStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ColorUtils.getPrimaryText(context),
                        ),
                      ),
                      Text(
                        '${r.strategyName} · ${r.timeframe}',
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
                    // Confidence bar
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.confidence / 100,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${r.confidence.toStringAsFixed(0)}% · $timeAgo',
                      style: Styles.textStyle.copyWith(
                        fontSize: 11,
                        color: ColorUtils.getSecondText(context),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: ColorUtils.getSecondText(context),
                  size: 18,
                ),
              ],
            ),
            // Expandable reasoning
            if (_expanded) ...[
              const Gap(12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorUtils.getBackGround(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.reasoning.isNotEmpty ? r.reasoning : 'No details available',
                  style: Styles.textStyle.copyWith(
                    fontSize: 13,
                    color: ColorUtils.getSecondText(context),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ─────────────────────────────────────────────────────
//  Agent Log Card
// ─────────────────────────────────────────────────────
class _LogCard extends StatelessWidget {
  final AgentLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case 'blocked':
        statusColor = Styles.lossRed;
        statusIcon = Icons.block;
        break;
      case 'warning':
        statusColor = Styles.warningOrange;
        statusIcon = Icons.warning_amber;
        break;
      case 'done':
        statusColor = Styles.profitGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Styles.primaryColor;
        statusIcon = Icons.info_outline;
    }

    final timeAgo = _formatTimeAgo(log.time);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.agent,
                      style: Styles.textStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (log.symbol.isNotEmpty) ...[
                      const Gap(6),
                      Text(
                        log.symbol,
                        style: Styles.textStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ColorUtils.getPrimaryText(context),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      timeAgo,
                      style: Styles.textStyle.copyWith(
                        fontSize: 11,
                        color: ColorUtils.getSecondText(context),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  _stripEmojis(log.message),
                  style: Styles.textStyle.copyWith(
                    fontSize: 12,
                    color: ColorUtils.getSecondText(context),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stripEmojis(String text) {
    return text.replaceAll(
        RegExp(
            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2702}-\u{27B0}\u{24C2}-\u{1F251}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true),
        '');
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
