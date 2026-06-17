import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/user_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../feed/data/report_repository.dart';
import '../../feed/domain/models/report_post.dart';

// ── Warna tema ──────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF1B3564);
const _kNavyLight = Color(0xFF2A4A8A);

class PejabatDashboardScreen extends StatefulWidget {
  const PejabatDashboardScreen({super.key});

  @override
  State<PejabatDashboardScreen> createState() => _PejabatDashboardScreenState();
}

class _PejabatDashboardScreenState extends State<PejabatDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = ReportRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _extractWilayahLabel(String? wilayah) {
    if (wilayah == null || wilayah.isEmpty) return 'Semua Wilayah';
    // Ambil bagian pertama: "Kota Surabaya -> Jawa Timur -> Pusat" → "Kota Surabaya"
    return wilayah.split(' -> ').first;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(user, innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReportTab(user, null),                                   // Semua
                  _buildReportTab(user, ReportPostStatus.waitingReview),         // Menunggu
                  _buildReportTab(user, ReportPostStatus.inProgress),            // Diproses
                  _buildReportTab(user, ReportPostStatus.solved),                // Selesai
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver App Bar dengan info pejabat ──────────────────────────────────
  SliverAppBar _buildSliverAppBar(UserModel user, bool innerBoxIsScrolled) {
    final wilayahLabel = _extractWilayahLabel(user.wilayah);

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _kNavy,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: () => setState(() {}),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kNavy, _kNavyLight, Color(0xFF1565C0)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: user.avatarUrl.isEmpty
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard Pejabat',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    wilayahLabel,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
        ),
        title: const Text(
          'Dashboard Pejabat',
          style: TextStyle(color: Colors.white),
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _kNavy,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _kNavy,
        indicatorWeight: 3,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Menunggu'),
          Tab(text: 'Diproses'),
          Tab(text: 'Selesai'),
        ],
      ),
    );
  }

  // ── Tab content: stream laporan ──────────────────────────────────────────
  Widget _buildReportTab(UserModel user, ReportPostStatus? statusFilter) {
    final wilayah = user.wilayah ?? '';

    // Jika wilayah kosong, tampilkan pesan
    if (wilayah.isEmpty || wilayah == 'Pusat') {
      return _buildAllReportsStream(statusFilter, user.uid);
    }

    // Ambil bagian wilayah yang relevan untuk pejabat
    // Misalnya pejabat "Kota Surabaya -> Jawa Timur -> Pusat"
    // → kita match laporan yang mengandung "Kota Surabaya"
    final wilayahKey = wilayah.split(' -> ').first;

    return StreamBuilder<List<ReportPost>>(
      stream: _repository.watchReportsByWilayahFiltered(
        wilayahKey,
        status: statusFilter,
        currentUserId: user.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }
        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return _buildEmpty(statusFilter);
        }

        return Column(
          children: [
            _buildSummaryRow(reports),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                itemBuilder: (ctx, i) => _ReportCard(
                  report: reports[i],
                  onStatusUpdate: (newStatus, note) async {
                    await _repository.updateReportStatus(
                      reportId: reports[i].id,
                      newStatus: newStatus,
                      officialNote: note,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllReportsStream(ReportPostStatus? statusFilter, String userId) {
    final stream = statusFilter != null
        ? _repository.watchReportsByStatus(statusFilter, currentUserId: userId)
        : _repository.watchFeed(currentUserId: userId);

    return StreamBuilder<List<ReportPost>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }
        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return _buildEmpty(statusFilter);
        }

        return Column(
          children: [
            _buildSummaryRow(reports),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                itemBuilder: (ctx, i) => _ReportCard(
                  report: reports[i],
                  onStatusUpdate: (newStatus, note) async {
                    await _repository.updateReportStatus(
                      reportId: reports[i].id,
                      newStatus: newStatus,
                      officialNote: note,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Summary row (chip stats) ─────────────────────────────────────────────
  Widget _buildSummaryRow(List<ReportPost> reports) {
    final waiting =
        reports.where((r) => r.status == ReportPostStatus.waitingReview).length;
    final inProgress =
        reports.where((r) => r.status == ReportPostStatus.inProgress).length;
    final solved =
        reports.where((r) => r.status == ReportPostStatus.solved).length;
    final urgent = reports.where((r) => r.urgency == 'URGENT').length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _StatChip(
              label: 'Total', count: reports.length, color: _kNavy),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Menunggu', count: waiting, color: Colors.orange),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Proses', count: inProgress, color: Colors.blue),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Selesai', count: solved, color: Colors.green),
          if (urgent > 0) ...[
            const SizedBox(width: 8),
            _StatChip(label: 'Urgent', count: urgent, color: Colors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(ReportPostStatus? status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            status == null
                ? 'Belum ada laporan di wilayah Anda'
                : 'Tidak ada laporan berstatus "${status.label}"',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Terjadi kesalahan memuat data',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
          Text(label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

// ── Report Card ───────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onStatusUpdate});

  final ReportPost report;
  final Future<void> Function(ReportPostStatus newStatus, String? note)
      onStatusUpdate;

  Color _statusColor(ReportPostStatus status) {
    switch (status) {
      case ReportPostStatus.waitingReview:
        return Colors.orange;
      case ReportPostStatus.inProgress:
        return Colors.blue;
      case ReportPostStatus.solved:
        return Colors.green;
      case ReportPostStatus.rejected:
        return Colors.red;
    }
  }

  IconData _statusIcon(ReportPostStatus status) {
    switch (status) {
      case ReportPostStatus.waitingReview:
        return Icons.hourglass_empty_rounded;
      case ReportPostStatus.inProgress:
        return Icons.construction_rounded;
      case ReportPostStatus.solved:
        return Icons.check_circle_rounded;
      case ReportPostStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  void _showUpdateStatusDialog(BuildContext context) {
    ReportPostStatus? chosen;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Status Laporan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih status baru:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...ReportPostStatus.values
                  .where((s) => s != report.status)
                  .map(
                    (s) => InkWell(
                      onTap: () => setDialogState(() => chosen = s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              chosen == s
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: chosen == s
                                  ? _statusColor(s)
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              s.label,
                              style: TextStyle(
                                color: chosen == s
                                    ? _statusColor(s)
                                    : Colors.black87,
                                fontWeight: chosen == s
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Sudah dijadwalkan perbaikan',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: chosen == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await onStatusUpdate(chosen!, noteController.text);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Status diperbarui: ${chosen!.label}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal update: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3564),
                  foregroundColor: Colors.white),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    final isUrgent = report.urgency == 'URGENT';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: status badge + urgent tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(report.status),
                          size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        report.status.label,
                        style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (isUrgent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🔴 URGENT',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  report.timeAgo,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Judul & deskripsi
            Text(
              report.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              report.description,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Meta info
            Row(
              children: [
                Icon(Icons.category_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(report.category,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 12),
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.wilayah.split(' -> ').first,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.thumb_up_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text('${report.upvotes}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),

            const SizedBox(height: 12),

            // Action button
            if (report.status != ReportPostStatus.solved &&
                report.status != ReportPostStatus.rejected)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showUpdateStatusDialog(context),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Update Status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B3564),
                    side:
                        const BorderSide(color: Color(0xFF1B3564)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
