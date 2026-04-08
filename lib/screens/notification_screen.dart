import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'notifications',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // mark all as read button
          TextButton(
            onPressed: () => _markAllAsRead(currentUser?.uid),
            child: const Text(
              'mark all read',
              style: TextStyle(
                color: Color(0xFF22D3EE),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    'no notifications yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'you\'ll be notified when someone\ncomments on your lost item',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif =
                  notifications[index].data() as Map<String, dynamic>;
              final notifId = notifications[index].id;
              final isRead = notif['isRead'] ?? false;

              return GestureDetector(
                onTap: () {
                  // mark as read
                  _markAsRead(notifId);
                  // navigate to item detail
                  _navigateToItem(context, notif['itemId']);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF083344),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRead
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFF22D3EE),
                      width: isRead ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isRead
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFF22D3EE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.comment_outlined,
                          color: isRead
                              ? const Color(0xFF555555)
                              : Colors.black,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['message'] ?? '',
                              style: TextStyle(
                                color: isRead
                                    ? const Color(0xFFAAAAAA)
                                    : Colors.white,
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getTimeAgo(notif['createdAt']),
                              style: const TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // unread dot
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22D3EE),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAsRead(String notifId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead(String? userId) async {
    if (userId == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _navigateToItem(
    BuildContext context, String? itemId) async {
  if (itemId == null) return;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('items')
        .doc(itemId)
        .get();
    if (!doc.exists) return;
    if (!context.mounted) return;
    final item = ItemModel.fromFirestore(doc);
    Navigator.pushNamed(context, '/item-detail', arguments: item);
  } catch (e) {
    print('Error navigating to item: $e');
  }
}

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'just now';
    try {
      final DateTime date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inSeconds < 60) return 'just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'just now';
    }
  }
}