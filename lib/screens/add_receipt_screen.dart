import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receipt_manager/screens/scan_screen.dart';

import '../components//rounded_button.dart';
import '../components/category_select_popup.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../services/receipt_service.dart';
import '../services/storage_service.dart';

class AddReceiptScreen extends StatefulWidget {
  static const String id = 'add_receipt_screen';

  @override
  _AddReceiptScreenState createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  User? loggedInUser;

  final ReceiptService receiptService = ReceiptService(); // Create an instance
  final StorageService storageService =
      StorageService(); // Create an instance of StorageService

  final TextEditingController merchantController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();

  // Categories and currencies will be loaded from Firestore
  List<String> categories = [];
  String? selectedCategory;

  List<String> currencies = [];
  String? selectedCurrency;

  bool isLoading = true; // To manage loading state

  String? uploadedImageUrl; // Variable to store uploaded image URL

  void initState() {
    super.initState();
    // Set the default date to today
    dateController.text = DateTime.now()
        .toLocal()
        .toString()
        .split(' ')[0]; // Format to YYYY-MM-DD
    getCurrentUser();
    fetchCurrencies();
  }

  Future<void> fetchCurrencies() async {
    try {
      currencies =
          await CurrencyService.fetchCurrencyCodes(); // Fetch currency codes
      setState(() {}); // Update the UI after fetching currencies
    } catch (e) {
      print('Error fetching currencies: $e');
    }
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      dateController.text =
          "${pickedDate.toLocal()}".split(' ')[0]; // Format date
    }
  }

  void _showCategorySelectPopup() async {
    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (context) =>
          CategorySelectPopup(userId: loggedInUser?.email ?? ''),
    );

    if (selectedCategory != null) {
      setState(() {
        this.selectedCategory =
            selectedCategory; // Update the selected category
      });
    }
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Currency'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount:
                    currencies.length + 1, // Include "Add New Currency" option
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(currencies[index]), // Display each currency
                    onTap: () {
                      setState(() {
                        selectedCurrency =
                            currencies[index]; // Update selected currency
                      });
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    trailing: selectedCurrency == currencies[index]
                        ? Icon(Icons.check, color: Colors.green)
                        : null, // Show checkmark for selected currency
                  );
                }),
          ),
        );
      },
    );
  }

  Future<void> uploadReceiptImage() async {
    String? imageUrl = await storageService
        .uploadReceiptImage(); // Use the new service to upload the image

    if (imageUrl != null) {
      setState(() {
        uploadedImageUrl = imageUrl.trim(); // Store the uploaded image URL
      });
    }
  }

  Future<void> _saveReceipt() async {
    if (merchantController.text.isEmpty ||
        totalController.text.isEmpty ||
        selectedCategory == null ||
        selectedCurrency == null) {
      // Handle error: show a message that fields are required
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Create a map with receipt data
    Map<String, dynamic> receiptData = {
      'merchant': merchantController.text,
      'date': Timestamp.fromDate(DateTime.parse(dateController.text)),
      'amount': double.tryParse(totalController.text) ?? 0.0,
      'category': selectedCategory,
      'currency': selectedCurrency,
      'itemName': itemNameController.text,
      'description': descriptionController.text,
      'imageUrl': uploadedImageUrl ?? '', // Use the uploaded image URL
    };

    try {
      await receiptService.addReceipt(receiptData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt saved successfully')),
      );

      // Clear form fields and reset dropdown selections
      setState(() {
        merchantController.clear();
        dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
        totalController.clear();
        descriptionController.clear();
        itemNameController.clear();
        selectedCategory = null;
        selectedCurrency = null;
        uploadedImageUrl = null; // Clear the image URL
      });
    } catch (e) {
      // Handle error: show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save receipt. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Receipt'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoundedButton(
                color: Colors.lightBlueAccent,
                title: 'Scan Receipt',
                onPressed: () {
                  // Add functionality to capture a receipt image
                  Navigator.pushNamed(context, ScanScreen.id);
                },
              ),
              TextField(
                controller: merchantController,
                decoration: InputDecoration(labelText: 'Merchant'),
              ),
              GestureDetector(
                onTap: () => _selectDate(context), // Trigger date picker on tap
                child: AbsorbPointer(
                  child: TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      hintText: 'e.g. Sep 30, 2024',
                    ),
                  ),
                ),
              ),
              // Category and Item Name Side by Side
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap:
                              _showCategorySelectPopup, // Open the popup when tapped
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: selectedCategory?.isNotEmpty == true
                                    ? selectedCategory
                                    : 'Select Category', // Show selected category or hint
                                border: OutlineInputBorder(),
                                hintText: selectedCategory == null
                                    ? 'Select Category'
                                    : null, // Only show hint if no category is selected
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      width: 20), // Space between category and item name input
                  Expanded(
                    child: TextField(
                      controller: itemNameController,
                      decoration: InputDecoration(labelText: 'Item Name'),
                    ),
                  ),
                ],
              ),

              // Currency and Total Input Side by Side
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _showCurrencyDialog(
                              context), // Trigger the dialog
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: selectedCurrency ??
                                    'Select Currency', // Display selected currency or hint
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20), // Space between currency and total input
                  Expanded(
                    child: TextField(
                      controller: totalController,
                      decoration: InputDecoration(
                        labelText: 'Total',
                        hintText: 'e.g. 0.00',
                      ),
                      keyboardType:
                          TextInputType.number, // Show numeric keyboard
                      inputFormatters: [
                        // Only allow digits (0-9) and decimal numbers
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  )
                ],
              ),

              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    uploadReceiptImage(); // Upload the image
                  },
                  child: Text('Upload Receipt Image'),
                ),
              ),
              // Display the uploaded image
              if (uploadedImageUrl != null) ...[
                SizedBox(height: 20),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(8.0), // Set the desired radius
                  child: Image.network(
                    uploadedImageUrl!.trim(),
                    fit: BoxFit.cover, // Adjust the image fit as needed
                  ),
                ),
              ],
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RoundedButton(
                      color: Colors.lightBlueAccent,
                      title: 'Cancel',
                      onPressed: () {
                        Navigator.pop(context); // Navigate back when canceled
                      },
                    ),
                  ),
                  SizedBox(width: 10), // Space between buttons
                  Expanded(
                    child: RoundedButton(
                      color: Colors.blueAccent,
                      title: 'Save',
                      onPressed: () {
                        // Handle saving the receipt
                        _saveReceipt();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
