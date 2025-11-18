import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class PostUploader {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> pickAndUploadImage() async {
    // Pick an image from the gallery
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final file = File(picked.path);
    final id = const Uuid().v4();

    // Store at: posts/<uuid>.jpg
    final ref = _storage.ref().child('posts/$id.jpg');

    // Upload file
    await ref.putFile(file);

    // Get public URL
    final url = await ref.getDownloadURL();
    return url;
  }
}
