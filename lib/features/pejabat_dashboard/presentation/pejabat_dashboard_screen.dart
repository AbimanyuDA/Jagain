import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/user_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../feed/domain/models/report_post.dart';
import '../data/pejabat_repository.dart';

const _navy = Color(0xFF0F1E36);
const _primary = Color(0xFF2E5BFF);

class PejabatDashboardScreen extends StatelessWidget {
  const PejabatDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final official = authState is AuthAuthenticated ? authState.user : null;

    if (official == null || official.role != UserRole.official) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Pejabat')),
        body: const Center(
          child: Text('Halaman ini khusus untuk akun Pejabat terverifikasi.'),
        ),
      );
    }

    final wilayah = official.wilayah ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Pejabat - Jagain')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${official.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Wilayah Administrasi: ${wilayah.isEmpty ? '-' : wilayah}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Laporan Wilayah Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _RegionalReportsList(wilayah: wilayah, official: official),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionalReportsList extends StatefulWidget {
  final String wilayah;
  final UserModel official;

  const _RegionalReportsList({required this.wilayah, required this.official});

  @override
  State<_RegionalReportsList> createState() => _RegionalReportsListState();
}

class _RegionalReportsListState extends State<_RegionalReportsList> {
  final PejabatRepository _repository = PejabatRepository();

  @override
  Widget build(BuildContext context) {
    if (widget.wilayah.isEmpty) {
      return const Center(
        child: Text('Wilayah administrasi belum diatur pada akun Anda.'),
      );
    }

    return StreamBuilder<List<ReportPost>>(
      stream: _repository.watchRegionalReports(
        widget.wilayah,
        currentUserId: widget.official.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat laporan: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return const Center(
            child: Text('Belum ada laporan dari wilayah ini.'),
          );
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final report = reports[index];
            return _RegionalReportCard(
              report: report,
              onProcess: () => _openStatusUpdateSheet(report),
            );
          },
        );
      },
    );
  }

  Future<void> _openStatusUpdateSheet(ReportPost report) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _StatusUpdateSheet(
        report: report,
        official: widget.official,
        repository: _repository,
      ),
    );
  }
}

class _RegionalReportCard extends StatelessWidget {
  final ReportPost report;
  final VoidCallback onProcess;

  const _RegionalReportCard({required this.report, required this.onProcess});

  _StatusStyle get _statusStyle => _StatusStyle.of(report.status);

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle;
    final canProcess =
        report.status != ReportPostStatus.solved &&
        report.status != ReportPostStatus.rejected;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: style.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.status.label,
                    style: TextStyle(
                      color: style.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${report.category} • Dilaporkan oleh @${report.userName} • ${report.timeAgo}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: canProcess ? onProcess : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(canProcess ? 'Proses' : 'Selesai Ditangani'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color color;
  final Color backgroundColor;

  const _StatusStyle({required this.color, required this.backgroundColor});

  static _StatusStyle of(ReportPostStatus status) {
    switch (status) {
      case ReportPostStatus.solved:
        return const _StatusStyle(
          color: Color(0xFF00A550),
          backgroundColor: Color(0xFFE6F8EF),
        );
      case ReportPostStatus.inProgress:
        return const _StatusStyle(
          color: _primary,
          backgroundColor: Color(0xFFEEF2FF),
        );
      case ReportPostStatus.waitingReview:
        return const _StatusStyle(
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFFFFF3E0),
        );
      case ReportPostStatus.rejected:
        return const _StatusStyle(
          color: Color(0xFFD32F2F),
          backgroundColor: Color(0xFFFFEBEE),
        );
    }
  }
}

class _StatusUpdateSheet extends StatefulWidget {
  final ReportPost report;
  final UserModel official;
  final PejabatRepository repository;

  const _StatusUpdateSheet({
    required this.report,
    required this.official,
    required this.repository,
  });

  @override
  State<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<_StatusUpdateSheet> {
  static const _selectableStatuses = [
    ReportPostStatus.inProgress,
    ReportPostStatus.solved,
    ReportPostStatus.rejected,
  ];

  final _noteController = TextEditingController();
  final _picker = ImagePicker();

  late ReportPostStatus _selectedStatus;
  File? _proofImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status == ReportPostStatus.waitingReview
        ? ReportPostStatus.inProgress
        : widget.report.status;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _proofImage = File(file.path));
    }
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulis catatan penanganan terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.repository.updateReportStatus(
        reportId: widget.report.id,
        status: _selectedStatus,
        note: note,
        proofImage: _proofImage,
        official: widget.official,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status laporan berhasil diperbarui.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Proses Laporan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.report.title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReportPostStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status Baru',
                border: OutlineInputBorder(),
              ),
              items: _selectableStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedStatus = val ?? _selectedStatus),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan Penanganan',
                hintText: 'Jelaskan tindakan yang sudah/akan dilakukan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildProofPicker(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan & Kirim Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Bukti Penanganan (opsional)',
          style: TextStyle(fontWeight: FontWeight.w600, color: _navy),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickProofImage,
          child: _proofImage == null
              ? Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                      SizedBox(height: 6),
                      Text(
                        'Ambil Foto Bukti',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _proofImage!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _proofImage = null),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
