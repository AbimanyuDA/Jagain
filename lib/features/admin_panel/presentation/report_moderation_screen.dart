import 'package:flutter/material.dart';

import '../../feed/domain/models/report_post.dart';
import '../data/admin_repository.dart';

const _navy = Color(0xFF0F1E36);

class ReportModerationScreen extends StatefulWidget {
  const ReportModerationScreen({super.key});

  @override
  State<ReportModerationScreen> createState() => _ReportModerationScreenState();
}

class _ReportModerationScreenState extends State<ReportModerationScreen> {
  final AdminRepository _repository = AdminRepository();
  final Set<String> _processingIds = {};

  Future<void> _moderate(ReportPost report, bool approve) async {
    setState(() => _processingIds.add(report.id));
    try {
      await _repository.moderateReport(reportId: report.id, approve: approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Laporan "${report.title}" disetujui dan diteruskan ke pejabat wilayah.'
                  : 'Laporan "${report.title}" ditolak.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memproses laporan: $e')));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(report.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderasi Laporan')),
      body: StreamBuilder<List<ReportPost>>(
        stream: _repository.watchPendingReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat laporan: ${snapshot.error}'),
            );
          }

          final reports = snapshot.data ?? const [];
          if (reports.isEmpty) {
            return const Center(
              child: Text('Tidak ada laporan yang menunggu review.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = reports[index];
              final isProcessing = _processingIds.contains(report.id);

              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (report.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                report.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (report.imageUrl.isNotEmpty)
                            const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${report.category} • @${report.userName} • ${report.wilayah}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => _moderate(report, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD32F2F),
                                side: const BorderSide(
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                              child: const Text('Tolak'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => _moderate(report, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A550),
                                foregroundColor: Colors.white,
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Setujui'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
