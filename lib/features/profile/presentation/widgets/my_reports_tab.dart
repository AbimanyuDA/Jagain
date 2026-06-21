import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../domain/models/user_profile.dart';
import 'profile_theme.dart';

class MyReportsTab extends StatelessWidget {
  final List<UserReport> reports;

  const MyReportsTab({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _EmptyState(
        icon: Icons.campaign_outlined,
        title: 'Belum Ada Laporan',
        subtitle:
            'Mulai berkontribusi dengan melaporkan\nmasalah infrastruktur di sekitarmu.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = reports[index];
        return _MyReportCard(report: report);
      },
    );
  }
}

class _MyReportCard extends StatelessWidget {
  final UserReport report;

  const _MyReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final statusStyle = StatusStyle.fromStatus(report.status);
    final catBg = CategoryStyle.backgroundColor(report.category);
    final catFg = CategoryStyle.textColor(report.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              height: 110,
              child: report.imageUrl.isNotEmpty
                  ? AppNetworkImage(
                      url: report.imageUrl,
                      width: 100,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            report.category,
                            style: TextStyle(
                              color: catFg,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          report.timeAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ProfileColors.navyDark,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${report.upvotes}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusStyle.icon,
                                size: 12,
                                color: statusStyle.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                report.status.label,
                                style: TextStyle(
                                  color: statusStyle.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: ProfileColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ProfileColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9E9E9E),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
