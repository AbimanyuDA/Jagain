import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../feed/data/report_repository.dart';
import '../../feed/domain/models/report_post.dart';
import '../../feed/domain/models/report_update.dart';
import '../../feed/presentation/report_detail_screen.dart';

/// Wraps the existing [ReportDetailScreen] with official-only controls
/// (FAB to add updates, edit/delete on timeline entries).
class PejabatReportDetailScreen extends StatelessWidget {
  final ReportPost post;

  const PejabatReportDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ReportDetailScreen(
          post: post,
          updateActionBuilder: (context, update) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showUpdateSheet(
                  context,
                  reportId: post.id,
                  currentStatus: post.status,
                  existing: update,
                ),
                child: Icon(Icons.edit_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => showDeleteDialog(
                  context,
                  reportId: post.id,
                  updateId: update.id,
                ),
                child: Icon(Icons.delete_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showUpdateSheet(
              context,
              reportId: post.id,
              currentStatus: post.status,
            ),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.edit_note),
            label: const Text('Update'),
          ),
        ),
      ],
    );
  }

  static void _showUpdateSheet(
    BuildContext context, {
    required String reportId,
    required ReportPostStatus currentStatus,
    ReportUpdate? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _UpdateSheet(
        reportId: reportId,
        currentStatus: currentStatus,
        existing: existing,
      ),
    );
  }

  static void showEditSheet(
    BuildContext context, {
    required String reportId,
    required ReportPostStatus currentStatus,
    required ReportUpdate update,
  }) {
    _showUpdateSheet(
      context,
      reportId: reportId,
      currentStatus: currentStatus,
      existing: update,
    );
  }

  static Future<bool?> showDeleteDialog(
    BuildContext context, {
    required String reportId,
    required String updateId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Hapus Update'),
          content: const Text(
              'Update ini akan dihapus permanen. Lanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ReportRepository().deleteUpdate(
                    reportId: reportId,
                    updateId: updateId,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus: $e')),
                    );
                    Navigator.of(ctx).pop(false);
                  }
                }
              },
              child: Text('Hapus',
                  style: TextStyle(color: colorScheme.error)),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update Sheet (handles both create and edit)
// ─────────────────────────────────────────────────────────────────────────────

class _UpdateSheet extends StatefulWidget {
  final String reportId;
  final ReportPostStatus currentStatus;
  final ReportUpdate? existing;

  const _UpdateSheet({
    required this.reportId,
    required this.currentStatus,
    this.existing,
  });

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final _repo = ReportRepository();
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  ReportPostStatus? _newStatus;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _descriptionController.text = widget.existing!.description;
      _existingImageUrls =
          List<String>.from(widget.existing!.imageUrls ?? []);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _newImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  bool get _requiresPhoto =>
      _newStatus == ReportPostStatus.solved;

  bool get _hasImages =>
      _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      !_isSubmitting &&
      (!_requiresPhoto || _hasImages);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    try {
      if (_isEditing) {
        await _repo.editUpdate(
          reportId: widget.reportId,
          updateId: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          newImages: _newImages.isNotEmpty ? _newImages : null,
          existingImageUrls:
              _existingImageUrls.isNotEmpty ? _existingImageUrls : null,
        );
      } else {
        await _repo.addUpdate(
          reportId: widget.reportId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          images: _newImages.isNotEmpty ? _newImages : null,
          newStatus: _newStatus,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Update berhasil diedit'
                : 'Update berhasil dikirim'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEditing ? 'Edit Update' : 'Tambah Update',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Judul Update',
                  hintText: 'cth: Perbaikan dimulai',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Jelaskan progres terbaru...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status change (only for create)
              if (!_isEditing) ...[
                Text(
                  'Ubah Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Opsional | Status saat ini: '),
                      TextSpan(
                        text: widget.currentStatus.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ReportPostStatus.values
                      .where((s) => s != widget.currentStatus)
                      .map((status) {
                    final selected = _newStatus == status;
                    return FilterChip(
                      label: Text(
                        status.label,
                        style: TextStyle(
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: selected,
                      selectedColor: colorScheme.primary,
                      checkmarkColor: colorScheme.onPrimary,
                      onSelected: (val) {
                        setState(() => _newStatus = val ? status : null);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Photos
              Text(
                'Foto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  children: const [
                    TextSpan(text: 'Untuk '),
                    TextSpan(
                      text: 'menyelesaikan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' laporan foto bukti wajib dilampirkan'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images (from edit)
                    ..._existingImageUrls.asMap().entries.map((entry) =>
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  url: entry.value,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () =>
                                      _removeExistingImage(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    // New images (from picker)
                    ..._newImages.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  entry.value,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removeNewImage(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_photo_alternate_outlined,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor:
                        colorScheme.surfaceContainerHigh,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(_isEditing ? 'Simpan' : 'Kirim Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
