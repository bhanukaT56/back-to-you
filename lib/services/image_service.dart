import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // pick and crop student ID — 1.59:1 ratio (landscape)
  Future<File?> pickStudentId(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (photo == null) return null;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: photo.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.59, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'crop student ID',
            toolbarColor: const Color(0xFF0D1F26),
            toolbarWidgetColor: const Color(0xFF22D3EE),
            activeControlsWidgetColor: const Color(0xFF22D3EE),
            backgroundColor: const Color(0xFF0F0F0F),
            cropFrameColor: const Color(0xFF22D3EE),
            lockAspectRatio: true,
          ),
        ],
      );

      if (cropped == null) return null;
      return File(cropped.path);
    } catch (e) {
      return null;
    }
  }

  // pick and crop item photo — 1:1 ratio (square)
  Future<File?> pickItemPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 60,
      );

      if (photo == null) return null;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: photo.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'crop item photo',
            toolbarColor: const Color(0xFF0D1F26),
            toolbarWidgetColor: const Color(0xFF22D3EE),
            activeControlsWidgetColor: const Color(0xFF22D3EE),
            backgroundColor: const Color(0xFF0F0F0F),
            cropFrameColor: const Color(0xFF22D3EE),
            lockAspectRatio: true,
          ),
        ],
      );

      if (cropped == null) return null;
      return File(cropped.path);
    } catch (e) {
      return null;
    }
  }
}