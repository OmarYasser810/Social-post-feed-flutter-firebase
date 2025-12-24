import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_post_feed/models/user_model.dart';
import 'package:social_post_feed/services/auth_service.dart';
import 'package:social_post_feed/services/firestore_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = widget.userId == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await _authService.logout();
                // Navigation handled by StreamBuilder in main.dart
              },
            ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.getUserStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('User not found'));
          }

          final user = snapshot.data!;
          _isFollowing = user.isFollowedBy(_currentUserId ?? '');

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 40, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Name
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),

                      // Email
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Bio
                      if (user.bio.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            user.bio,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      SizedBox(height: 20),

                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Followers', user.followerCount.toString()),
                          _buildStatColumn('Following', user.followingCount.toString()),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Action Button
                      if (isOwnProfile)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(user: user),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit),
                          label: Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _toggleFollow(user),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 45),
                            backgroundColor: _isFollowing ? Colors.grey : Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isFollowing ? 'Unfollow' : 'Follow',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                    ],
                  ),
                ),

                Divider(height: 1),

                // User's Posts
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.article, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getUserPosts(widget.userId),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No posts yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final posts = postSnapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final data = post.data() as Map<String, dynamic>;
                        final likes = List<String>.from(data['likes'] ?? []);
                        final isLiked = likes.contains(_currentUserId);
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Post text
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 12),

                                // Post footer
                                Row(
                                  children: [
                                    Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      size: 20,
                                      color: isLiked ? Colors.red : Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text('${likes.length}'),
                                    SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatTimestamp(createdAt),
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow(UserModel user) async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    bool success;
    if (_isFollowing) {
      success = await _firestoreService.unfollowUser(
        currentUserId: _currentUserId!,
        targetUserId: user.uid,
      );
    } else {
      success = await _firestoreService.followUser(
        currentUserId: _currentUserId!,
        targetUserId: user.uid,
      );
    }

    if (!mounted) return;
    
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isFollowing = !_isFollowing);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${_isFollowing ? "unfollow" : "follow"} user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}