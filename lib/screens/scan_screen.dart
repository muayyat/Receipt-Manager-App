import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/auth_service.dart';

final _auth = FirebaseAuth.instance;
User? loggedInUser;

class ScanScreen extends StatefulWidget {
  static const String id = 'scan_screen';
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _imageFile;
  String _extractedText = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    getCurrentUser();

    // Copy tessdata files from app bundle to Documents directory
    copyTessdataToDocuments().then((_) {
      print('Tessdata files copied successfully');
    }).catchError((error) {
      print('Error copying tessdata files: $error');
    });
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

  Future<void> copyTessdataToDocuments() async {
    // Get the path of the app's documents directory
    final directory = await getApplicationDocumentsDirectory();
    final tessdataPath = '${directory.path}/tessdata';

    // Create the tessdata directory if it doesn't exist
    final tessdataDir = Directory(tessdataPath);
    if (!(await tessdataDir.exists())) {
      await tessdataDir.create();
    }

    // Copy the .traineddata files from the app bundle to the documents directory
    final languages = ['eng', 'fin', 'kor']; // List of languages you're using
    for (var language in languages) {
      final traineddataAssetPath = 'assets/tessdata/$language.traineddata';
      final traineddataDestPath = '$tessdataPath/$language.traineddata';

      // Check if the file already exists
      if (!File(traineddataDestPath).existsSync()) {
        // Read from the asset bundle and write to the documents directory
        final data = await rootBundle.load(traineddataAssetPath);
        final bytes = data.buffer.asUint8List();
        await File(traineddataDestPath).writeAsBytes(bytes);
      }
    }
    print('Tessdata files copied to: $tessdataPath');
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
        print('Image path: ${pickedFile.path}');
        if (_imageFile!.existsSync()) {
          print("Image file exists");
        } else {
          print("Image file does not exist");
        }
        _performTextRecognition(_imageFile!);
      }
    } else {
      print("Camera permission denied");
    }
  }

  // Function to request gallery permission and pick a photo from the gallery
  Future<void> _pickFromGallery() async {
    PermissionStatus permissionStatus;

    if (Platform.isIOS) {
      // Request permission for iOS
      permissionStatus = await Permission.photos.request();
    } else {
      // Request permission for Android
      permissionStatus = await Permission.storage.request();
    }

    if (permissionStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        print('Image path: ${pickedFile.path}');
        if (_imageFile!.existsSync()) {
          print("Image file exists");
        } else {
          print("Image file does not exist");
        }
        _performTextRecognition(_imageFile!);
      }
    } else {
      print("Gallery permission denied");
    }
  }

  // Function to perform text recognition on an image using Flutter Tesseract OCR
  Future<void> _performTextRecognition(File image) async {
    setState(() {
      _extractedText = "Processing...";
    });

    try {
      String tessdataPath = '';
      if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        tessdataPath =
        '${directory.path}/tessdata'; // This is the correct path for iOS.
      } else if (Platform.isAndroid) {
        tessdataPath =
        'assets/tessdata'; // This is the correct path for Android.
      }
      print('Using tessdata path: $tessdataPath');

      // Check if tessdata folder exists and list its contents
      Directory tessdataDir = Directory(tessdataPath);
      if (await tessdataDir.exists()) {
        print("tessdata folder exists.");
        tessdataDir.listSync().forEach((file) {
          print("File in tessdata: ${file.path}");
        });
      } else {
        print("tessdata folder does not exist.");
      }

      // Use Tesseract OCR to extract text from the image
      String text = await FlutterTesseractOcr.extractText(image.path,
          language: 'fin+eng',
          args: {
            "tessdata": tessdataPath,
            "preserve_interword_spaces": "1",
          });
      setState(() {
        _extractedText = text;
      });
    } catch (e, stackTrace) {
      print('Error during text recognition: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _extractedText = "Error extracting text: $e";
      });
    }
    print(_extractedText);
  }

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
                _auth.signOut();
                Navigator.pop(context);
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