import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_post_feed/models/post_model.dart';
import 'package:social_post_feed/screens/feed/comments_screen.dart';
import 'package:social_post_feed/screens/profile/profile_screen.dart';
import 'package:social_post_feed/services/firestore_service.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot postDoc;

  const PostCard({
    Key? key,
    required this.postDoc,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _firestoreService = FirestoreService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  late PostModel post;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    post = PostModel.fromDocument(widget.postDoc);
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postDoc != widget.postDoc) {
      post = PostModel.fromDocument(widget.postDoc);
    }
  }

  Future<void> _toggleLike() async {
    if (_currentUserId == null || _isLiking) return;

    setState(() => _isLiking = true);

    final isLiked = post.isLikedBy(_currentUserId!);
    bool success;

    if (isLiked) {
      success = await _firestoreService.unlikePost(post.id, _currentUserId!);
    } else {
      success = await _firestoreService.likePost(post.id, _currentUserId!);
    }

    setState(() => _isLiking = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${isLiked ? "unlike" : "like"} post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _firestoreService.deletePost(post.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _openComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: post.id),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isOwnPost = post.userId == _currentUserId;
    final isLiked = post.isLikedBy(_currentUserId ?? '');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User info and menu
            Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: post.userId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      post.userName.isNotEmpty
                          ? post.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Name and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(userId: post.userId),
                            ),
                          );
                        },
                        child: Text(
                          post.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu (delete for own posts)
                if (isOwnPost)
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: _deletePost,
                  ),
              ],
            ),
            SizedBox(height: 12),

            // Post content
            Text(
              post.text,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),

            Divider(height: 1),
            SizedBox(height: 8),

            // Actions: Like and Comment
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey[600],
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // Comment button
                InkWell(
                  onTap: _openComments,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Comment',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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