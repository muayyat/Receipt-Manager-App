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
  String _language = '';
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
    // Split the text into individual lines
    List<String> lines = text.split('\n');

    // Iterate over each line
    for (String line in lines) {
      // Trim any leading or trailing whitespace from the line
      line = line.trim();

      // Check if the line is not empty after trimming
      if (line.isNotEmpty) {
        // Set the merchant name to the first non-empty line found
        _merchantName = line;
        logger.i(
            'Extracted Merchant Name: $_merchantName'); // Log the extracted merchant name
        break; // Exit the loop after finding the first non-empty line
      }
    }

    // If no non-empty line was found, set a default value and log a warning
    if (_merchantName.isEmpty) {
      logger.w(
          "Merchant name could not be identified."); // Log a warning if no merchant name is found
      _merchantName = "Not Found"; // Set a default value for the merchant name
    }
  }

  String detectLanguage(String text) {
    // Define possible keywords for Finnish and English receipts
    List<String> finnishKeywords = [
      "yhteensä",
      "summa",
      "käteinen",
      "korttiautomaatti",
      "osuuskauppa",
      "kuitti",
      "verollinen"
    ];
    List<String> englishKeywords = [
      "total",
      "amount due",
      "balance",
      "receipt",
      "subtotal",
      "sales tax"
    ];

    // Check if any Finnish keywords are present
    for (var word in finnishKeywords) {
      if (text.toLowerCase().contains(word)) {
        return "Finnish";
      }
    }

    // Check if any English keywords are present
    for (var word in englishKeywords) {
      if (text.toLowerCase().contains(word)) {
        return "English";
      }
    }

    // Return Unknown if no keywords matched
    return "Unknown";
  }

  void _extractTotalAmountAndCurrency(String text) {
    // Detect language using the detectLanguage function
    _language = detectLanguage(text);
    logger.i('Detected receipt language: $_language');

    // Split the text into lines to process each line individually
    List<String> lines = text.split('\n');
    bool foundKeyword =
        false; // Flag to indicate we've found "Total" or similar keyword

    // Define regex pattern for amount extraction, allowing for an optional trailing hyphen
    RegExp amountRegex = RegExp(r'\b(\d+[.,]?\d{2})-?\b');

    // Set keyword based on language
    String totalKeyword;
    String assumedCurrency;

    if (_language == 'Finnish') {
      totalKeyword = 'yhteensä';
      assumedCurrency = 'EUR';
    } else if (_language == 'English') {
      totalKeyword = 'total';
      assumedCurrency =
          'USD'; // Default to USD if currency symbol is not detected
    } else {
      logger.w('Language detection failed or unknown language');
      _totalPrice = "Not Found";
      _currency = "Not Found";
      return;
    }

    // Process each line to find the total amount
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i]
          .toLowerCase(); // Convert to lowercase for case-insensitive matching
      logger.i('Processing line: "$line"');

      // Step 1: Check if the line contains the total keyword
      if (!foundKeyword && line.contains(totalKeyword)) {
        foundKeyword = true;
        logger.i('Found total keyword in line: "$line"');

        // For Finnish receipts, move to the next line to find the amount if available
        if (_language == 'Finnish' && i + 1 < lines.length) {
          line = lines[i + 1];
          logger.i('Checking next line for amount: "$line"');
        }

        // For English receipts, combine with the next line if "Total" spans multiple lines
        if (_language == 'English' && i + 1 < lines.length) {
          String combinedLine = '$line ${lines[i + 1]}';
          if (combinedLine.toLowerCase().contains("subtotal") ||
              combinedLine.toLowerCase().contains("sub total")) {
            foundKeyword = false; // Skip processing if it contains "Subtotal"
            continue;
          }
          line = combinedLine;
          logger.i('Combined line for processing: "$line"');
        }
      }

      // Step 2: Apply regex to find the amount
      if (foundKeyword) {
        Match? match = amountRegex.firstMatch(line);

        if (match != null) {
          // Capture the amount and remove any trailing hyphen if it exists
          _totalPrice = match.group(1) ?? 'Not Found';
          _currency =
              assumedCurrency; // Use assumed currency based on detected language
          logger
              .i('Extracted Total Amount: $_totalPrice, Currency: $_currency');
          return; // Exit once we find the valid total amount
        }

        // Reset the flag if no amount is found after checking the expected line
        foundKeyword = false;
      }
    }

    // If no match is found, log and set defaults
    logger.w('No total price found');
    _totalPrice = "Not Found";
    _currency = "Not Found";
  }

  void _extractDate(String text) {
    // Enhanced regex pattern to capture various date formats: D.M.YYYY, D-M-YYYY, M/d/yyyy, etc.
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
        if (rawDate.contains('.') && rawDate.length >= 8) {
          // Formats: D.M.YYYY, DD.MM.YYYY, D.M.YY, DD.MM.YY
          parsedDate = rawDate.length == 10
              ? DateFormat("d.M.yyyy").parse(rawDate)
              : DateFormat("d.M.yy").parse(rawDate);
        } else if (rawDate.contains('-') && rawDate.length >= 8) {
          // Formats: D-M-YYYY, DD-MM-YYYY, D-M-YY, DD-MM-YY, YYYY-MM-DD
          if (rawDate.split('-')[0].length == 4) {
            parsedDate = DateFormat("yyyy-M-d").parse(rawDate);
          } else {
            parsedDate = rawDate.length == 10
                ? DateFormat("d-M-yyyy").parse(rawDate)
                : DateFormat("d-M-yy").parse(rawDate);
          }
        } else if (rawDate.contains('/') && rawDate.length >= 8) {
          // Formats: M/d/yyyy, MM/dd/yyyy, M/d/yy, MM/dd/yy
          parsedDate = rawDate.length == 10
              ? DateFormat("M/d/yyyy").parse(rawDate)
              : DateFormat("M/d/yy").parse(rawDate);
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
                  // Language
                  Row(
                    children: [
                      Icon(Icons.language, color: Colors.lightBlue),
                      SizedBox(width: 8),
                      Text('Language:', style: infoTextStyle),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _language,
                          style: infoTextStyle.copyWith(
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8), // Add spacing between rows

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
