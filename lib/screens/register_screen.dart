import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _studentIdImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickStudentId() async {
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
              'upload student ID',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'take a clear photo of your student ID card',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 13,
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
                        imageQuality: 80,
                      );
                      if (photo != null) {
                        setState(() {
                          _studentIdImage = File(photo.path);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF083344),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF22D3EE),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Color(0xFF22D3EE),
                            size: 32,
                          ),
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
                        imageQuality: 80,
                      );
                      if (photo != null) {
                        setState(() {
                          _studentIdImage = File(photo.path);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: Color(0xFF555555),
                            size: 32,
                          ),
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
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'create account',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'join Back To You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'help your campus community',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'student ID card photo',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickStudentId,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _studentIdImage != null
                          ? const Color(0xFF22D3EE)
                          : const Color(0xFF2A2A2A),
                      width: _studentIdImage != null ? 1.5 : 1,
                    ),
                  ),
                  child: _studentIdImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _studentIdImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card,
                              color: Color(0xFF22D3EE),
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'tap to upload student ID',
                              style: TextStyle(
                                color: Color(0xFF22D3EE),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'take a photo or choose from gallery',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('full name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'Bhanuka Madugalla',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _buildLabel('student ID number'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _studentIdController,
                hint: '10967334',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildLabel('student email'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'you@university.ac.lk',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildLabel('password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF555555),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('confirm password'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF555555),
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'create account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'already have an account? ',
                    style: TextStyle(color: Color(0xFF555555)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'sign in',
                      style: TextStyle(
                        color: Color(0xFF22D3EE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _studentIdController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('please fill in all fields');
      return;
    }

    if (_studentIdImage == null) {
      _showSnackBar('please upload your student ID photo');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();
    String? error = await authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      studentId: _studentIdController.text.trim(),
      password: _passwordController.text,
      studentIdImage: _studentIdImage!,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      _showSnackBar(error);
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/pending');
      }
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