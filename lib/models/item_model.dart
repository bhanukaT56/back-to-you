import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type; // "found" or "lost"
  final String status; // "found", "submitted", "claimed"
  final String location;
  final double latitude;
  final double longitude;
  final String imageBase64;
  final String postedBy;
  final String postedByName;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.status,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageBase64,
    required this.postedBy,
    required this.postedByName,
    required this.createdAt,
  });

  // convert Firestore document to ItemModel
  // like parsing JSON in React
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? 'lost',
      status: data['status'] ?? 'found',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      imageBase64: data['imageBase64'] ?? '',
      postedBy: data['postedBy'] ?? '',
      postedByName: data['postedByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // convert ItemModel to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'status': status,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageBase64': imageBase64,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // time ago helper — like "2h ago", "just now"
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}