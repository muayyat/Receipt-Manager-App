import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadReceiptImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      print('No image selected.');
      return null; // Exit the function if no image is selected
    }

    print('Image selected: ${image.path}');
    try {
      String fileName = 'receipts/${DateTime.now().millisecondsSinceEpoch}.png';
      Reference ref = _storage.ref().child(fileName);
      await ref.putFile(File(image.path));
      print('Image uploaded successfully.');

      String downloadUrl = await ref.getDownloadURL();
      print('Image URL: $downloadUrl');

      return downloadUrl; // Return the uploaded image URL
    } catch (e) {
      print("Error uploading image: $e");
      return null; // Return null in case of an error
    }
  }
}
