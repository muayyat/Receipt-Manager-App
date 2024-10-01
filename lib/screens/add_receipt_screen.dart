import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/scan_screen.dart';

import '../components//rounded_button.dart';
import '../services/auth_service.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class AddReceiptScreen extends StatefulWidget {
  static const String id = 'add_receipt_screen';

  @override
  _AddReceiptScreenState createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
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

  void initState() {
    super.initState();
    // Set the default date to today
    dateController.text = DateTime.now()
        .toLocal()
        .toString()
        .split(' ')[0]; // Format to YYYY-MM-DD
    getCurrentUser();
    fetchCategoriesAndCurrencies();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

// Fetch unique categories and currencies from the receipts collection for the current user only
  Future<void> fetchCategoriesAndCurrencies() async {
    if (loggedInUser == null) return; // Ensure the user is logged in

    try {
      // Query Firestore for receipts for the current user
      QuerySnapshot snapshot = await _firestore
          .collection('receipts')
          .where('userId',
              isEqualTo: loggedInUser?.email) // Filter by current user
          .get();

      Set<String> categorySet = {};
      Set<String> currencySet = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String category = data['category'];
        String currency = data['currency'];

        // Add to sets to ensure uniqueness
        categorySet.add(category);
        currencySet.add(currency);
      }

      setState(() {
        categories = categorySet.toList(); // Convert to list for dropdown
        currencies = currencySet.toList(); // Convert to list for dropdown
        isLoading = false; // Set loading to false once data is fetched
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
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

  void _showNewCategoryDialog() {
    final TextEditingController newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Category'),
          content: TextField(
            controller: newCategoryController,
            decoration: InputDecoration(hintText: "Enter new category"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  categories.add(newCategoryController.text);
                  selectedCategory = newCategoryController
                      .text; // Set newly created category as selected
                });
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showNewCurrencyDialog() {
    final TextEditingController newCurrencyController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Currency'),
          content: TextField(
            controller: newCurrencyController,
            decoration: InputDecoration(hintText: "Enter new currency"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  currencies.add(newCurrencyController.text);
                  selectedCurrency = newCurrencyController
                      .text; // Set newly created currency as selected
                });
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
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
      'date': dateController.text,
      'amount': double.tryParse(totalController.text) ?? 0.0,
      'category': selectedCategory,
      'currency': selectedCurrency,
      'itemName': itemNameController.text,
      'description': descriptionController.text,
      'userId': loggedInUser?.email,
      'imageUrl': '',
    };

    try {
      // Add the document to Firestore
      await _firestore.collection('receipts').add(receiptData);

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
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () {
              Navigator.pop(context); // Navigate back when canceled
            },
          ),
        ],
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
                        Text('Category'), // Label for category
                        DropdownButton<String>(
                          hint: Text('Select Category'),
                          value: selectedCategory,
                          onChanged: (String? newValue) {
                            if (newValue == 'Add New Category') {
                              _showNewCategoryDialog(); // Show dialog to add new category
                            } else {
                              setState(() {
                                selectedCategory =
                                    newValue; // Update selected category
                              });
                            }
                          },
                          items: [...categories, 'Add New Category']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      width: 20), // Space between dropdown and item name input
                  Expanded(
                    child: TextField(
                      controller: itemNameController,
                      decoration: InputDecoration(labelText: 'Item Name'),
                    ),
                  ),
                ],
              ),
              // Currency and Total Input Side by Side
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Currency'), // Label for currency
                        DropdownButton<String>(
                          hint: Text('Select Currency'),
                          value: selectedCurrency,
                          onChanged: (String? newValue) {
                            if (newValue == 'Add New Currency') {
                              _showNewCurrencyDialog(); // Show dialog to add new currency
                            } else {
                              setState(() {
                                selectedCurrency =
                                    newValue; // Update selected currency
                              });
                            }
                          },
                          items: [...currencies, 'Add New Currency']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20), // Space between dropdown and total input
                  Expanded(
                    child: TextField(
                      controller: totalController,
                      decoration: InputDecoration(
                          labelText: 'Total', hintText: 'e.g. €0.00'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              // Description Input
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Add functionality to capture a receipt image
                  Navigator.pushNamed(context, ScanScreen.id);
                },
                child: Text('Add Receipt Image'),
              ),
              SizedBox(height: 20),
              RoundedButton(
                color: Colors.lightBlueAccent,
                title: 'Save',
                onPressed: () {
                  // Handle saving the receipt
                  _saveReceipt();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
