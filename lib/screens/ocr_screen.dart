import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      logger.i("Base64 Image String: $base64Image");
      logger.i("Base64 Image Length: ${base64Image.length}"); // Debug log
      return base64Image;
    }
    return null;
  }

  // Function to call the Firebase Cloud Function using HTTP directly
  Future<void> recognizeText(String base64Image) async {
    try {
      logger.i("Sending Base64 Image Data, Length: ${base64Image.length}");

      final url = Uri.parse(
          'https://annotateimagehttp-uh7mqi6ahq-uc.a.run.app'); // Replace with your actual function URL

      final requestData = {
        "image": base64Image, // Update to match what works in Postman
      };

      // Log request data
      logger.i("Request Data: ${jsonEncode(requestData)}");

      // Make the HTTP POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            data['text'] ?? "No text found"; // Adjust to match response format
        setState(() {
          recognizedText = text;
        });
      } else {
        logger.e("HTTP request failed with status: ${response.statusCode}");
        logger.e("Response body: ${response.body}");
        setState(() {
          recognizedText =
              "HTTP request failed with status: ${response.statusCode}";
        });
      }
    } catch (e) {
      logger.e("Error during HTTP request: $e"); // Debug log
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
