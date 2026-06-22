import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/stats_repository.dart';

const _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

class MonthlyTrendCard extends StatelessWidget {
  final List<MonthlyReportCount> monthlyTrend;

  const MonthlyTrendCard({super.key, required this.monthlyTrend});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = monthlyTrend
        .map((m) => m.count)
        .fold<int>(0, (max, v) => v > max ? v : max);
    final maxY = maxCount == 0 ? 5.0 : (maxCount * 1.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Laporan Bulanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthlyTrend.length) {
                          return const SizedBox.shrink();
                        }
                        final month = monthlyTrend[index].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _monthAbbreviations[month.month - 1],
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < monthlyTrend.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: monthlyTrend[i].count.toDouble(),
                          color: colorScheme.primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
