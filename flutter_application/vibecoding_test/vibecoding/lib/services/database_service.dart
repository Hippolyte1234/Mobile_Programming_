import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream of all posts
  Stream<List<Post>> getPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream of posts for a specific user
  Stream<List<Post>> getUserPosts(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => Post.fromMap(doc.data(), doc.id))
              .toList();
          // Sort locally to avoid needing a composite index in Firestore
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  // Create a new post
  Future<void> createPost(String userId, String text, File imageFile) async {
    try {
      String postId = const Uuid().v4();
      
      // Convert image to base64 string
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Save Post Data to Firestore
      Post newPost = Post(
        id: postId,
        userId: userId,
        text: text,
        imageUrl: base64Image,
        createdAt: DateTime.now(),
      );

      await _db.collection('posts').doc(postId).set(newPost.toMap());
    } catch (e) {
      throw Exception("Error creating post: $e");
    }
  }
}
