import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../feed/presentation/widgets/post_card.dart';
import 'bloc/near_me_bloc.dart';
import 'bloc/near_me_event.dart';
import 'bloc/near_me_state.dart';

class NearMeScreen extends StatelessWidget {
  const NearMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NearMeBloc()..add(LoadNearMe()),
      child: const _NearMeView(),
    );
  }
}

class _NearMeView extends StatelessWidget {
  const _NearMeView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocBuilder<NearMeBloc, NearMeState>(
        builder: (context, state) {
          if (state is NearMeLocationDenied) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 56,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aktifkan akses lokasi untuk melihat laporan di sekitarmu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<NearMeBloc>().add(LoadNearMe()),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is NearMeError) {
            return Center(child: Text(state.message));
          }

          if (state is NearMeLoaded) {
            final posts = state.posts;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(state.userLat, state.userLng),
                        zoom: 13,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('me'),
                          position: LatLng(state.userLat, state.userLng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                        ),
                        ...posts.map(
                          (np) => Marker(
                            markerId: MarkerId(np.post.id),
                            position: LatLng(
                              np.post.latitude!,
                              np.post.longitude!,
                            ),
                            infoWindow: InfoWindow(
                              title: np.post.title,
                              snippet:
                                  '${(np.distanceMeters / 1000).toStringAsFixed(1)} km dari kamu',
                            ),
                          ),
                        ),
                      },
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
                  ),
                ),
                if (posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Belum ada laporan dalam radius 10km dari lokasimu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final nearPost = posts[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.near_me_outlined,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(nearPost.distanceMeters / 1000).toStringAsFixed(1)} km dari kamu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PostCard(
                              post: nearPost.post,
                              onUpvotePressed: () {
                                context.read<NearMeBloc>().add(
                                  ToggleNearMeUpvote(nearPost.post.id),
                                );
                              },
                              onDownvotePressed: () {
                                context.read<NearMeBloc>().add(
                                  ToggleNearMeDownvote(nearPost.post.id),
                                );
                              },
                            ),
                          ],
                        );
                      }, childCount: posts.length),
                    ),
                  ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
