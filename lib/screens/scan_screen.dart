import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:receipt_manager/components/rounded_button.dart';
import 'package:receipt_manager/screens/add_update_receipt_screen.dart';
import '../logger.dart';
import '../services/auth_service.dart';

class ScanScreen extends StatefulWidget {
  static const String id = 'scan_screen';

  const ScanScreen({super.key});
  @override
  ScanScreenState createState() => ScanScreenState();
}

class ScanScreenState extends State<ScanScreen> {
  User? loggedInUser;
  File? _imageFile;
  String _extractedText = '';
  String _totalPrice = '';
  String _receiptDate = '';
  String _merchantName = ''; // New variable to hold the extracted merchant name
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    copyTessdataToDocuments().then((_) {
      logger.i('Tessdata files copied successfully');
    }).catchError((error) {
      logger.e('Error copying tessdata files: $error');
    });
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

  Future<void> copyTessdataToDocuments() async {
    final directory = await getApplicationDocumentsDirectory();
    final tessdataPath = '${directory.path}/tessdata';
    final tessdataDir = Directory(tessdataPath);

    if (!(await tessdataDir.exists())) {
      await tessdataDir.create();
    }

    final languages = ['eng', 'fin'];
    for (var language in languages) {
      final traineddataAssetPath = 'assets/tessdata/$language.traineddata';
      final traineddataDestPath = '$tessdataPath/$language.traineddata';

      if (!File(traineddataDestPath).existsSync()) {
        final data = await rootBundle.load(traineddataAssetPath);
        final bytes = data.buffer.asUint8List();
        await File(traineddataDestPath).writeAsBytes(bytes);
      }
    }
    logger.i('Tessdata files copied to: $tessdataPath');
  }

  Future<void> _captureFromCamera() async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        logger.i('Image path: ${pickedFile.path}');
        _performTextRecognition(_imageFile!);
      }
    } else {
      logger.w("Camera permission denied");
    }
  }

  Future<void> _pickFromGallery() async {
    PermissionStatus permissionStatus;

    if (Platform.isIOS) {
      permissionStatus = await Permission.photos.request();
    } else {
      permissionStatus = await Permission.storage.request();
    }

    if (permissionStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        logger.i('Image path: ${pickedFile.path}');
        _performTextRecognition(_imageFile!);
      }
    } else {
      logger.w("Gallery permission denied");
    }
  }

  Future<void> _performTextRecognition(File image) async {
    setState(() {
      _extractedText = "Processing...";
      _totalPrice = '';
      _receiptDate = '';
      _merchantName = '';
    });

    try {
      String tessdataPath = '';
      if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        tessdataPath = '${directory.path}/tessdata';
      } else if (Platform.isAndroid) {
        tessdataPath = 'assets/tessdata';
      }
      logger.i('Using tessdata path: $tessdataPath');

      String text = await FlutterTesseractOcr.extractText(image.path,
          language: 'fin+eng',
          args: {
            "tessdata": tessdataPath,
            "preserve_interword_spaces": "1",
          });

      setState(() {
        _extractedText = text;
        _extractMerchantName(text);
        _extractTotalAmount(text);
        _extractDate(text);
      });
    } catch (e, stackTrace) {
      logger.e('Error during text recognition: $e');
      logger.i('Stack trace: $stackTrace');
      setState(() {
        _extractedText = "Error extracting text: $e";
      });
    }
  }

  void _extractMerchantName(String text) {
    List<String> lines = text.split('\n');
    for (String line in lines) {
      if (line.trim().isNotEmpty) {
        _merchantName = line.trim();
        logger.i('Extracted Merchant Name: $_merchantName');
        break;
      }
    }
  }

  void _extractTotalAmount(String text) {
    RegExp totalRegex = RegExp(
      r'(Total|TOTAL|total|Subtotal|SUBTOTAL|Amount Due|BALANCE DUE|Amount|YHTEENSÄ|YHTEENSÄ)\s*[:$]?\s*(\d+[.,]?\d{2})',
      caseSensitive: false,
    );

    Match? totalMatch = totalRegex.firstMatch(text);
    if (totalMatch != null) {
      _totalPrice = totalMatch.group(2) ?? '';
      logger.i('Extracted Total Amount: $_totalPrice');
    } else {
      logger.w('No total price found');
      _totalPrice = "Not Found";
    }
  }

  void _extractDate(String text) {
    RegExp dateRegex = RegExp(
      r'(\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b|\b\d{4}[./-]\d{1,2}[./-]\d{1,2}\b)',
      caseSensitive: false,
    );

    Match? dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      String rawDate = dateMatch.group(0)!;
      try {
        DateTime parsedDate;

        if (rawDate.contains('-')) {
          parsedDate = DateTime.parse(rawDate);
        } else if (rawDate.contains('/')) {
          var parts = rawDate.split('/');
          if (parts[2].length == 2) {
            parts[2] = '20' + parts[2];
          }
          parsedDate = DateTime.parse('${parts[2]}-${parts[0]}-${parts[1]}');
        } else {
          parsedDate = DateFormat("dd.MM.yyyy").parse(rawDate);
        }

        _receiptDate = DateFormat('yyyy-MM-dd').format(parsedDate);
        logger.i('Extracted Date: $_receiptDate');
      } catch (e) {
        logger.e('Failed to parse date: $e');
        _receiptDate = "Parsing Error";
      }
    } else {
      logger.w('No date found');
      _receiptDate = "Not Found";
    }
  }

  void _confirmDataAndNavigate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrUpdateReceiptScreen(
          existingReceipt: {
            'merchant': _merchantName,
            'amount': _totalPrice,
            'date': _receiptDate,
          },
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Receipt'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                width: 300,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Text("No image selected or captured"),
            RoundedButton(
                color: Colors.lightBlueAccent,
                title: 'Capture from Camera',
                onPressed: _captureFromCamera),
            RoundedButton(
                color: Colors.lightBlue,
                title: 'Pick from Gallery',
                onPressed: _pickFromGallery),
            SizedBox(height: 20),
            Text('Merchant Name: $_merchantName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Extracted Total Amount: $_totalPrice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Date: $_receiptDate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Full Extracted Text:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_extractedText),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 100, // Adjust the width to about 50% of the previous size
                  child: RoundedButton(
                    color: Colors.red,
                    title: 'Cancel',
                    onPressed: () {
                      Navigator.pop(context); // Close ScanScreen
                    },
                  ),
                ),
                SizedBox(
                  width: 100, // Adjust the width to about 50% of the previous size
                  child: RoundedButton(
                    color: Colors.green,
                    title: 'OK',
                    onPressed: _confirmDataAndNavigate, // Confirm and navigate
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
