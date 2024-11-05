import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../logger.dart';

class OCRScreen extends StatefulWidget {
  static const String id = 'ocr_screen';

  const OCRScreen({super.key});
  @override
  OCRScreenState createState() => OCRScreenState();
}

class OCRScreenState extends State<OCRScreen> {
  String recognizedText = "No text recognized yet";
  final picker = ImagePicker();

  // Function to pick an image, resize it, and convert it to Base64
  Future<String?> pickAndProcessImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null; // No image selected

    // Load image as bytes
    final File imageFile = File(pickedFile.path);
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    // Resize image
    if (image != null) {
      image = img.copyResize(image, width: 640);

      // Convert to JPEG and then to Base64
      final resizedBytes = img.encodeJpg(image);
      final base64Image = base64Encode(resizedBytes);
      logger.i("Base64 Image Length: ${base64Image.length}"); // Debug log
      return base64Image;
    }
    return null;
  }

  // Function to call the Firebase Cloud Function
  Future<void> recognizeText(String base64Image) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('annotateImage');
      final result = await callable.call({'image': base64Image});
      final data = result.data as Map<String, dynamic>;
      final text = data['text'] ?? "No text found";

      setState(() {
        recognizedText = text; // Update recognizedText here
      });
    } catch (e) {
      logger.e("Error during Cloud Function call: $e"); // Debug log
      setState(() {
        recognizedText = "Error calling Cloud Function: $e";
      });
    }
  }

  // Function to handle the entire process
  Future<void> handleTextRecognition() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Prompt the user to log in
      setState(() {
        recognizedText = "Please log in to use this feature.";
      });
      return;
    }
    // Proceed with image processing and calling the function
    final base64Image = await pickAndProcessImage();
    if (base64Image != null) {
      await recognizeText(base64Image);
    } else {
      setState(() {
        recognizedText = "No image selected";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Text Recognition")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: handleTextRecognition,
              child: Text("Select Image & Recognize Text"),
            ),
            SizedBox(height: 20),
            Text(
              recognizedText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
