import 'package:flutter/material.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/item_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
  }

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'update profile photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndUploadPhoto(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF083344),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22D3EE)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt,
                              color: Color(0xFF22D3EE), size: 32),
                          SizedBox(height: 8),
                          Text(
                            'camera',
                            style: TextStyle(
                              color: Color(0xFF22D3EE),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndUploadPhoto(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library,
                              color: Color(0xFF555555), size: 32),
                          SizedBox(height: 8),
                          Text(
                            'gallery',
                            style: TextStyle(
                              color: Color(0xFF555555),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (photo == null) return;

      setState(() => _isUploadingPhoto = true);

      String? error = await _authService.updateProfilePhoto(File(photo.path));

      if (error != null) {
        _showSnackBar(error);
      } else {
        await _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('profile photo updated!'),
              backgroundColor: Color(0xFF052E16),
            ),
          );
        }
      }

      setState(() => _isUploadingPhoto = false);
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _showSnackBar('could not update photo');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'my profile',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
            )
          : RefreshIndicator(
              color: const Color(0xFF22D3EE),
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildMyPosts(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    String name = _userData?['name'] ?? 'Unknown';
    String studentId = _userData?['studentId'] ?? '-';
    String email = _userData?['email'] ?? '-';
    bool isVerified = _userData?['isVerified'] ?? false;
    String? profilePhotoUrl = _userData?['profilePhotoUrl'];
    String initials = name.isNotEmpty
        ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF0D1F26),
      child: Column(
        children: [
          // profile photo with edit button
          Stack(
            children: [
              GestureDetector(
                onTap: _updateProfilePhoto,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF083344),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF22D3EE),
                      width: 2,
                    ),
                  ),
                  child: _isUploadingPhoto
    ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF22D3EE),
          strokeWidth: 2,
        ),
      )
    : profilePhotoUrl != null
        ? ClipOval(
            child: Image.network(
              profilePhotoUrl,
              fit: BoxFit.cover,
              width: 90,
              height: 90,
            ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Color(0xFF22D3EE),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                ),
              ),
              // edit icon
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _updateProfilePhoto,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22D3EE),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0D1F26),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // email
          Text(
            email,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          // badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF083344),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF22D3EE)),
                ),
                child: Text(
                  'ID: $studentId',
                  style: const TextStyle(
                    color: Color(0xFF22D3EE),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFF052E16)
                      : const Color(0xFF2A1A00),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  isVerified ? '✓ verified' : '⏳ pending',
                  style: TextStyle(
                    color: isVerified
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // student ID photo — 1.59:1 ratio
         if (_userData?['idPhotoUrl'] != null)
  Column(
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
            _userData!['idPhotoUrl'],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFF1A1A1A),
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
  ),
        ],
      ),
    );
  }

  Widget _buildMyPosts() {
    return StreamBuilder<List<ItemModel>>(
      stream: _firestoreService.getMyItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
          );
        }

        final items = snapshot.data ?? [];

        final foundItems = items.where((i) => i.type == 'found').length;
        final lostItems = items.where((i) => i.type == 'lost').length;
        final claimedItems =
            items.where((i) => i.status == 'claimed').length;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // stats row
              Row(
                children: [
                  _buildStatCard(
                      '${items.length}', 'total', const Color(0xFF22D3EE)),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      '$foundItems', 'found', const Color(0xFF4ADE80)),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      '$lostItems', 'lost', const Color(0xFFF87171)),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      '$claimedItems', 'claimed', const Color(0xFFF59E0B)),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'my posts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text(
                          '📭',
                          style: TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'no posts yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'your posts will appear here',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildMyPostCard(items[index]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPostCard(ItemModel item) {
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            // image — square
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
             child: item.imageUrl.isNotEmpty
    ? Image.network(
        item.imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      )
                  : Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFF0D1F26),
                      child: const Center(
                        child: Text('📦',
                            style: TextStyle(fontSize: 24)),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isFound
                              ? const Color(0xFF052E16)
                              : const Color(0xFF450A0A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isFound ? 'found' : 'lost',
                          style: TextStyle(
                            color: isFound
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                          item.status,
                          style: const TextStyle(
                            color: Color(0xFF22D3EE),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.timeAgo,
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF333333),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'sign out?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'are you sure you want to sign out?',
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
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'sign out',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ],
      ),
    );
  }
}