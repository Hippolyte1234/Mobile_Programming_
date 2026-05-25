import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          height: 250,
          child: Center(child: Icon(Icons.error)),
        ),
      );
    } else {
      try {
        return Image.memory(
          base64Decode(imageUrl),
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            height: 250,
            child: Center(child: Icon(Icons.error)),
          ),
        );
      } catch (e) {
        return const SizedBox(
          height: 250,
          child: Center(child: Icon(Icons.broken_image)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl.isNotEmpty)
            _buildImage(post.imageUrl),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              post.text,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              'User ID: ${post.userId.substring(0, 5)}... • ${post.createdAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12.0, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
