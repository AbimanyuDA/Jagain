import 'package:flutter/material.dart';

import '../../auth/domain/user_model.dart';
import '../data/admin_repository.dart';

const _navy = Color(0xFF0F1E36);

class OfficialVerificationScreen extends StatefulWidget {
  const OfficialVerificationScreen({super.key});

  @override
  State<OfficialVerificationScreen> createState() =>
      _OfficialVerificationScreenState();
}

class _OfficialVerificationScreenState
    extends State<OfficialVerificationScreen> {
  final AdminRepository _repository = AdminRepository();
  final Set<String> _processingIds = {};

  Future<void> _decide(UserModel official, bool verify) async {
    setState(() => _processingIds.add(official.uid));
    try {
      if (verify) {
        await _repository.verifyOfficial(official.uid);
      } else {
        await _repository.rejectOfficial(official.uid);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verify
                  ? 'Akun ${official.name} terverifikasi sebagai pejabat.'
                  : 'Pengajuan ${official.name} ditolak, akun dikembalikan ke peran warga.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memproses akun: $e')));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(official.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Akun Pejabat')),
      body: StreamBuilder<List<UserModel>>(
        stream: _repository.watchPendingOfficials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }

          final officials = snapshot.data ?? const [];
          if (officials.isEmpty) {
            return const Center(
              child: Text('Tidak ada pengajuan akun pejabat baru.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: officials.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final official = officials[index];
              final isProcessing = _processingIds.contains(official.uid);

              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: official.avatarUrl.isNotEmpty
                                ? NetworkImage(official.avatarUrl)
                                : null,
                            child: official.avatarUrl.isEmpty
                                ? Text(
                                    official.name.isNotEmpty
                                        ? official.name[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  official.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _navy,
                                  ),
                                ),
                                Text(
                                  official.email,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Wilayah: ${official.wilayah ?? '-'}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => _decide(official, false),
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
                                  : () => _decide(official, true),
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
                                  : const Text('Verifikasi'),
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
