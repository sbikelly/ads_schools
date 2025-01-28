import 'dart:html' as html;

import 'package:flutter/material.dart';

class FileHelper {
  /// Allows the user to select a photo from their device and returns the base64-encoded string.
  static Future<void> selectPhoto(Function(String?) onPhotoSelected) async {
    try {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          if (file.size > 1048487) {
            debugPrint('File size exceeds limit');
            onPhotoSelected(null);
            return;
          }
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            onPhotoSelected(reader.result as String?);
          });
        } else {
          onPhotoSelected(null);
        }
      });
    } catch (e) {
      onPhotoSelected(null);
      throw Exception('error selecting photo $e');
    }
  }

  /// Allows the user to select a file from their device and returns the base64-encoded string.
  static Future<void> selectFile({
    required Function(String? base64, String? fileName) onFileSelected,
    List<String>? acceptedTypes,
    int maxSize = 1048576, // Default max size is 1MB
  }) async {
    try {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = acceptedTypes?.join(',') ?? '*/*';
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          if (file.size > maxSize) {
            debugPrint('File size exceeds limit');
            onFileSelected(null, null);
            return;
          }
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            onFileSelected(reader.result as String?, file.name);
          });
        } else {
          onFileSelected(null, null);
        }
      });
    } catch (e) {
      onFileSelected(null, null);
      throw Exception('Error selecting file: $e');
    }
  }
}
