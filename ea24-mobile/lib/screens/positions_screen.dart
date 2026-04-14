import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../notifier/theme_provider.dart';
import '../notifier/trading_provider.dart';
import '../utils/app_style.dart';
import '../utils/color_utils.dart';

class PositionsScreen extends StatelessWidget {
  const PositionsScreen({super.key});

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
              'Positions',
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
              if (trading.positions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: ColorUtils.getSecondText(context)
                            .withOpacity(0.3),
                      ),
                      const Gap(16),
                      Text(
                        'No Open Positions',
                        style: Styles.textStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorUtils.getSecondText(context),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Your open trades will appear here',
                        style: Styles.textStyle.copyWith(
                          fontSize: 13,
                          color: ColorUtils.getSecondText(context)
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Summary header
              final totalProfit =
                  trading.positions.fold(0.0, (sum, p) => sum + p.profit);

              return Column(
                children: [
                  // Summary bar
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: ColorUtils.getCardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            ColorUtils.getLineColor(context).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${trading.positions.length} Open',
                          style: Styles.textStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ColorUtils.getPrimaryText(context),
                          ),
                        ),
                        Text(
                          '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
                          style: Styles.textStyle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: totalProfit >= 0
                                ? Styles.profitGreen
                                : Styles.lossRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Position list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: trading.positions.length,
                      itemBuilder: (context, index) {
                        return _PositionCard(
                          position: trading.positions[index],
                          onClose: () => _showCloseDialog(
                              context, trading, trading.positions[index]),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showCloseDialog(
      BuildContext context, TradingProvider trading, Position position) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ColorUtils.getCardColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Close Position',
            style: Styles.textStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorUtils.getPrimaryText(context),
            ),
          ),
          content: Text(
            'Close ${position.type} ${position.symbol} (#${position.ticket})?\n'
            'Current P&L: \$${position.profit.toStringAsFixed(2)}',
            style: Styles.textStyle.copyWith(
              color: ColorUtils.getSecondText(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: Styles.textStyle.copyWith(
                  color: ColorUtils.getSecondText(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                trading.closeTrade(position.ticket);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.lossRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Close',
                  style: Styles.textStyle),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  Position Card
// ─────────────────────────────────────────────────────
class _PositionCard extends StatelessWidget {
  final Position position;
  final VoidCallback onClose;

  const _PositionCard({required this.position, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isBuy = position.type == 'BUY';
    final dirColor = isBuy ? Styles.profitGreen : Styles.lossRed;
    final pnlColor =
        position.profit >= 0 ? Styles.profitGreen : Styles.lossRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorUtils.getLineColor(context).withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Direction badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dirColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  position.type,
                  style: Styles.textStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: dirColor,
                  ),
                ),
              ),
              const Gap(10),
              // Symbol
              Expanded(
                child: Text(
                  position.symbol,
                  style: Styles.textStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorUtils.getPrimaryText(context),
                  ),
                ),
              ),
              // P&L
              Text(
                '${position.profit >= 0 ? '+' : ''}\$${position.profit.toStringAsFixed(2)}',
                style: Styles.textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: pnlColor,
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              _InfoChip(
                  label: 'Lot', value: position.volume.toStringAsFixed(2)),
              const Gap(8),
              _InfoChip(
                  label: 'Open', value: position.openPrice.toStringAsFixed(5)),
              const Gap(8),
              _InfoChip(
                  label: 'Current',
                  value: position.currentPrice.toStringAsFixed(5)),
              const Spacer(),
              // Close button
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Styles.lossRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close, color: Styles.lossRed, size: 18),
                ),
              ),
            ],
          ),
          if (position.comment.isNotEmpty) ...[
            const Gap(6),
            Align(
               alignment: Alignment.centerLeft,
               child: Text(
                 '#${position.ticket} · ${position.comment}',
                 style: Styles.textStyle.copyWith(
                   fontSize: 11,
                   color: ColorUtils.getSecondText(context).withOpacity(0.7),
                 ),
               ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Styles.textStyle.copyWith(
            fontSize: 10,
            color: ColorUtils.getSecondText(context),
          ),
        ),
        Text(
          value,
          style: Styles.textStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorUtils.getPrimaryText(context),
          ),
        ),
      ],
    );
  }
}
