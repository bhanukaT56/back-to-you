import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manualLocationController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ImageService _imageService = ImageService();
  final MapController _mapController = MapController();

  String _type = 'found';
  String _category = 'Electronics';
  String _location = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  LatLng _selectedMapLocation = const LatLng(6.9271, 79.8612);
  bool _mapLocationSelected = false;
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
    _manualLocationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('please enable location services');
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('location timed out'),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}';
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _location = address;
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      _showManualLocationDialog();
    }
  }

  void _showManualLocationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'enter location manually',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Library, Block B',
            hintStyle: const TextStyle(color: Color(0xFF444444)),
            filled: true,
            fillColor: const Color(0xFF0F0F0F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF22D3EE)),
            ),
          ),
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
              if (controller.text.isNotEmpty) {
                setState(() {
                  _location = controller.text.trim();
                  _latitude = 6.9271;
                  _longitude = 79.8612;
                });
              }
              Navigator.pop(context);
            },
            child: const Text(
              'set location',
              style: TextStyle(color: Color(0xFF22D3EE)),
            ),
          ),
        ],
      ),
    );
  }

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
                      final File? image = await _imageService
                          .pickItemPhoto(ImageSource.camera);
                      if (image != null) setState(() => _itemImage = image);
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
                          Text('camera',
                              style: TextStyle(
                                  color: Color(0xFF22D3EE),
                                  fontWeight: FontWeight.w500)),
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
                      final File? image = await _imageService
                          .pickItemPhoto(ImageSource.gallery);
                      if (image != null) setState(() => _itemImage = image);
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
                          Text('gallery',
                              style: TextStyle(
                                  color: Color(0xFF555555),
                                  fontWeight: FontWeight.w500)),
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
                    fontWeight: FontWeight.w500),
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
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1.0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
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
                            child: Image.file(_itemImage!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  color: Color(0xFF22D3EE), size: 36),
                              SizedBox(height: 8),
                              Text('tap to add photo',
                                  style: TextStyle(
                                      color: Color(0xFF22D3EE),
                                      fontWeight: FontWeight.w500)),
                              SizedBox(height: 4),
                              Text('camera or gallery',
                                  style: TextStyle(
                                      color: Color(0xFF555555),
                                      fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // item name
              _buildLabel('item name'),
              const SizedBox(height: 4),
              const Text(
                'max 15 characters',
                style: TextStyle(color: Color(0xFF444444), fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                maxLength: 15,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. Blue Laptop').copyWith(
                  counterStyle: const TextStyle(color: Color(0xFF555555)),
                ),
              ),

              const SizedBox(height: 8),

              // description
              _buildLabel('description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration:
                    _inputDecoration('describe the item in detail...'),
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
                          value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // LOCATION SECTION
              _buildLabel('location'),
              const SizedBox(height: 8),

              if (_type == 'found') ...[
                // FOUND ITEM — GPS + manual type
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
                                    strokeWidth: 2),
                              )
                            : Icon(
                                Icons.my_location,
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
                                    : 'tap to get current GPS location',
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
                  'GPS location is mandatory for found items',
                  style: TextStyle(color: Color(0xFF444444), fontSize: 11),
                ),
                const SizedBox(height: 12),

                // manual location note for found item
                _buildLabel('additional location note (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualLocationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                      'e.g. near the library entrance, 2nd floor'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'add extra location details to help identify the spot',
                  style: TextStyle(color: Color(0xFF444444), fontSize: 11),
                ),
              ] else ...[
                // LOST ITEM — map picker + manual type
                const Text(
                  'tap on the map to pin where you last saw it',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 12),
                ),
                const SizedBox(height: 8),

                // map picker
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _mapLocationSelected
                          ? const Color(0xFF22D3EE)
                          : const Color(0xFF2A2A2A),
                      width: _mapLocationSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedMapLocation,
                        initialZoom: 15,
                        onTap: (tapPosition, point) async {
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                                  point.latitude, point.longitude);
                          String address = '';
                          if (placemarks.isNotEmpty) {
                            Placemark place = placemarks.first;
                            address =
                                '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}';
                          }
                          setState(() {
                            _selectedMapLocation = point;
                            _latitude = point.latitude;
                            _longitude = point.longitude;
                            _location = address.isNotEmpty
                                ? address
                                : '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                            _mapLocationSelected = true;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.back_to_you',
                        ),
                        if (_mapLocationSelected)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedMapLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFF87171),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                if (_mapLocationSelected) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF22D3EE), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _location,
                          style: const TextStyle(
                              color: Color(0xFF22D3EE), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // manual type for lost item
                _buildLabel('or type location manually'),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualLocationController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    setState(() {
                      if (val.isNotEmpty && !_mapLocationSelected) {
                        _location = val;
                      }
                    });
                  },
                  decoration: _inputDecoration(
                      'e.g. Library, Block B, 2nd floor'),
                ),
              ],

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
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'post it',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
          fontWeight: FontWeight.w500),
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
        borderSide:
            const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
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

    if (_type == 'found' && _location.isEmpty) {
      _showSnackBar('GPS location is mandatory for found items');
      return;
    }
    if (_type == 'lost' &&
        _location.isEmpty &&
        _manualLocationController.text.isEmpty) {
      _showSnackBar('please pin a location on the map or type it manually');
      return;
    }

    if (_type == 'lost' && _location.isEmpty) {
      setState(() {
        _location = _manualLocationController.text.trim();
        _latitude = 6.9271;
        _longitude = 79.8612;
      });
    }

    setState(() => _isLoading = true);

    try {
      final userData = await _authService.getUserData();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || userData == null) {
        _showSnackBar('please login again');
        setState(() => _isLoading = false);
        return;
      }

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

      final item = ItemModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        type: _type,
        status: _type == 'found' ? 'found' : 'lost',
        location: _location,
        manualLocation: _manualLocationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: '',
        postedBy: user.uid,
        postedByName: userData['name'] ?? 'Anonymous',
        createdAt: DateTime.now(),
      );

      String? error = await _firestoreService.addItem(item, _itemImage!);

      setState(() => _isLoading = false);

      if (error != null) {
        _showSnackBar(error);
      } else {
        if (mounted) {
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