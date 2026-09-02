import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';

class TrendChart extends ConsumerWidget {
  final List<Map<String, dynamic>> records;

  const TrendChart({super.key, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<double> prices = [];
    List<String> monthLabels = [];

    final validRecords = records
        .where((r) => ((r['price'] as num?) ?? 0) > 0)
        .toList();

    if (validRecords.length >= 2) {
      final sample = validRecords.take(7).toList();
      prices = sample.map((r) => (r['price'] as num).toDouble()).toList();
      monthLabels = sample.map((r) {
        final date = DateTime.tryParse(r['date'].toString());
        return date == null ? '' : '${date.day}/${date.month}';
      }).toList();
    }

    if (prices.length < 2) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            ref.tr('not_enough_price_data_for_trend'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ),
      );
    }

    final double minP = prices.reduce(min);
    final double maxP = prices.reduce(max);

    final double minY = (minP - 1).floorToDouble().clamp(0, double.infinity);
    final double maxY = (maxP + 1).ceilToDouble();
    final double midY = (minY + maxY) / 2;

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-Axis Labels
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM${maxY.toInt()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
                Text(
                  'RM${midY.toInt()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
                Text(
                  'RM${minY.toInt()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Line Chart Canvas
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(
                prices: prices,
                minY: minY,
                maxY: maxY,
                monthLabels: monthLabels,
                primaryGreen: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> prices;
  final double minY;
  final double maxY;
  final List<String> monthLabels;
  final Color primaryGreen;

  _ChartPainter({
    required this.prices,
    required this.minY,
    required this.maxY,
    required this.monthLabels,
    required this.primaryGreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomPadding = 24.0;
    final double chartHeight = size.height - bottomPadding;
    final double chartWidth = size.width;

    final axisPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = primaryGreen
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = primaryGreen
      ..style = PaintingStyle.fill;

    // 1. Draw Axis Box Line (L-Shape)
    canvas.drawLine(const Offset(0, 0), Offset(0, chartHeight), axisPaint);
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(chartWidth, chartHeight),
      axisPaint,
    );

    // 2. Draw Dashed Grid Lines (Top, Middle, Bottom)
    final yPositions = [0.0, chartHeight / 2, chartHeight];
    for (final y in yPositions) {
      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 3. Calculate Point Coordinates
    final range = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
    final stepX = chartWidth / (prices.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < prices.length; i++) {
      final x = i * stepX;
      final normalizedY = (prices[i] - minY) / range;
      final y = chartHeight - (normalizedY * chartHeight);
      points.add(Offset(x, y));
    }

    // 4. Draw Straight Graph Line
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // 5. Draw Dots & X-Axis Labels
    const textStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0xFF333333),
    );

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.5, dotPaint);

      if (i < monthLabels.length) {
        final textSpan = TextSpan(text: monthLabels[i], style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            points[i].dx - (textPainter.width / 2),
            chartHeight + 6,
          ),
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double currentX = start.dx;

    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(min(currentX + dashWidth, end.dx), start.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}