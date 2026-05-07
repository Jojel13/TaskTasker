import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSaveImage(String taskId, {bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final dir = await getApplicationSupportDirectory();
      final imagesDir = Directory('${dir.path}/task_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final String fileName = 'img_$taskId.jpg';
      final String targetPath = '${imagesDir.path}/$fileName';

      // Comprime e salva
      final result = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );

      return result != null ? fileName : null;
    } catch (e) {
      debugPrint('Erro ao salvar imagem: $e');
      return null;
    }
  }

  static Future<File?> getImageFile(String fileName) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/task_images/$fileName');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  static Future<void> deleteImage(String fileName) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/task_images/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Erro ao deletar imagem: $e');
    }
  }
}
