import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';

/// ProfileHeader — menampilkan identitas, avatar, lencana, jumlah pengikut, dan aksi ikuti/kirim pesan.
class ProfileHeader extends StatefulWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.isOwnProfile = true,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  late bool _isFollowing;
  late int _followersCount;

  @override
  void initState() {
    super.initState();
    _isFollowing = false; // Default belum mengikuti user lain
    _followersCount = widget.profile.followersCount;
  }

  @override
  void didUpdateWidget(covariant ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _isFollowing = false;
      _followersCount = widget.profile.followersCount;
    }
  }

  void _toggleFollow() {
    if (_isFollowing) {
      // Konfirmasi Batal Mengikuti ala Instagram
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Batal mengikuti @${widget.profile.username}?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F1E36),
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Anda tidak akan menerima update laporan dari warga ini di feed lagi.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isFollowing = false;
                  _followersCount--;
                });
              },
              child: const Text(
                'Batal Mengikuti',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      // Ikuti langsung
      setState(() {
        _isFollowing = true;
        _followersCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar center ──────────────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32, // Diperkecil dari 36 ke 32
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: NetworkImage(widget.profile.avatarUrl),
                  ),
                ),
                if (widget.profile.isVerifiedCitizen)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A550),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 10, // Diperkecil
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4), // Diperkecil dari 8 ke 4

            // ── Nama Lengkap ───────────────────────────────────────────
            Text(
              widget.profile.displayName,
              style: const TextStyle(
                color: Color(0xFF0F1E36),
                fontWeight: FontWeight.w800,
                fontSize: 15, // Diperkecil dari 17 ke 15
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2), // Diperkecil dari 4 ke 2

            // ── Lokasi ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 2),
                Text(
                  widget.profile.domicile,
                  style: TextStyle(
                    fontSize: 11, // Diperkecil dari 12 ke 11
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // Diperkecil dari 8 ke 4

            // ── Badge chips ────────────────────────────────────────────
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (widget.profile.isVerifiedCitizen)
                  _BadgeChip(
                    label: 'Verified Citizen',
                    icon: Icons.shield_rounded,
                    color: const Color(0xFF00A550),
                    bgColor: const Color(0xFFE6F8EF),
                  ),
                _BadgeChip(
                  label: widget.profile.gamificationTitle,
                  icon: Icons.military_tech_rounded,
                  color: const Color(0xFFB45309),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ],
            ),
            const SizedBox(height: 8), // Diperkecil dari 12 ke 8

            // ── Followers & Following counts ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12, // Diperkecil dari 13 ke 12
                      color: Color(0xFF0F1E36),
                    ),
                    children: [
                      TextSpan(
                        text: '$_followersCount ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(
                        text: 'pengikut',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12, // Diperkecil dari 13 ke 12
                      color: Color(0xFF0F1E36),
                    ),
                    children: [
                      TextSpan(
                        text: '${widget.profile.followingCount} ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(
                        text: 'mengikuti',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Diperkecil dari 14 ke 8

            // ── Actions: Edit Profil or Follow/Message ─────────────────
            if (widget.isOwnProfile)
              SizedBox(
                width: double.infinity,
                height: 30, // Diperkecil dari 32 ke 30
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                    foregroundColor: const Color(0xFF0F1E36),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12, // Diperkecil dari 13 ke 12
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Edit Profil'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 30, // Diperkecil dari 32 ke 30
                      child: _isFollowing
                          ? OutlinedButton(
                              onPressed: _toggleFollow,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300, width: 1),
                                foregroundColor: const Color(0xFF0F1E36),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Mengikuti',
                                style: TextStyle(
                                  color: Color(0xFF0F1E36),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12, // Diperkecil dari 13 ke 12
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F1E36),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Ikuti',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12, // Diperkecil dari 13 ke 12
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 30, // Diperkecil dari 32 ke 30
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                          foregroundColor: const Color(0xFF0F1E36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kirim Pesan',
                          style: TextStyle(
                            color: Color(0xFF0F1E36),
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Diperkecil dari 13 ke 12
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Chip ─────────────────────────────────────────────────────────────────
class _BadgeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Diperkecil
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color), // Diperkecil
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10, // Diperkecil dari 11 ke 10
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
