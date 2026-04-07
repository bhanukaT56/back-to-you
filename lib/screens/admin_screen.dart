import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/item_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F26),
        elevation: 0,
        title: const Text(
          'admin dashboard',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF22D3EE),
          labelColor: const Color(0xFF22D3EE),
          unselectedLabelColor: const Color(0xFF555555),
          tabs: const [
            Tab(text: 'pending users'),
            Tab(text: 'submitted items'),
            Tab(text: 'history'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingUsers(),
          _buildSubmittedItems(),
          _buildHistory(),
        ],
      ),
    );
  }

  // TAB 1 — PENDING USERS
  Widget _buildPendingUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('isVerified', isEqualTo: false)
          .where('role', isNotEqualTo: 'admin')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
          );
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✅', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'no pending verifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'all students are verified!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final uid = users[index].id;
            return _buildUserCard(user, uid);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String uid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF083344),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF22D3EE)),
                  ),
                  child: Center(
                    child: Text(
                      (user['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user['email'] ?? '-',
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${user['studentId'] ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xFF22D3EE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A00),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    '⏳ pending',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (user['idPhotoUrl'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'student ID card',
                    style: TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 1.59,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        user['idPhotoUrl'],
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _rejectUser(uid),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF450A0A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFF87171)),
                            ),
                            child: const Center(
                              child: Text(
                                'reject',
                                style: TextStyle(
                                  color: Color(0xFFF87171),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _verifyUser(uid),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22D3EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'verify',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // TAB 2 — SUBMITTED ITEMS
  Widget _buildSubmittedItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('items')
          .where('status', isEqualTo: 'submitted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
          );
        }

        final items = snapshot.data?.docs ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'no submitted items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'items submitted to security will appear here',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = ItemModel.fromFirestore(items[index]);
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(ItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
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
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF083344),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          color: Color(0xFF22D3EE),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF444444),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('users')
                      .doc(item.postedBy)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF22D3EE),
                          strokeWidth: 2,
                        ),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text(
                        'poster details not found',
                        style: TextStyle(color: Color(0xFF555555)),
                      );
                    }

                    final user =
                        snapshot.data!.data() as Map<String, dynamic>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'posted by',
                          style: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF083344),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF22D3EE)),
                              ),
                              child: ClipOval(
                                child: user['profilePhotoUrl'] != null
                                    ? Image.network(
                                        user['profilePhotoUrl'],
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          (user['name'] ?? '?')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFF22D3EE),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user['email'] ?? '-',
                                    style: const TextStyle(
                                      color: Color(0xFF555555),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Student ID: ${user['studentId'] ?? '-'}',
                                    style: const TextStyle(
                                      color: Color(0xFF22D3EE),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (user['idPhotoUrl'] != null) ...[
                          const Text(
                            'student ID card',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AspectRatio(
                            aspectRatio: 1.59,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                user['idPhotoUrl'],
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
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _markAsClaimed(item.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22D3EE),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'mark as claimed',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3 — HISTORY
  Widget _buildHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('items')
          .where('status', isEqualTo: 'claimed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final sortedItems = docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (sortedItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'no claimed items yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'claimed items will appear here',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            return _buildHistoryCard(sortedItems[index]);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(ItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          // item image
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFF0D1F26),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF22D3EE),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF0D1F26),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text('📦', style: TextStyle(fontSize: 24)),
              ),
            ),

          // item details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.location,
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${item.postedByName}',
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF052E16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '✓ claimed',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.timeAgo,
                        style: const TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('user verified successfully!'),
            backgroundColor: Color(0xFF052E16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('failed to verify user'),
            backgroundColor: Color(0xFF1A1A1A),
          ),
        );
      }
    }
  }

  Future<void> _rejectUser(String uid) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'reject user?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'this will delete the user account permanently.',
          style: TextStyle(color: Color(0xFF888888)),
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('users').doc(uid).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('user rejected'),
                      backgroundColor: Color(0xFF450A0A),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('failed to reject user'),
                      backgroundColor: Color(0xFF1A1A1A),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'reject',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsClaimed(String itemId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'mark as claimed?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'confirm that the owner has collected this item from the security office.',
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('items').doc(itemId).update({
                  'status': 'claimed',
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('item marked as claimed!'),
                      backgroundColor: Color(0xFF052E16),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('failed to update status'),
                      backgroundColor: Color(0xFF1A1A1A),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'confirm',
              style: TextStyle(color: Color(0xFF22D3EE)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}