import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/scan_screen.dart';

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

  // Predefined categories and currencies
  List<String> categories = ['Food', 'Transport', 'Entertainment'];
  String? selectedCategory;

  List<String> currencies = ['EUR', 'USD', 'GBP'];
  String? selectedCurrency;

  void initState() {
    super.initState();
    // Set the default date to today
    dateController.text = DateTime.now()
        .toLocal()
        .toString()
        .split(' ')[0]; // Format to YYYY-MM-DD
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Receipt'),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () {
              Navigator.pop(context); // Navigate back when canceled
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ElevatedButton(
                onPressed: () {
                  // Handle saving the receipt
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
