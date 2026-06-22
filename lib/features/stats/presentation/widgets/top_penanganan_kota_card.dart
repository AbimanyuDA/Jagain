import 'package:flutter/material.dart';

import '../bloc/stats_state.dart';

class TopPenangananKotaCard extends StatelessWidget {
  final List<KotaResolutionStat> topKota;

  const TopPenangananKotaCard({super.key, required this.topKota});

  static const _medals = [
    (Icons.workspace_premium, Color(0xFFFFB300)),
    (Icons.workspace_premium, Color(0xFFB0BEC5)),
    (Icons.workspace_premium, Color(0xFFA1887F)),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            'Top Penanganan Kota/Kabupaten',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < topKota.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (i < _medals.length)
                    Icon(_medals[i].$1, color: _medals[i].$2, size: 22)
                  else
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topKota[i].kota,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${(topKota[i].resolvedRate * 100).toStringAsFixed(1)}% Selesai',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
