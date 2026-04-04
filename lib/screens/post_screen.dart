import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  String _type = 'found'; // "found" or "lost"
  String _category = 'Electronics';
  String _location = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  File? _itemImage;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  final List<String> _categories = [
    'Electronics',
    'Bags',
    'Clothing',
    'Cards & IDs',
    'Keys',
    'Books',
    'Accessories',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // GPS SENSOR — get current location
 Future<void> _getCurrentLocation() async {
    print('🔍 getting location...');
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        _showSnackBar('please enable location services');
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 permission after request: $permission');
        if (permission == LocationPermission.denied) {
          _showSnackBar('location permission denied');
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('location permission permanently denied');
        setState(() => _isGettingLocation = false);
        return;
      }

      print('📍 getting position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      print('📍 position: ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}';
        print('📍 address: $address');
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _location = address;
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      print('🔴 location error: $e');
      _showSnackBar('could not get location: $e');
      setState(() => _isGettingLocation = false);
    }
  }

  // CAMERA SENSOR — take or pick photo
  Future<void> _pickImage() async {
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
              'add item photo',
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
                      final XFile? photo = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 60,
                      );
                      if (photo != null) {
                        setState(() => _itemImage = File(photo.path));
                      }
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
                      final XFile? photo = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 60,
                      );
                      if (photo != null) {
                        setState(() => _itemImage = File(photo.path));
                      }
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
          'make a post',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // type selector
              const Text(
                'what happened?',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'found'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _type == 'found'
                              ? const Color(0xFF052E16)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _type == 'found'
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF2A2A2A),
                            width: _type == 'found' ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('🎉',
                                style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              'i found it',
                              style: TextStyle(
                                color: _type == 'found'
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'lost'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _type == 'lost'
                              ? const Color(0xFF450A0A)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _type == 'lost'
                                ? const Color(0xFFF87171)
                                : const Color(0xFF2A2A2A),
                            width: _type == 'lost' ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('😭',
                                style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              'i lost it',
                              style: TextStyle(
                                color: _type == 'lost'
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // photo upload
              const Text(
                'item photo',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _itemImage != null
                          ? const Color(0xFF22D3EE)
                          : const Color(0xFF2A2A2A),
                      width: _itemImage != null ? 1.5 : 1,
                    ),
                  ),
                  child: _itemImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _itemImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                color: Color(0xFF22D3EE), size: 36),
                            SizedBox(height: 8),
                            Text(
                              'tap to add photo',
                              style: TextStyle(
                                color: Color(0xFF22D3EE),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'camera or gallery',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // item name
              _buildLabel('item name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g. Blue Nike Backpack',
              ),

              const SizedBox(height: 16),

              // description
              _buildLabel('description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  'describe the item in detail...',
                ),
              ),

              const SizedBox(height: 16),

              // category
              _buildLabel('category'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // location
              _buildLabel('location'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _getCurrentLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _location.isNotEmpty
                          ? const Color(0xFF22D3EE)
                          : const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: Row(
                    children: [
                      _isGettingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Color(0xFF22D3EE),
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.location_on,
                              color: _location.isNotEmpty
                                  ? const Color(0xFF22D3EE)
                                  : const Color(0xFF555555),
                              size: 20,
                            ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isGettingLocation
                              ? 'getting your location...'
                              : _location.isNotEmpty
                                  ? _location
                                  : 'tap to get current location',
                          style: TextStyle(
                            color: _location.isNotEmpty
                                ? Colors.white
                                : const Color(0xFF555555),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'uses your GPS sensor to tag the exact location',
                style: TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 32),

              // submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'post it',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF444444)),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF22D3EE),
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _handlePost() async {
    if (_titleController.text.isEmpty) {
      _showSnackBar('please enter item name');
      return;
    }
    if (_descriptionController.text.isEmpty) {
      _showSnackBar('please enter a description');
      return;
    }
    if (_itemImage == null) {
      _showSnackBar('please add a photo of the item');
      return;
    }
    if (_location.isEmpty) {
      _showSnackBar('please get your current location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // get user data
      final userData = await _authService.getUserData();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || userData == null) {
        _showSnackBar('please login again');
        setState(() => _isLoading = false);
        return;
      }

      // convert image to base64
    // compress image before saving
final compressedBytes = await FlutterImageCompress.compressWithFile(
  _itemImage!.path,
  quality: 30,
  minWidth: 600,
  minHeight: 600,
);

if (compressedBytes == null) {
  _showSnackBar('could not process image');
  setState(() => _isLoading = false);
  return;
}

print('📸 compressed size: ${compressedBytes.length} bytes');
String base64Image = base64Encode(compressedBytes);
print('📸 base64 size: ${base64Image.length} chars');



      // create item model
      final item = ItemModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        type: _type,
        status: _type == 'found' ? 'found' : 'lost',
        location: _location,
        latitude: _latitude,
        longitude: _longitude,
        imageBase64: base64Image,
        postedBy: user.uid,
        postedByName: userData['name'] ?? 'Anonymous',
        createdAt: DateTime.now(),
      );

      // save to Firestore
      String? error = await _firestoreService.addItem(item);

      setState(() => _isLoading = false);

      if (error != null) {
        _showSnackBar(error);
      } else {
        if (mounted) {
          // success!
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('post uploaded successfully!'),
              backgroundColor: Color(0xFF052E16),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('something went wrong. try again');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
  }
}