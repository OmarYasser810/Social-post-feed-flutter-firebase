import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================
  
  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get user stream (realtime)
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDocument(doc) : null);
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String uid,
    String? name,
    String? bio,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;

      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Search users by name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // ==================== FOLLOW OPERATIONS ====================

  // Follow a user
  Future<bool> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Add to current user's following
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayUnion([targetUserId]),
      });

      // Add to target user's followers
      await _firestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Remove from current user's following
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });

      // Remove from target user's followers
      await _firestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Get followers list
  Future<List<UserModel>> getFollowers(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null || user.followers.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: user.followers)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get following list
  Future<List<UserModel>> getFollowing(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null || user.following.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: user.following)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // ==================== POST OPERATIONS ====================

  // Create a post
  Future<bool> createPost({
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'text': text,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  // Get all posts (public feed)
  Stream<QuerySnapshot> getPublicFeed() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get posts from followed users (private feed)
  Stream<QuerySnapshot> getPrivateFeed(List<String> followingIds) {
    if (followingIds.isEmpty) {
      // Return empty stream if not following anyone
      return Stream.empty();
    }
    
    return _firestore
        .collection('posts')
        .where('userId', whereIn: followingIds)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get user's posts
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Like a post
  Future<bool> likePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  // Unlike a post
  Future<bool> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      
      // Delete all comments for this post
      final comments = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var doc in comments.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // ==================== COMMENT OPERATIONS ====================

  // Add comment
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      await _firestore.collection('comments').add({
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Get comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Delete comment
  Future<bool> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }
}