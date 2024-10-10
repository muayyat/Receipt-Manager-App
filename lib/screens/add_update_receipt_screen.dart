import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receipt_manager/screens/scan_screen.dart';

import '../components//rounded_button.dart';
import '../components/add_category_widget.dart';
import '../components/currency_roller_picker.dart';
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/currency_service.dart';
import '../services/receipt_service.dart';
import '../services/storage_service.dart';

class AddOrUpdateReceiptScreen extends StatefulWidget {
  static const String id = 'add_receipt_screen';
  final Map<String, dynamic>? existingReceipt; // Store existing receipt data
  final String? receiptId; // Store the receipt ID when editing

  const AddOrUpdateReceiptScreen(
      {super.key, this.existingReceipt, this.receiptId});

  @override
  AddOrUpdateReceiptScreenState createState() =>
      AddOrUpdateReceiptScreenState();
}

class AddOrUpdateReceiptScreenState extends State<AddOrUpdateReceiptScreen> {
  User? loggedInUser;

  final ReceiptService receiptService = ReceiptService(); // Create an instance
  final StorageService storageService =
      StorageService(); // Create an instance of StorageService
  final CategoryService _categoryService = CategoryService();

  final TextEditingController merchantController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();

  // Categories and currencies will be loaded from Firestore
  List<Map<String, dynamic>> categories = [];

  String? selectedCategoryId;
  String? selectedCategoryIcon; // Store selected category icon
  String? selectedCategoryName; // Store selected category name

  List<String> currencies = [];
  String? selectedCurrency;

  bool isLoading = true; // To manage loading state

  String? uploadedImageUrl; // Variable to store uploaded image URL

  @override
  void initState() {
    super.initState();

    getCurrentUser().then((_) {
      if (widget.existingReceipt != null) {
        // Populate the fields with existing receipt data
        merchantController.text = widget.existingReceipt!['merchant'] ?? '';
        dateController.text = (widget.existingReceipt!['date'] as Timestamp)
            .toDate()
            .toLocal()
            .toString()
            .split(' ')[0];
        totalController.text = widget.existingReceipt!['amount'].toString();
        descriptionController.text =
            widget.existingReceipt!['description'] ?? '';
        itemNameController.text = widget.existingReceipt!['itemName'] ?? '';
        selectedCategoryId = widget.existingReceipt!['categoryId'];

        // Check if selectedCategoryId is not null or empty, and then fetch the category details
        if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
          _fetchCategoryDetails(selectedCategoryId!);
        }

        selectedCurrency = widget.existingReceipt!['currency'];
        uploadedImageUrl = widget.existingReceipt!['imageUrl'];
      } else {
        // Set the default date to today for new receipts
        dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
      }

      fetchCurrencies(); // Fetch the currencies only after user is initialized
      fetchUserCategories();
    });
  }

  Future<void> getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    setState(() {}); // Trigger a rebuild after the user is loaded
  }

  Future<void> fetchUserCategories() async {
    try {
      // Fetch categories from the service
      final fetchedCategories =
          await _categoryService.fetchUserCategories(loggedInUser!.email!);

      setState(() {
        categories =
            fetchedCategories; // Set the fetched categories in the state
      });
    } catch (e) {
      logger.e("Error fetching user categories: $e");
    }
  }

  // Function to fetch category details based on the categoryId
  Future<void> _fetchCategoryDetails(String categoryId) async {
    final categoryData = await _categoryService.fetchCategoryById(
        loggedInUser!.email!, categoryId);

    setState(() {
      selectedCategoryIcon = categoryData?['icon'] ?? ''; // Get category icon
      selectedCategoryName = categoryData?['name'] ?? ''; // Get category name
    });
    logger.e('selectedCategoryName: ${selectedCategoryName!}');
  }

  Future<void> fetchCurrencies() async {
    try {
      currencies =
          await CurrencyService.fetchCurrencyCodes(); // Fetch currency codes
      setState(() {}); // Update the UI after fetching currencies
    } catch (e) {
      logger.e('Error fetching currencies: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        DateTime tempPickedDate =
            initialDate; // Hold the selected date temporarily

        return Container(
          height: 300, // Set an appropriate height for the picker
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              Text(
                'Select Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Rolling Date Picker
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDate,
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2101),
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate; // Update the temporary date
                  },
                ),
              ),
              // Done Button to confirm the selection
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    dateController.text = "${tempPickedDate.toLocal()}"
                        .split(' ')[0]; // Format date
                  });
                  Navigator.pop(context); // Close the bottom sheet
                },
                child: Text('DONE'),
              ),
            ],
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

  // Function to show the AddCategoryWidget dialog
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: AddCategoryWidget(
            userId: loggedInUser!.email!,
            onCategoryAdded: () {
              // Refresh categories when a new category is added
              fetchUserCategories();
            },
          ),
        );
      },
    );
  }

  Future<void> _showCategoryBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // To make the height flexible
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 400, // Set a height for the list view
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    String categoryId = categories[index]['id'] ?? '';
                    String categoryName = categories[index]['name'] ?? '';
                    String categoryIcon = categories[index]['icon'] ?? '';

                    bool isSelected = categoryId == selectedCategoryId;

                    return Container(
                      color: isSelected
                          ? Colors.lightBlue.withOpacity(0.2)
                          : null, // Highlight selected row
                      child: ListTile(
                        leading:
                            Text(categoryIcon, style: TextStyle(fontSize: 24)),
                        title: Text(
                          categoryName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context,
                              categoryId); // Return the selected categoryId
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed:
                    // Handle add category action
                    _showAddCategoryDialog,
                child: Text('Add Category'),
              ),
            ],
          ),
        );
      },
    );

// Handle the result from the bottom sheet (selected categoryId)
    if (result != null) {
      setState(() {
        selectedCategoryId = result; // Update the selected category ID
      });

      // Fetch category details after updating the selectedCategoryId
      _fetchCategoryDetails(selectedCategoryId!);
    }
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CurrencyPicker(
          availableCurrencies: currencies,
          selectedCurrency:
              selectedCurrency ?? currencies.first, // Provide a default,
          onCurrencySelected: (String newCurrency) {
            setState(() {
              selectedCurrency = newCurrency;
            });
          },
        );
      },
    );
  }

  Future<void> _saveReceipt() async {
    // Capture the ScaffoldMessenger before async operations
    final messenger = ScaffoldMessenger.of(context);

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
        messenger.showSnackBar(
          SnackBar(content: Text('Receipt updated successfully')),
        );
      } else {
        // If adding a new receipt
        await receiptService.addReceipt(receiptData);
        messenger.showSnackBar(
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
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle error: show an error message
      messenger.showSnackBar(
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
    // Capture the ScaffoldMessenger before async operations
    final messenger = ScaffoldMessenger.of(context);

    if (widget.receiptId != null) {
      try {
        // Call the delete method in ReceiptService
        await receiptService.deleteReceipt(widget.receiptId!);

        if (mounted) {
          // Show a success message
          messenger.showSnackBar(
            SnackBar(content: Text('Receipt deleted successfully')),
          );

          // Navigate back to the previous screen
          Navigator.pop(context);
        }
      } catch (e) {
        // Handle any errors
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete receipt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.receiptId != null ? 'Update Receipt' : 'New Receipt'),
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
                          onTap: () {
                            _showCategoryBottomSheet(
                                context); // Call the bottom sheet here
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: selectedCategoryId?.isNotEmpty ==
                                        true
                                    ? '$selectedCategoryIcon $selectedCategoryName' // Display icon and name together
                                    : 'Select Category', // Show hint if no category is selected
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
                          onTap: () {
                            _showCurrencyPicker(
                                context); // Show the picker when button is pressed
                          },
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
