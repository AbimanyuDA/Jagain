import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

({String label, Color color}) _responsifLevel(double responsifRate) {
  if (responsifRate >= 0.90) {
    return (label: 'Sangat Responsif', color: const Color(0xFF00A550));
  } else if (responsifRate >= 0.75) {
    return (label: 'Responsif', color: const Color(0xFF26A69A));
  } else if (responsifRate >= 0.60) {
    return (label: 'Cukup Responsif', color: const Color(0xFFF59E0B));
  } else if (responsifRate >= 0.40) {
    return (label: 'Kurang Responsif', color: const Color(0xFFF57C00));
  } else {
    return (label: 'Tidak Responsif', color: const Color(0xFFD32F2F));
  }
}

class ResponsivitasCard extends StatelessWidget {
  final double responsifRate;
  final double apatisRate;

  const ResponsivitasCard({
    super.key,
    required this.responsifRate,
    required this.apatisRate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final responsifPct = (responsifRate * 100).toStringAsFixed(0);
    final apatisPct = (apatisRate * 100).toStringAsFixed(0);
    final level = _responsifLevel(responsifRate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Skor Responsivitas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    centerSpaceRadius: 60,
                    sectionsSpace: 0,
                    sections: [
                      PieChartSectionData(
                        value: responsifRate,
                        color: level.color,
                        showTitle: false,
                        radius: 22,
                      ),
                      PieChartSectionData(
                        value: apatisRate == 0 ? 0.0001 : apatisRate,
                        color: colorScheme.outlineVariant,
                        showTitle: false,
                        radius: 22,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$responsifPct%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'RESPONSIF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$apatisPct%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Apatis',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: level.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  level.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: level.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
