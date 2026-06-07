import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import 'profile_theme.dart';

class SupportedReportsTab extends StatelessWidget {
  final List<SupportedReport> reports;

  const SupportedReportsTab({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada laporan yang didukung'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _SupportedReportCard(report: reports[index]);
      },
    );
  }
}

class _SupportedReportCard extends StatelessWidget {
  final SupportedReport report;

  const _SupportedReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final statusStyle = StatusStyle.fromStatus(report.status);
    final catBg = CategoryStyle.backgroundColor(report.category);
    final catFg = CategoryStyle.textColor(report.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: report.imageUrl.isNotEmpty
                      ? Image.network(
                          report.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: catBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.category,
                      style: TextStyle(
                        color: catFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          report.isSaved
                              ? Icons.bookmark_rounded
                              : Icons.arrow_upward_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.isSaved ? 'Disimpan' : 'Didukung',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: report.authorAvatarUrl.isNotEmpty
                            ? NetworkImage(report.authorAvatarUrl)
                            : null,
                        backgroundColor: Colors.grey.shade200,
                        child: report.authorAvatarUrl.isEmpty
                            ? Text(
                                report.authorName.isNotEmpty
                                    ? report.authorName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.black54,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        report.authorName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(width: 6),
                      Text(
                        report.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${report.upvotes}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusStyle.icon,
                          size: 13,
                          color: statusStyle.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          report.status.label,
                          style: TextStyle(
                            color: statusStyle.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
