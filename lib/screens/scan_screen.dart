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

  final TextStyle infoTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.lightBlue,
  );

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
    List<String> merchantIndicators = ["Korttiautomaatti", "Osuuskauppa", "TAMPERE"];

    for (String line in lines) {
      line = line.trim();

      if (line.isNotEmpty && line.contains(RegExp(r'^[A-Z\s]+$'))) {
        _merchantName = line;
        logger.i('Extracted Merchant Name: $_merchantName');
        break;
      }

      // Check for merchant-related keywords in the lines
      if (merchantIndicators.any((keyword) => line.contains(keyword))) {
        _merchantName = line;
        logger.i('Extracted Merchant Name based on keyword: $_merchantName');
        break;
      }
    }

    if (_merchantName.isEmpty) {
      logger.w("Merchant name could not be identified.");
      _merchantName = "Not Found";
    }
  }




  void _extractTotalAmountAndCurrency(String text) {
    List<String> lines = text.split('\n');
    bool foundKeyword = false;

    RegExp totalKeywordRegex = RegExp(r'\b(Total|TOTAL|Amount Due|BALANCE DUE|YHTEENSÄ|Yhteensä|YHTEENSA|Yhteensa|EUR)\b', caseSensitive: false);
    RegExp amountRegex = RegExp(r'([€$]|[A-Z]{3})?\s*([\d,]+[.,]\d{2})', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      logger.i('Processing line: "$line"');

      if (!foundKeyword && totalKeywordRegex.hasMatch(line)) {
        foundKeyword = true;
        if (i + 1 < lines.length) {
          line += ' ' + lines[i + 1];
        }
      }

      if (foundKeyword) {
        Match? match = amountRegex.firstMatch(line);
        if (match != null) {
          String detectedCurrency = match.group(1) ?? 'EUR';
          String amount = match.group(2) ?? '';

          _currency = detectedCurrency.contains('€') ? 'EUR' : 'Unknown';
          _totalPrice = amount;
          logger.i('Extracted Total Amount: $_totalPrice, Currency: $_currency');
          return;
        }

        foundKeyword = false;
      }
    }

    if (_totalPrice.isEmpty) {
      logger.w("Total amount could not be identified.");
      _totalPrice = "Not Found";
      _currency = "Not Found";
    }
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
            // Check if an image is selected
            if (_imageFile == null) ...[
              // Center the capture and pick buttons when no image is selected
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundedButton(
                      color: Colors.lightBlueAccent,
                      title: 'Capture from Camera',
                      onPressed: _captureFromCamera,
                    ),
                    SizedBox(height: 10), // Space between buttons
                    RoundedButton(
                      color: Colors.lightBlue,
                      title: 'Pick from Gallery',
                      onPressed: _pickFromGallery,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Display the image preview and extracted data when an image is selected
              Container(
                height: 200,
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
              ),
              SizedBox(height: 20),
              Container(
                height: 200,
                width: double.infinity, // Makes it take full width available
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _extractedText,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign
                        .start, // Align text to the start (left) by default
                  ),
                ),
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant
                  Row(
                    children: [
                      Icon(Icons.store, color: Colors.lightBlue),
                      SizedBox(width: 8),
                      Text('Merchant:', style: infoTextStyle),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _merchantName,
                          style: infoTextStyle.copyWith(
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8), // Add spacing between rows

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.lightBlue),
                      SizedBox(width: 8),
                      Text('Date:', style: infoTextStyle),
                      SizedBox(width: 4),
                      Text(
                        _receiptDate,
                        style: infoTextStyle.copyWith(
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Currency
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.lightBlue),
                      SizedBox(width: 8),
                      Text('Currency:', style: infoTextStyle),
                      SizedBox(width: 4),
                      Text(
                        _currency,
                        style: infoTextStyle.copyWith(
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Total Amount
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.lightBlue),
                      SizedBox(width: 8),
                      Text('Total:', style: infoTextStyle),
                      SizedBox(width: 4),
                      Text(
                        _totalPrice,
                        style: infoTextStyle.copyWith(
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ],
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
                      onPressed:
                          _confirmDataAndNavigate, // Confirm and navigate
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
