import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageProcessingOptions {
  const ImageProcessingOptions({
    this.maxDimension = 1600,
    this.jpegQuality = 85,
  })  : assert(maxDimension > 0),
        assert(jpegQuality >= 0 && jpegQuality <= 100);

  final int maxDimension;
  final int jpegQuality;

  static const ImageProcessingOptions postDefault =
      ImageProcessingOptions(maxDimension: 1600, jpegQuality: 82);

  static const ImageProcessingOptions whiskeyDefault =
      ImageProcessingOptions(maxDimension: 1600, jpegQuality: 85);

  static const ImageProcessingOptions producerDefault =
      ImageProcessingOptions(maxDimension: 1600, jpegQuality: 85);
}

class PostUploader {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> pickAndUploadImage({
    String destinationFolder = 'posts',
    ImageProcessingOptions? processingOptions,
  }) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final originalFile = File(picked.path);
    final fileForUpload = processingOptions == null
        ? originalFile
        : await _processImage(originalFile, processingOptions) ?? originalFile;

    final id = const Uuid().v4();
    final ref = _storage.ref().child('$destinationFolder/$id.jpg');

    try {
      await ref.putFile(fileForUpload);
      return await ref.getDownloadURL();
    } finally {
      if (fileForUpload.path != originalFile.path) {
        try {
          await fileForUpload.delete();
        } catch (_) {
          // Ignore cleanup issues.
        }
      }
    }
  }

  Future<File?> _processImage(
    File file,
    ImageProcessingOptions options,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = _resizeIfNeeded(decoded, options.maxDimension);
      final quality = options.jpegQuality.clamp(0, 100);
      final jpgBytes = img.encodeJpg(resized, quality: quality);

      final processedFile = File(
        '${file.parent.path}${Platform.pathSeparator}upload_${const Uuid().v4()}.jpg',
      );
      await processedFile.writeAsBytes(jpgBytes, flush: true);
      return processedFile;
    } catch (_) {
      return null;
    }
  }

  img.Image _resizeIfNeeded(img.Image image, int maxDimension) {
    final longestSide = math.max(image.width, image.height);
    if (longestSide <= maxDimension) {
      return image;
    }

    final widthIsLongest = image.width >= image.height;
    final targetWidth = widthIsLongest
        ? maxDimension
        : (image.width * maxDimension / image.height).round();
    final targetHeight = widthIsLongest
        ? (image.height * maxDimension / image.width).round()
        : maxDimension;

    return img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }
}
