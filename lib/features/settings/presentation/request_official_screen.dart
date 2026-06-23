import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../../app/routes.dart';
import '../../../core/data/indonesia_regions.dart';
import '../../../core/widgets/region_selector_bottom_sheet.dart';

class RequestOfficialScreen extends StatefulWidget {
  const RequestOfficialScreen({super.key});

  @override
  State<RequestOfficialScreen> createState() => _RequestOfficialScreenState();
}

class _RequestOfficialScreenState extends State<RequestOfficialScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedLevel = 'Kecamatan'; // default
  String? _selectedProvinsi;
  String? _selectedKota;
  final _kecamatanController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Update preview real-time saat user mengetik kecamatan
    _kecamatanController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _kecamatanController.dispose();
    super.dispose();
  }

  /// Buka bottom sheet pemilih provinsi
  Future<void> _pickProvinsi() async {
    final result = await showRegionSelectorSheet(
      context: context,
      title: 'Pilih Provinsi',
      items: IndonesiaRegions.provinsi,
      selected: _selectedProvinsi,
    );
    if (result != null) {
      setState(() {
        _selectedProvinsi = result;
        // Reset kota jika provinsi berubah
        _selectedKota = null;
        _kecamatanController.clear();
      });
    }
  }

  /// Buka bottom sheet pemilih kota/kabupaten
  Future<void> _pickKota() async {
    if (_selectedProvinsi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih provinsi terlebih dahulu')),
      );
      return;
    }
    final kota = IndonesiaRegions.getKota(_selectedProvinsi!);
    final result = await showRegionSelectorSheet(
      context: context,
      title: 'Pilih Kota / Kabupaten',
      items: kota,
      selected: _selectedKota,
    );
    if (result != null) {
      setState(() {
        _selectedKota = result;
        _kecamatanController.clear();
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Validasi region fields
    if (_selectedLevel != 'Pusat') {
      if (_selectedProvinsi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih provinsi terlebih dahulu')),
        );
        return;
      }
    }
    if (_selectedLevel == 'Kota / Kabupaten' || _selectedLevel == 'Kecamatan') {
      if (_selectedKota == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kota / kabupaten terlebih dahulu')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    String wilayahString;
    if (_selectedLevel == 'Pusat') {
      wilayahString = 'Pusat';
    } else if (_selectedLevel == 'Provinsi') {
      wilayahString = '${_selectedProvinsi!} -> Pusat';
    } else if (_selectedLevel == 'Kota / Kabupaten') {
      wilayahString = '${_selectedKota!} -> ${_selectedProvinsi!} -> Pusat';
    } else {
      // Kecamatan
      final kec = _kecamatanController.text.trim();
      wilayahString = '$kec -> ${_selectedKota!} -> ${_selectedProvinsi!} -> Pusat';
    }

    context.read<AuthBloc>().add(
          AuthUpgradeToOfficialRequested(wilayah: wilayahString),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan sebagai Pejabat')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengajuan berhasil! Menunggu verifikasi admin.'),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRoutes.settings); // langsung ke Settings, bukan pop
          }
          if (state is AuthError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Card ──
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dengan mengajukan diri sebagai pejabat daerah, '
                            'Anda akan dapat menangani laporan warga di '
                            'wilayah Anda. Pengajuan akan diverifikasi '
                            'oleh admin.',
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Tingkat Wilayah Dropdown ──
                const Text(
                  'Tingkat Jabatan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.layers),
                    border: OutlineInputBorder(),
                    hintText: 'Pilih tingkat wilayah kerja',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Kecamatan', child: Text('Kecamatan')),
                    DropdownMenuItem(
                        value: 'Kota / Kabupaten',
                        child: Text('Kota / Kabupaten')),
                    DropdownMenuItem(
                        value: 'Provinsi', child: Text('Provinsi')),
                    DropdownMenuItem(
                        value: 'Pusat', child: Text('Pusat (Nasional)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedLevel = val;
                        _selectedProvinsi = null;
                        _selectedKota = null;
                        _kecamatanController.clear();
                      });
                    }
                  },
                ),

                // ── Provinsi ──
                if (_selectedLevel != 'Pusat') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Provinsi',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _RegionPickerTile(
                    icon: Icons.map_outlined,
                    label: _selectedProvinsi ?? 'Pilih Provinsi',
                    isPlaceholder: _selectedProvinsi == null,
                    onTap: _pickProvinsi,
                  ),
                ],

                // ── Kota / Kabupaten ──
                if (_selectedLevel == 'Kota / Kabupaten' ||
                    _selectedLevel == 'Kecamatan') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Kota / Kabupaten',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _RegionPickerTile(
                    icon: Icons.location_city_outlined,
                    label: _selectedKota ?? 'Pilih Kota / Kabupaten',
                    isPlaceholder: _selectedKota == null,
                    onTap: _pickKota,
                    disabled: _selectedProvinsi == null,
                  ),
                ],

                // ── Kecamatan ──
                if (_selectedLevel == 'Kecamatan') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Kecamatan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _kecamatanController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Tambaksari',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (_selectedLevel == 'Kecamatan') {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama kecamatan wajib diisi';
                        }
                      }
                      return null;
                    },
                  ),
                ],

                // ── Ringkasan wilayah ──
                if (_selectedLevel == 'Pusat' ||
                    (_selectedProvinsi != null)) ...[
                  const SizedBox(height: 16),
                  _buildWilayahPreview(),
                ],

                const SizedBox(height: 32),

                // ── Submit ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                        _isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWilayahPreview() {
    String preview;
    if (_selectedLevel == 'Pusat') {
      preview = 'Pusat (Nasional)';
    } else if (_selectedLevel == 'Provinsi') {
      preview = _selectedProvinsi == null
          ? '—'
          : '${_selectedProvinsi!} → Pusat';
    } else if (_selectedLevel == 'Kota / Kabupaten') {
      if (_selectedKota == null) {
        preview = '—';
      } else {
        preview = '${_selectedKota!} → ${_selectedProvinsi!} → Pusat';
      }
    } else {
      final kec = _kecamatanController.text.trim();
      if (_selectedKota == null) {
        preview = '—';
      } else if (kec.isEmpty) {
        preview = '(kecamatan) → ${_selectedKota!} → ${_selectedProvinsi!} → Pusat';
      } else {
        preview = '$kec → ${_selectedKota!} → ${_selectedProvinsi!} → Pusat';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wilayah Kerja',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
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

/// Tile interaktif untuk memilih wilayah via bottom sheet
class _RegionPickerTile extends StatelessWidget {
  const _RegionPickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPlaceholder = false,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPlaceholder;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : isPlaceholder
                    ? Colors.grey.shade400
                    : const Color(0xFF1B3564),
          ),
          borderRadius: BorderRadius.circular(8),
          color: disabled ? Colors.grey.shade100 : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: disabled
                  ? Colors.grey.shade400
                  : isPlaceholder
                      ? Colors.grey.shade500
                      : const Color(0xFF1B3564),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? Colors.grey.shade400
                      : isPlaceholder
                          ? Colors.grey.shade500
                          : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: disabled ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
