import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../data/report_repository.dart';
import '../domain/models/report_post.dart';
import '../domain/models/report_update.dart';
import 'widgets/comments_section.dart';

const double _kValidationRadius = 100.0; // meters

typedef UpdateActionBuilder =
    Widget Function(BuildContext context, ReportUpdate update);

class ReportDetailScreen extends StatefulWidget {
  final ReportPost post;
  final UpdateActionBuilder? updateActionBuilder;

  const ReportDetailScreen({
    super.key,
    required this.post,
    this.updateActionBuilder,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ReportRepository();

  late final TabController _tabController;
  late final Stream<List<ReportUpdate>> _updatesStream = _repo.watchUpdates(
    widget.post.id,
  );

  // Validation state
  bool _isCheckingProximity = true;
  bool _isWithinRadius = false;
  double? _distanceMeters;
  String? _myValidationType;
  bool _isSubmittingValidation = false;
  StreamSubscription? _validationCountSub;
  int _validationCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkProximityAndValidation();
    _listenValidationCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _validationCountSub?.cancel();
    super.dispose();
  }

  void _listenValidationCount() {
    _validationCountSub = _repo.watchValidationCount(widget.post.id).listen((
      count,
    ) {
      if (mounted) setState(() => _validationCount = count);
    });
  }

  Future<void> _checkProximityAndValidation() async {
    setState(() => _isCheckingProximity = true);
    try {
      // Check stored validation for current user
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _myValidationType = await _repo.getUserValidation(widget.post.id, uid);
      }

      // Check location proximity
      if (widget.post.latitude != null && widget.post.longitude != null) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }

        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 8));

        final dist = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.post.latitude!,
          widget.post.longitude!,
        );
        if (mounted) {
          setState(() {
            _distanceMeters = dist;
            _isWithinRadius = dist <= _kValidationRadius;
          });
        }
      }
    } catch (_) {
      // Permission denied or location unavailable → show disabled state
    } finally {
      if (mounted) setState(() => _isCheckingProximity = false);
    }
  }

  Future<void> _submitValidation(String type) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _isSubmittingValidation) return;

    setState(() => _isSubmittingValidation = true);
    try {
      await _repo.submitValidation(
        reportId: widget.post.id,
        userId: uid,
        type: type,
      );
      if (mounted) {
        setState(() => _myValidationType = type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validasi "$type" berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim validasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingValidation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorScheme = Theme.of(context).colorScheme;
    final isUrgent = post.urgency == 'URGENT';

    final authState = context.watch<AuthBloc>().state;
    final currentUid = authState is AuthAuthenticated
        ? authState.user.uid
        : null;
    final isOwnPost = currentUid != null && currentUid == post.authorId;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Transparent AppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => context.pop(),
            ),
            title: Text(
              post.category,
              style: TextStyle(
                color: isUrgent ? const Color(0xFFD32F2F) : colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? const Color(0xFFD32F2F)
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.urgency,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Gallery ────────────────────────────────────────
                _ImageGallery(post: post),

                // ── Author + Title + Description ─────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colorScheme.surfaceContainer,
                            backgroundImage: post.userAvatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(post.userAvatarUrl)
                                : null,
                            child: post.userAvatarUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${post.timeAgo} · ${post.userBadge}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        post.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        post.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Wilayah chip
                      if (post.wilayah.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.wilayah,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: 16),

                // ── Location Map ─────────────────────────────────────────
                if (post.latitude != null && post.longitude != null)
                  _LocationCard(post: post),

                const SizedBox(height: 16),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: 16),

                // ── Validation Section ───────────────────────────────────
                if (!isOwnPost)
                  _ValidationSection(
                    post: post,
                    isCheckingProximity: _isCheckingProximity,
                    isWithinRadius: _isWithinRadius,
                    distanceMeters: _distanceMeters,
                    myValidationType: _myValidationType,
                    isSubmitting: _isSubmittingValidation,
                    validationCount: _validationCount,
                    onValidate: _submitValidation,
                  ),

                const SizedBox(height: 16),
                Divider(height: 1, color: colorScheme.outlineVariant),

                // ── TabBar: Updates | Replies ─────────────────────────────
                TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: colorScheme.primary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: [
                    const Tab(text: 'Updates'),
                    Tab(text: 'Replies (${post.repliesCount})'),
                  ],
                ),

                // ── Tab Content ───────────────────────────────────────────
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _UpdatesTab(
                        updatesStream: _updatesStream,
                        actionBuilder: widget.updateActionBuilder,
                      ),
                      CommentsSection(post: post),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Image Gallery Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ImageGallery extends StatefulWidget {
  final ReportPost post;
  const _ImageGallery({required this.post});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;
  final PageController _ctrl = PageController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.post.imageUrls ?? [widget.post.imageUrl];
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => urls[i].isNotEmpty
                ? AppNetworkImage(
                    url: urls[i],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: colorScheme.surfaceContainer,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        if (urls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 8 : 5,
                  height: _current == i ? 8 : 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == i
                        ? Colors.white
                        : Colors.white.withAlpha(150),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Card
// ─────────────────────────────────────────────────────────────────────────────

class _LocationCard extends StatefulWidget {
  final ReportPost post;
  const _LocationCard({required this.post});

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lat = widget.post.latitude!;
    final lng = widget.post.longitude!;
    final target = LatLng(lat, lng);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: target, zoom: 16),
                markers: {
                  Marker(markerId: const MarkerId('report'), position: target),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.post.wilayah.isNotEmpty
                          ? widget.post.wilayah
                          : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Open in Google Maps app via URL
                    },
                    child: Text(
                      'BUKA PETA',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Validation Section
// ─────────────────────────────────────────────────────────────────────────────

class _ValidationSection extends StatelessWidget {
  final ReportPost post;
  final bool isCheckingProximity;
  final bool isWithinRadius;
  final double? distanceMeters;
  final String? myValidationType;
  final bool isSubmitting;
  final int validationCount;
  final void Function(String type) onValidate;

  const _ValidationSection({
    required this.post,
    required this.isCheckingProximity,
    required this.isWithinRadius,
    required this.distanceMeters,
    required this.myValidationType,
    required this.isSubmitting,
    required this.validationCount,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Validation Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (!isWithinRadius && !isCheckingProximity)
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$validationCount Validasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Buttons
            if (isCheckingProximity)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  _ValidationButton(
                    label: 'Darurat',
                    icon: Icons.error_outline,
                    color: isWithinRadius
                        ? const Color(0xFFD32F2F)
                        : colorScheme.outlineVariant,
                    isSelected: myValidationType == 'darurat',
                    isEnabled: isWithinRadius && !isSubmitting,
                    onTap: () => onValidate('darurat'),
                  ),
                  const SizedBox(width: 8),
                  _ValidationButton(
                    label: 'Berisiko',
                    icon: Icons.warning_amber_outlined,
                    color: isWithinRadius
                        ? const Color(0xFFE65100)
                        : colorScheme.outlineVariant,
                    isSelected: myValidationType == 'berisiko',
                    isEnabled: isWithinRadius && !isSubmitting,
                    onTap: () => onValidate('berisiko'),
                  ),
                  const SizedBox(width: 8),
                  _ValidationButton(
                    label: 'Mengganggu',
                    icon: Icons.info_outline,
                    color: isWithinRadius
                        ? const Color(0xFFF9A825)
                        : colorScheme.outlineVariant,
                    isSelected: myValidationType == 'mengganggu',
                    isEnabled: isWithinRadius && !isSubmitting,
                    onTap: () => onValidate('mengganggu'),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Proximity status message
            Row(
              children: [
                Icon(
                  isWithinRadius
                      ? Icons.near_me
                      : Icons.near_me_disabled_outlined,
                  size: 13,
                  color: isWithinRadius
                      ? Colors.green.shade600
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isCheckingProximity
                        ? 'Memeriksa lokasi Anda...'
                        : isWithinRadius
                        ? 'Your location is within the ${_kValidationRadius.toInt()}m validation radius.'
                        : distanceMeters != null
                        ? 'You are outside the validation radius (${(distanceMeters! / 1000).toStringAsFixed(1)} km away).'
                        : 'You are outside the validation radius.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isWithinRadius
                          ? Colors.green.shade600
                          : colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
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

class _ValidationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ValidationButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? null : Border.all(color: color.withAlpha(100)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Updates Tab
// ─────────────────────────────────────────────────────────────────────────────

class _UpdatesTab extends StatelessWidget {
  final Stream<List<ReportUpdate>> updatesStream;
  final UpdateActionBuilder? actionBuilder;

  const _UpdatesTab({required this.updatesStream, this.actionBuilder});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<ReportUpdate>>(
      stream: updatesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Gagal memuat update: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          );
        }

        final updates = snapshot.data ?? [];
        if (updates.isEmpty) {
          return Center(
            child: Text(
              'Belum ada update status.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: updates.length,
          itemBuilder: (context, index) {
            final update = updates[index];
            final isLast = index == updates.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator column
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: update.isDone
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            border: Border.all(
                              color: update.isDone
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: 2,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: colorScheme.outlineVariant,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            update.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: update.isDone
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            update.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          if (update.imageUrls != null &&
                              update.imageUrls!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: update.imageUrls!.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppNetworkImage(
                                    url: update.imageUrls![i],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                update.timeFormatted,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (actionBuilder != null) ...[
                                const Spacer(),
                                actionBuilder!(context, update),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
