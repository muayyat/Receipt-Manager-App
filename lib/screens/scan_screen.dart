import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receipt_manager/components/rounded_button.dart';

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

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  String _extractedText = '';

  String _merchantName = '';
  String _receiptDate = '';
  String _currency = '';
  String _totalPrice = '';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

  // Function to pick an image from the gallery, resize it, and convert it to Base64
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

        // Process image: resize and convert to Base64
        final base64Image = await _processImage(_imageFile!);
        if (base64Image != null) {
          await recognizeText(base64Image);
        }
      }
    } else {
      logger.w("Gallery permission denied");
    }
  }

  // Function to capture an image from the camera, resize it, and convert it to Base64
  Future<void> _captureFromCamera() async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        logger.i('Image path: ${pickedFile.path}');

        // Process image: resize and convert to Base64
        final base64Image = await _processImage(_imageFile!);
        if (base64Image != null) {
          await recognizeText(base64Image);
        }
      }
    } else {
      logger.w("Camera permission denied");
    }
  }

  // Function to resize the image and convert it to Base64
  Future<String?> _processImage(File imageFile) async {
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
          _extractedText = text;
          _extractMerchantName(text);
          _extractTotalAmountAndCurrency(text);
          _extractDate(text);
        });
      } else {
        logger.e("HTTP request failed with status: ${response.statusCode}");
        logger.e("Response body: ${response.body}");
        setState(() {
          _extractedText =
              "HTTP request failed with status: ${response.statusCode}";
        });
      }
    } catch (e) {
      logger.e("Error during HTTP request: $e"); // Debug log
      setState(() {
        _extractedText = "Error calling Cloud Function: $e";
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

  void _extractTotalAmountAndCurrency(String text) {
    // Split the text into lines to process each line individually
    List<String> lines = text.split('\n');
    bool foundKeyword =
        false; // Flag to indicate we've found "Total" or similar keyword

    // Regex to match currency and amount in a line or across combined lines
    RegExp totalRegex = RegExp(
      r'\b(Total|TOTAL|Amount Due|BALANCE DUE)\b',
      caseSensitive: false,
    );
    RegExp amountRegex = RegExp(
      r'\b([A-Z]{3}|[€$])?\s*[\$]?\s*(\d+[.,]?\d{2})',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i]; // Keep original case for all operations
      logger.i('Processing line: "$line"');

      // Step 1: Check if the line contains "Total" or similar keywords
      if (!foundKeyword && totalRegex.hasMatch(line)) {
        foundKeyword = true;
        logger.i('Found total keyword in line: "$line"');

        // Check if the next line exists and combine it with the current line
        if (i + 1 < lines.length) {
          String combinedLine = line + ' ' + lines[i + 1];
          if (combinedLine.toLowerCase().contains("subtotal") ||
              combinedLine.toLowerCase().contains("sub total")) {
            logger.i(
                'Skipping combined line as it contains "subtotal": "$combinedLine"');
            foundKeyword = false; // Reset the flag and skip processing
            continue;
          }
          line = combinedLine; // Use the combined line in original case
          logger.i('Combined line for processing: "$line"');
        }
      }

      // Step 2: Apply regex to the current or combined line in original case
      if (foundKeyword) {
        Match? match = amountRegex.firstMatch(line);

        if (match != null) {
          // Capture the currency symbol or code if present
          String detectedCurrency = match.group(1) ?? '';
          // Capture the actual amount
          String amount = match.group(2) ?? '';

          // Standardize the currency to USD or EUR based on the detected symbol or code
          String currency;
          if (detectedCurrency == '\$' || detectedCurrency == 'USD') {
            currency = 'USD';
          } else if (detectedCurrency == '€' || detectedCurrency == 'EUR') {
            currency = 'EUR';
          } else {
            currency = 'Unknown'; // Use 'Unknown' if currency is not recognized
          }

          _totalPrice = amount;
          _currency = currency;
          logger
              .i('Extracted Total Amount: $_totalPrice, Currency: $_currency');
          return; // Exit once we find the valid total amount
        }

        // Reset the flag if no amount is found after the combined line
        foundKeyword = false;
      }
    }

    // If no match is found
    logger.w('No total price found');
    _totalPrice = "Not Found";
    _currency = "Not Found";
  }

  void _extractDate(String text) {
    // Enhanced regex pattern to capture various date formats: DD.MM.YYYY, DD-MM-YYYY, MM/dd/yyyy, etc.
    RegExp dateRegex = RegExp(
      r'(?<!\d)(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})(?!\d)', // Matches multiple formats with separators
      caseSensitive: false,
    );

    Match? dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      String rawDate = dateMatch.group(0)!;

      try {
        DateTime parsedDate;

        // Identify the format based on separators and length
        if (rawDate.contains('.') && rawDate.length == 10) {
          // Format: DD.MM.YYYY
          parsedDate = DateFormat("dd.MM.yyyy").parse(rawDate);
        } else if (rawDate.contains('.') && rawDate.length == 8) {
          // Format: DD.MM.YY
          parsedDate = DateFormat("dd.MM.yy").parse(rawDate);
        } else if (rawDate.contains('-') && rawDate.length == 10) {
          // Format: DD-MM-YYYY or YYYY-MM-DD
          if (rawDate.split('-')[0].length == 4) {
            parsedDate = DateFormat("yyyy-MM-dd").parse(rawDate);
          } else {
            parsedDate = DateFormat("dd-MM-yyyy").parse(rawDate);
          }
        } else if (rawDate.contains('-') && rawDate.length == 8) {
          // Format: DD-MM-YY
          parsedDate = DateFormat("dd-MM-yy").parse(rawDate);
        } else if (rawDate.contains('/') && rawDate.length == 10) {
          // Format: MM/dd/yyyy
          parsedDate = DateFormat("MM/dd/yyyy").parse(rawDate);
        } else if (rawDate.contains('/') && rawDate.length == 8) {
          // Format: MM/dd/yy
          parsedDate = DateFormat("MM/dd/yy").parse(rawDate);
        } else {
          throw FormatException("Unrecognized date format");
        }

        // Standardize the date to 'yyyy-MM-dd' format
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
    final data = {
      'merchant': _merchantName,
      'date': _receiptDate,
      'currency': _currency,
      'amount': _totalPrice,
      'imagePath': _imageFile?.path,
    };
    logger.i('Data to pass back: $data'); // Debug log
    Navigator.pop(context, data);
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
              Container(
                height: 300,
                width: double.infinity, // Full screen width
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: SingleChildScrollView(
                  scrollDirection:
                      Axis.vertical, // Enable vertical scrolling for the image
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit
                        .contain, // Show the entire image without cropping
                  ),
                ),
              )
            else
              Text(""),
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
            Text('Date: $_receiptDate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Currency: $_currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Total Amount: $_totalPrice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text(
              'Full Extracted Text:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 200,
              width: double.infinity, // Makes it take full width available
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _extractedText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 100,
                  child: RoundedButton(
                    color: Colors.red,
                    title: 'Cancel',
                    onPressed: () {
                      Navigator.pop(context); // Close ScanScreen
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
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
