import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _filter = 'all';
  String _dateFilter = 'all time';
  int _currentIndex = 0;
  String _userName = '';
  String? _profilePhoto;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    if (data != null && mounted) {
      setState(() {
        _userName = data['name']?.split(' ')?.first ?? 'there';
        _profilePhoto = data['profilePhotoUrl'];
      });
    }
  }

  List<ItemModel> _applyDateFilter(List<ItemModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    switch (_dateFilter) {
      case 'today':
        return items.where((i) => i.createdAt.isAfter(today)).toList();
      case 'yesterday':
        return items
            .where((i) =>
                i.createdAt.isAfter(yesterday) &&
                i.createdAt.isBefore(today))
            .toList();
      case 'this week':
        return items.where((i) => i.createdAt.isAfter(weekAgo)).toList();
      case 'this month':
        return items.where((i) => i.createdAt.isAfter(monthAgo)).toList();
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            _buildDateFilterTabs(),
            Expanded(
              child: _buildFeed(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/post');
              },
              backgroundColor: const Color(0xFF22D3EE),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text(
                'make a post',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: const Color(0xFF0D1F26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'hey $_userName 👋',
                style: const TextStyle(
                  color: Color(0xFF0891B2),
                  fontSize: 13,
                ),
              ),
              const Text(
                'feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadUserData();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF083344),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF22D3EE),
                  width: 1.5,
                ),
              ),
              child: _profilePhoto != null
                  ? ClipOval(
                      child: Image.network(
                        _profilePhoto!,
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                      ),
                    )
                  : Center(
                      child: Text(
                        _userName.isNotEmpty
                            ? _userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF22D3EE),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      color: const Color(0xFF0F0F0F),
      child: Row(
        children: [
          _filterTab('all', 'all'),
          const SizedBox(width: 8),
          _filterTab('found', 'found'),
          const SizedBox(width: 8),
          _filterTab('lost', 'lost'),
        ],
      ),
    );
  }

  Widget _buildDateFilterTabs() {
    final dateFilters = ['all time', 'today', 'yesterday', 'this week', 'this month'];
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      color: const Color(0xFF0F0F0F),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dateFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = dateFilters[index];
          bool isSelected = _dateFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _dateFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF083344)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF22D3EE)
                      : const Color(0xFF2A2A2A),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF22D3EE)
                      : const Color(0xFF555555),
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterTab(String value, String label) {
    bool isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF22D3EE)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF22D3EE)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF555555),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder<List<ItemModel>>(
      stream: _firestoreService.getItems(filter: 'all'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'something went wrong',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final allItems = snapshot.data ?? [];

        // apply type filter
        var items = _filter == 'all'
            ? allItems
            : allItems.where((i) => i.type == _filter).toList();

        // apply date filter
        items = _applyDateFilter(items);

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'nothing here yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _dateFilter != 'all time'
                      ? 'no posts for $_dateFilter'
                      : 'be the first to make a post!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildItemCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildItemCard(ItemModel item) {
    bool isFound = item.type == 'found';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/item-detail',
          arguments: item,
        );
      },
      child: Container(
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isFound
                          ? const Color(0xFF052E16)
                          : const Color(0xFF450A0A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item.postedByName.isNotEmpty
                            ? item.postedByName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: isFound
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.postedByName} posted',
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
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
            ),

            if (item.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image.network(
                    item.imageUrl,
                    width: double.infinity,
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
              )
            else
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  color: const Color(0xFF0D1F26),
                  child: const Center(
                    child: Text('📦', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),

            // item details
Padding(
  padding: const EdgeInsets.all(12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // item name
      Text(
        item.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      // type and category
      Row(
        children: [
          // type badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
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
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // category badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF083344),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.category,
              style: const TextStyle(
                color: Color(0xFF22D3EE),
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          top: BorderSide(color: Color(0xFF1F1F1F)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.pushNamed(context, '/map');
          if (index == 2) Navigator.pushNamed(context, '/post');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: const Color(0xFF22D3EE),
        unselectedItemColor: const Color(0xFF444444),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'me',
          ),
        ],
      ),
    );
  }
}