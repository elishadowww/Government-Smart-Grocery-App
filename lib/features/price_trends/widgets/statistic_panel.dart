import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';

class StatisticPanel extends ConsumerWidget {
  final double lowest;
  final double avg;
  final double high;

  const StatisticPanel({
    super.key,
    required this.lowest,
    required this.avg,
    required this.high,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.arrow_downward_rounded,
              label: ref.tr('lowest'),
              value: 'RM${lowest.toStringAsFixed(2)}',
            ),
          ),
          Container(height: 28, width: 1, color: const Color(0xFFE0E0E0)),
          Expanded(
            child: _StatItem(
              icon: Icons.show_chart_rounded,
              label: ref.tr('average'),
              value: 'RM${avg.toStringAsFixed(2)}',
            ),
          ),
          Container(height: 28, width: 1, color: const Color(0xFFE0E0E0)),
          Expanded(
            child: _StatItem(
              icon: Icons.north_east_rounded,
              label: ref.tr('highest'),
              value: 'RM${high.toStringAsFixed(2)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryGreen, width: 1.5),
          ),
          child: Icon(icon, size: 14, color: primaryGreen),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}