import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';

class RequestOfficialScreen extends StatefulWidget {
  const RequestOfficialScreen({super.key});

  @override
  State<RequestOfficialScreen> createState() => _RequestOfficialScreenState();
}

class _RequestOfficialScreenState extends State<RequestOfficialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wilayahController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _wilayahController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    context.read<AuthBloc>().add(
          AuthUpgradeToOfficialRequested(
            wilayah: _wilayahController.text.trim(),
          ),
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
                content: Text(
                  'Pengajuan berhasil! Menunggu verifikasi admin.',
                ),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(); // kembali ke settings
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

                // ── Wilayah ──
                TextFormField(
                  controller: _wilayahController,
                  decoration: const InputDecoration(
                    labelText: 'Wilayah Kerja',
                    hintText: 'Contoh: Kota Surabaya',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Wilayah wajib diisi';
                    }
                    if (val.trim().length < 3) {
                      return 'Wilayah minimal 3 karakter';
                    }
                    return null;
                  },
                ),

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
                      _isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan',
                    ),
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
}
