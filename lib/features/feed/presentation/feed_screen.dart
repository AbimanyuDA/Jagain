import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc/feed_bloc.dart';
import 'bloc/feed_event.dart';
import 'bloc/feed_state.dart';
import 'widgets/post_card.dart';
import '../../profile/presentation/profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _currentIndex = 0;



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => FeedBloc()..add(LoadFeed()),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            BlocBuilder<FeedBloc, FeedState>(
              builder: (context, state) {
                if (state is FeedLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FeedLoaded) {
                  final posts = state.posts;
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<FeedBloc>().add(LoadFeed());
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          floating: true,
                          snap: true,
                          pinned: false,
                          leading: IconButton(
                            icon: Icon(
                              Icons.add,
                              color: colorScheme.onSurface,
                            ),
                            onPressed: () {
                              context.push('/create-report');
                            },
                          ),
                          automaticallyImplyLeading: false,
                          title: Text(
                            'JAGAIN',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 0.5,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(
                                Icons.search_rounded,
                                color: colorScheme.onSurface,
                              ),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 4),
                          ],
                          backgroundColor: colorScheme.surface,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final post = posts[index];
                              return PostCard(
                                post: post,
                                onUpvotePressed: () {
                                  context.read<FeedBloc>().add(
                                    ToggleUpvote(post.id),
                                  );
                                },
                                onDownvotePressed: () {
                                  context.read<FeedBloc>().add(
                                    ToggleDownvote(post.id),
                                  );
                                },
                              );
                            }, childCount: posts.length),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is FeedError) {
                  return Center(child: Text(state.message));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),

            const Center(
              child: Text('Halaman Near Me (Peta Laporan Terdekat)'),
            ),

            const Center(child: Text('Halaman Statistik & Grafik Laporan')),

            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outline, width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.feed_outlined),
                activeIcon: Icon(Icons.feed),
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on),
                label: 'Near Me',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


