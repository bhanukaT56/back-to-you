import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  bool _isUpdating = false;
  bool _isPostingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as ItemModel;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyPost = currentUser?.uid == item.postedBy;
    final isFound = item.type == 'found';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width,
            pinned: true,
            backgroundColor: const Color(0xFF0D1F26),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: const Color(0xFF0D1F26),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF22D3EE),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF0D1F26),
                      child: const Center(
                        child: Text('📦', style: TextStyle(fontSize: 64)),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title and badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isFound
                              ? const Color(0xFF052E16)
                              : const Color(0xFF450A0A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFound ? 'found' : 'lost',
                          style: TextStyle(
                            color: isFound
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // status tracker — only for found items
                  if (isFound) _buildStatusTracker(item.status),
                  if (isFound) const SizedBox(height: 20),

                  // details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('posted by', item.postedByName),
                        const Divider(color: Color(0xFF2A2A2A), height: 20),
                        _buildDetailRow('category', item.category),
                        const Divider(color: Color(0xFF2A2A2A), height: 20),

                        // tappable GPS location
                        if (item.latitude != 0 && item.longitude != 0)
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/map',
                                arguments: {
                                  'latitude': item.latitude,
                                  'longitude': item.longitude,
                                  'title': item.title,
                                },
                              );
                            },
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'location',
                                  style: TextStyle(
                                    color: Color(0xFF555555),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.location,
                                          style: const TextStyle(
                                            color: Color(0xFF22D3EE),
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.right,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.map_outlined,
                                        color: Color(0xFF22D3EE),
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _buildDetailRow('location', item.location),

                        // manual location note
                        if (item.manualLocation.isNotEmpty) ...[
                          const Divider(
                              color: Color(0xFF2A2A2A), height: 20),
                          _buildDetailRow(
                              'location note', item.manualLocation),
                        ],

                        const Divider(color: Color(0xFF2A2A2A), height: 20),
                        _buildDetailRow('posted', item.timeAgo),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // description
                  if (item.type == 'lost' || isMyPost)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'description',
                          style: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Color(0xFF555555),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'description is hidden to prevent false claims. visit the security office to identify the item.',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // action buttons
                  if (isMyPost)
                    _buildMyPostActions(item)
                  else
                    _buildClaimButton(item),

                  const SizedBox(height: 32),

                  // comments section
                  _buildCommentsSection(item, currentUser),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(ItemModel item, User? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'comments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // comments list
        StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getComments(item.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF22D3EE),
                  strokeWidth: 2,
                ),
              );
            }

            final comments = snapshot.data?.docs ?? [];

            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: const Text(
                  'no comments yet — be the first!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 13,
                  ),
                ),
              );
            }

            return ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: comments.length,
  itemBuilder: (context, index) {
    final comment =
        comments[index].data() as Map<String, dynamic>;
    final isMyComment =
        comment['postedBy'] == currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(comment['postedBy'])
          .get(),
      builder: (context, userSnapshot) {
        String studentId = '';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData =
              userSnapshot.data!.data() as Map<String, dynamic>;
          studentId = userData['studentId'] ?? '';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMyComment
                ? const Color(0xFF083344)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMyComment
                  ? const Color(0xFF22D3EE)
                  : const Color(0xFF2A2A2A),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // avatar
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isMyComment
                      ? const Color(0xFF22D3EE)
                      : const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (comment['postedByName'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      color: isMyComment
                          ? Colors.black
                          : const Color(0xFFAAAAAA),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isMyComment
                              ? 'you'
                              : comment['postedByName'] ?? 'Unknown',
                          style: TextStyle(
                            color: isMyComment
                                ? const Color(0xFF22D3EE)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (studentId.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF083344),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: $studentId',
                              style: const TextStyle(
                                color: Color(0xFF22D3EE),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _getTimeAgo(comment['createdAt']),
                          style: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['text'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  },
);
          },
        ),

        const SizedBox(height: 12),

        // comment input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: item.type == 'lost'
                      ? 'e.g. I think I found this near the library...'
                      : 'add a comment...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF22D3EE),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isPostingComment
                  ? null
                  : () => _postComment(item.id, currentUser),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF22D3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isPostingComment
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.black,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _postComment(String itemId, User? currentUser) async {
    if (_commentController.text.trim().isEmpty) return;
    if (currentUser == null) return;

    setState(() => _isPostingComment = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = doc.data();
      String userName = userData?['name'] ?? 'Anonymous';

      String? error = await _firestoreService.addComment(
        itemId: itemId,
        text: _commentController.text.trim(),
        postedBy: currentUser.uid,
        postedByName: userName,
      );

      setState(() => _isPostingComment = false);

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xFF1A1A1A),
            ),
          );
        }
      } else {
        _commentController.clear();
      }
    } catch (e) {
      setState(() => _isPostingComment = false);
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

  Widget _buildStatusTracker(String status) {
    final steps = ['found', 'submitted', 'claimed'];
    final currentStep = steps.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'item journey',
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStep('found', 0, currentStep),
              _buildLine(0, currentStep),
              _buildStep('submitted', 1, currentStep),
              _buildLine(1, currentStep),
              _buildStep('claimed', 2, currentStep),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, int step, int currentStep) {
    bool isCompleted = step <= currentStep;
    bool isCurrent = step == currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF22D3EE)
                  : const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF22D3EE)
                    : const Color(0xFF333333),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : Text(
                      '${step + 1}',
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 11,|
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isCompleted
                  ? const Color(0xFF22D3EE)
                  : const Color(0xFF444444),
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLine(int step, int currentStep) {
    bool isCompleted = step < currentStep;
    return Container(
      height: 2,
      width: 40,
      color: isCompleted
          ? const Color(0xFF22D3EE)
          : const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMyPostActions(ItemModel item) {
    bool isFound = item.type == 'found';

    if (!isFound) {
      if (item.status == 'claimed') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF052E16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              '✓ you got your item back!',
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed:
              _isUpdating ? null : () => _showGotItemBackDialog(item),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ADE80),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isUpdating
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text(
                  'i got my item back!',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      );
    }

    if (item.status == 'found') {
      return _buildStatusButton(
        label: 'mark as submitted to security',
        color: const Color(0xFF22D3EE),
        textColor: Colors.black,
        onTap: () => _updateStatus(item.id, 'submitted'),
      );
    }

    if (item.status == 'submitted') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF083344),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF22D3EE)),
        ),
        child: const Center(
          child: Text(
            '⏳ submitted to security — waiting for claim',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF22D3EE),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF052E16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Text(
          '✓ item has been claimed',
          style: TextStyle(
            color: Color(0xFF4ADE80),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildClaimButton(ItemModel item) {
    bool isFound = item.type == 'found';

    if (!isFound) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Center(
          child: Text(
            'if you found this item please submit it to the security office',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (item.status == 'claimed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF052E16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            '✓ this item has been claimed',
            style: TextStyle(
              color: Color(0xFF4ADE80),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (item.status == 'submitted') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Center(
          child: Text(
            'item is at the security office — visit to claim it',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Center(
        child: Text(
          'contact the security office if this is your item',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isUpdating ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _isUpdating
              ? CircularProgressIndicator(color: textColor)
              : Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  void _showGotItemBackDialog(ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'got your item back?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'mark this item as returned so others know it has been recovered!',
          style: TextStyle(color: Color(0xFF888888), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'cancel',
              style: TextStyle(color: Color(0xFF555555)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(item.id, 'claimed');
            },
            child: const Text(
              'yes, i got it back!',
              style: TextStyle(color: Color(0xFF4ADE80)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String itemId, String newStatus) async {
    setState(() => _isUpdating = true);
    String? error =
        await _firestoreService.updateItemStatus(itemId, newStatus);
    setState(() => _isUpdating = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('status updated!'),
            backgroundColor: Color(0xFF052E16),
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}