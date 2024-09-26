import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

User? loggedInUser;

class ScanScreen extends StatefulWidget {
  static const String id = 'scan_screen';
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _auth = FirebaseAuth.instance;

  File? _imageFile;
  String _extractedText = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser!;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser?.email);
      }
    } catch (e) {
      print(e);
    }
  }

  // Function to request camera permission and capture a photo
  Future<void> _captureFromCamera() async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        // _performTextRecognition(_imageFile!);
      }
    } else {
      print("Camera permission denied");
    }
  }

  // Function to request gallery permission and pick a photo from the gallery
  Future<void> _pickFromGallery() async {
    PermissionStatus galleryStatus = await Permission.photos.request();

    if (galleryStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        // _performTextRecognition(_imageFile!);
      }
    } else {
      print("Gallery permission denied");
    }
  }

  // Function to perform text recognition on an image
  // Future<void> _performTextRecognition(File image) async {
  //   final InputImage inputImage = InputImage.fromFile(image);
  //   final textRecognizer = TextRecognizer();
  //
  //   try {
  //     final RecognizedText recognizedText =
  //         await textRecognizer.processImage(inputImage);
  //     setState(() {
  //       _extractedText = recognizedText.text;
  //     });
  //   } catch (e) {
  //     print('Error during text recognition: $e');
  //   } finally {
  //     // Dispose of the text recognizer to free up resources
  //     textRecognizer.close();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
              }),
        ],
        title: Text('⚡️Capture Receipt'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _imageFile != null
                ? Image.file(
                    _imageFile!,
                    width: 300,
                    height: 400,
                  )
                : Text("No image selected or captured"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _captureFromCamera,
              child: Text('Capture from Camera'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickFromGallery,
              child: Text('Pick from Gallery'),
            ),
            SizedBox(height: 20),
            _extractedText.isNotEmpty
                ? Text(
                    'Extracted Text:\n$_extractedText',
                    textAlign: TextAlign.center,
                  )
                : Text("No text extracted yet"),
          ],
        ),
      ),
    );
  }
}
