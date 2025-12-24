import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_post_feed/screens/feed/create_post_screen.dart';
import 'package:social_post_feed/screens/profile/profile_screen.dart';
import 'package:social_post_feed/services/firestore_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  late TabController _tabController;
  List<String> _followingIds = [];
  bool _isLoadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    if (_currentUserId == null) return;

    final user = await _firestoreService.getUser(_currentUserId!);
    if (user != null) {
      setState(() {
        _followingIds = user.following;
        _isLoadingFollowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Feed'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Public Feed'),
            Tab(text: 'Following'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              if (_currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(userId: _currentUserId!),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Public Feed Tab
          _buildPublicFeed(),

          // Following Feed Tab
          _buildFollowingFeed(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildPublicFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getPublicFeed(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading feed'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Be the first to share something!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return;
             // PostCard(postDoc: posts[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowingFeed() {
    if (_isLoadingFollowing) {
      return Center(child: CircularProgressIndicator());
    }

    // If not following anyone, show message
    if (_followingIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Not following anyone yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Follow users to see their posts here',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0); // Switch to public feed
              },
              icon: Icon(Icons.public),
              label: Text('Explore Public Feed'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getPrivateFeed(_followingIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading feed'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Users you follow haven\'t posted yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            await _loadFollowing();
          },
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return; //PostCard(postDoc: posts[index]);
            },
          ),
        );
      },
    );
  }
}
