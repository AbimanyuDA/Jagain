import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/domain/user_model.dart';
import '../../../app/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _roleName(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return 'Warga';
      case UserRole.official:
        return 'Pejabat Daerah';
      case UserRole.admin:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;
          final isCitizen = user.role == UserRole.citizen;
          final isPendingOfficial =
              user.role == UserRole.official && !user.isVerified;
          final isAdmin = user.role == UserRole.admin;
          final isVerifiedOfficial =
              user.role == UserRole.official && user.isVerified;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Info User ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: user.avatarUrl.isEmpty
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 24),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${user.username}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Tombol Edit Profil ──
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF1B3564),
                  ),
                  title: const Text('Edit Profil'),
                  subtitle: const Text('Ubah nama, foto, dan data akun'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
              ),

              const SizedBox(height: 12),

              // ── Role Badge ──
              Card(
                child: ListTile(
                  leading: Icon(
                    user.role == UserRole.admin
                        ? Icons.admin_panel_settings
                        : user.role == UserRole.official
                            ? Icons.verified_user
                            : Icons.person,
                    color: user.role == UserRole.admin
                        ? Colors.red
                        : user.role == UserRole.official
                            ? Colors.blue
                            : Colors.grey,
                  ),
                  title: const Text('Peran'),
                  subtitle: Text(_roleName(user.role)),
                  trailing: isPendingOfficial
                      ? Chip(
                          label: const Text(
                            'Menunggu Verifikasi',
                            style: TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.orange.shade100,
                          labelStyle: TextStyle(color: Colors.orange.shade800),
                        )
                      : user.isVerified && user.role == UserRole.official
                          ? Chip(
                              label: const Text(
                                'Terverifikasi',
                                style: TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.green.shade100,
                              labelStyle:
                                  TextStyle(color: Colors.green.shade800),
                            )
                          : null,
                ),
              ),

              const SizedBox(height: 12),

              // ── Dashboard Admin (hanya admin) ──
              if (isAdmin) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.red,
                    ),
                    title: const Text('Dashboard Admin'),
                    subtitle: const Text(
                      'Kelola pengajuan pejabat, kategori, dan laporan',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.adminDashboard),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Dashboard Pejabat (hanya pejabat terverifikasi) ──
              if (isVerifiedOfficial) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.dashboard_customize,
                      color: Colors.blue,
                    ),
                    title: const Text('Dashboard Pejabat'),
                    subtitle: const Text(
                      'Lihat laporan dan statistik wilayah kerja',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.pejabatDashboard),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Ajukan Pejabat (hanya citizen) ──
              if (isCitizen)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.upgrade,
                      color: Color(0xFF1565C0),
                    ),
                    title: const Text('Ajukan sebagai Pejabat Daerah'),
                    subtitle: const Text(
                      'Verifikasi oleh admin diperlukan',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.requestOfficial),
                  ),
                ),

              // ── Pending Info (pejabat belum diverifikasi) ──
              if (isPendingOfficial)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pengajuan Anda sebagai pejabat daerah sedang '
                            'menunggu verifikasi dari admin.',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Logout ──
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar'),
                      content: const Text(
                        'Apakah Anda yakin ingin keluar dari akun?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context
                                .read<AuthBloc>()
                                .add(AuthLogoutRequested());
                          },
                          child: const Text(
                            'Keluar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
