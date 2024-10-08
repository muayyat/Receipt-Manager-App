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

class AddOrUpdateReceiptScreen extends StatefulWidget {
  static const String id = 'add_receipt_screen';
  final Map<String, dynamic>? existingReceipt; // Store existing receipt data
  final String? receiptId; // Store the receipt ID when editing

  AddOrUpdateReceiptScreen({this.existingReceipt, this.receiptId});

  @override
  _AddOrUpdateReceiptScreenState createState() =>
      _AddOrUpdateReceiptScreenState();
}

class _AddOrUpdateReceiptScreenState extends State<AddOrUpdateReceiptScreen> {
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
  String? selectedCategoryId;

  List<String> currencies = [];
  String? selectedCurrency;

  bool isLoading = true; // To manage loading state

  String? uploadedImageUrl; // Variable to store uploaded image URL

  void initState() {
    super.initState();

    if (widget.existingReceipt != null) {
      // Populate the fields with existing receipt data
      merchantController.text = widget.existingReceipt!['merchant'] ?? '';
      dateController.text = (widget.existingReceipt!['date'] as Timestamp)
          .toDate()
          .toLocal()
          .toString()
          .split(' ')[0];
      totalController.text = widget.existingReceipt!['amount'].toString();
      descriptionController.text = widget.existingReceipt!['description'] ?? '';
      itemNameController.text = widget.existingReceipt!['itemName'] ?? '';
      selectedCategoryId = widget.existingReceipt!['categoryId'] ?? null;
      selectedCurrency = widget.existingReceipt!['currency'] ?? null;
      uploadedImageUrl = widget.existingReceipt!['imageUrl'] ?? null;
    } else {
      // Set the default date to today
      dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
    }

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
    final selectedCategoryId = await showDialog<String>(
      context: context,
      builder: (context) =>
          CategorySelectPopup(userId: loggedInUser?.email ?? ''),
    );

    if (selectedCategoryId != null) {
      setState(() {
        this.selectedCategoryId =
            selectedCategoryId; // Update the selected categoryId
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
        selectedCategoryId == null ||
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
      'categoryId':
          selectedCategoryId, // Store the selected categoryId instead of category name
      'currency': selectedCurrency,
      'itemName': itemNameController.text,
      'description': descriptionController.text,
      'imageUrl': uploadedImageUrl ?? '',
    };

    try {
      if (widget.receiptId != null) {
        // If editing, update the existing receipt
        await receiptService.updateReceipt(widget.receiptId!, receiptData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt updated successfully')),
        );
      } else {
        // If adding a new receipt
        await receiptService.addReceipt(receiptData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt saved successfully')),
        );

        // Only clear form fields and reset dropdown selections if a new receipt was added
        setState(() {
          merchantController.clear();
          dateController.text =
              DateTime.now().toLocal().toString().split(' ')[0];
          totalController.clear();
          descriptionController.clear();
          itemNameController.clear();
          selectedCategoryId = null;
          selectedCurrency = null;
          uploadedImageUrl = null;
        });
      }

      // Navigate back to the receipt list screen after saving
      Navigator.pop(context);
    } catch (e) {
      // Handle error: show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save receipt. Try again.')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    // Show a confirmation dialog before deletion
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Receipt'),
          content: Text(
              'Are you sure you want to delete this receipt? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Dismiss the dialog without deletion
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // If the user confirmed, proceed with deletion
      _deleteReceipt();
    }
  }

  Future<void> _deleteReceipt() async {
    if (widget.receiptId != null) {
      try {
        // Call the delete method in ReceiptService
        await receiptService.deleteReceipt(widget.receiptId!);

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt deleted successfully')),
        );

        // Navigate back to the previous screen
        Navigator.pop(context);
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete receipt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.receiptId != null ? 'Edit Receipt' : 'Create New Receipt'),
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
                                labelText: selectedCategoryId?.isNotEmpty ==
                                        true
                                    ? selectedCategoryId
                                    : 'Select Category', // Show selected category or hint
                                border: OutlineInputBorder(),
                                hintText: selectedCategoryId == null
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
                      title: widget.receiptId != null ? 'Update' : 'Save',
                      onPressed: () {
                        _saveReceipt();
                      },
                    ),
                  ),
                ],
              ),
              // Delete button (only show if editing an existing receipt)
              if (widget.receiptId != null)
                Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        color: Colors.redAccent, // Set the delete button color
                        title: 'Delete',
                        onPressed: () {
                          _confirmDelete(); // Call the delete function
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
