import 'package:flutter/material.dart';

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
  
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    // get item passed from feed screen
    final item = ModalRoute.of(context)!.settings.arguments as ItemModel;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyPost = currentUser?.uid == item.postedBy;
    final isFound = item.type == 'found';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          // app bar with image
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

                  // status tracker
                  _buildStatusTracker(item.status),

                  const SizedBox(height: 20),

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
                        _buildDetailRow('location', item.location),
                        const Divider(color: Color(0xFF2A2A2A), height: 20),
                        _buildDetailRow('posted', item.timeAgo),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // description
                // description — hidden for found items posted by others
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                        fontSize: 11,
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
              fontWeight:
                  isCurrent ? FontWeight.w500 : FontWeight.normal,
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

  // buttons for the person who posted the item
  Widget _buildMyPostActions(ItemModel item) {
    return Column(
      children: [
        const Text(
          'update item status',
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (item.status == 'found')
              Expanded(
                child: _buildStatusButton(
                  label: 'mark as submitted',
                  color: const Color(0xFF22D3EE),
                  textColor: Colors.black,
                  onTap: () => _updateStatus(item.id, 'submitted'),
                ),
              ),
            if (item.status == 'submitted') ...[
              Expanded(
                child: _buildStatusButton(
                  label: 'mark as claimed',
                  color: const Color(0xFF4ADE80),
                  textColor: Colors.black,
                  onTap: () => _updateStatus(item.id, 'claimed'),
                ),
              ),
            ],
            if (item.status == 'claimed')
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                ),
              ),
          ],
        ),
      ],
    );
  }

  // claim button for other users
  Widget _buildClaimButton(ItemModel item) {
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

    if (item.type == 'lost') {
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
            'contact security office to report finding this item',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : () => _showClaimDialog(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22D3EE),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isUpdating
            ? const CircularProgressIndicator(color: Colors.black)
            : const Text(
                'this is mine — claim it',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

  void _showClaimDialog(ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'claim this item?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'please go to the security office with your student ID to collect this item.',
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
              'yes, claim it',
              style: TextStyle(color: Color(0xFF22D3EE)),
            ),
          ),
        ],
      ),
    );
  }
}