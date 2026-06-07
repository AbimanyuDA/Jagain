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
    return BlocProvider(
      create: (context) => FeedBloc()..add(LoadFeed()),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF0F1E36)),
            onPressed: () {},
          ),
          title: const Text(
            'JAGAIN',
            style: TextStyle(
              color: Color(0xFF0F1E36), // Match mockup bold dark logo style
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF0F1E36)),
              onPressed: () {},
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 1: Feed (Developer B)
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
                    child: ListView.builder(
                      itemCount: posts.length,
                      padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding to avoid FAB overlap
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return PostCard(
                          post: post,
                          onUpvotePressed: () {
                            context.read<FeedBloc>().add(ToggleUpvote(post.id));
                          },
                          onDownvotePressed: () {
                            context.read<FeedBloc>().add(ToggleDownvote(post.id));
                          },
                        );
                      },
                    ),
                  );
                } else if (state is FeedError) {
                  return Center(child: Text(state.message));
                }
                return const Center(child: Text('Memuat Laporan...'));
              },
            ),
            
            // Tab 2: Near Me Placeholder (Developer C)
            const Center(child: Text('Halaman Near Me (Peta Laporan Terdekat)')),
            
            // Tab 3: Stats Placeholder (Developer A / C)
            const Center(child: Text('Halaman Statistik & Grafik Laporan')),
            
            // Tab 4: Profile Screen (Developer A)
            const ProfileScreen(),
          ],
        ),
        
        // Floating Action Button for reporting (Developer C entrypoint)
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/create-report');
          },
          backgroundColor: const Color(0xFF0F1E36), // Match dark blue button in mockup
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),

        // Bottom Navigation Bar
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFE53935), // Match red selected color in mockup
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
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
