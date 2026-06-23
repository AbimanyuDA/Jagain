import 'package:flutter/material.dart';

import '../../data/stats_repository.dart';

class TopPenangananCard extends StatelessWidget {
  final String title;
  final List<RegionResolutionStat> items;

  const TopPenangananCard({
    super.key,
    required this.title,
    required this.items,
  });

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
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++)
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
                      items[i].name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${(items[i].resolvedRate * 100).toStringAsFixed(1)}% Selesai',
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
