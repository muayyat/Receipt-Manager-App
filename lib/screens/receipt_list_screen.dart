import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/custom_drawer.dart';
import '../components/date_range_container.dart';
import '../components/date_roller_picker.dart'; // Import the CalendarFilterWidget
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart'; // Import CategoryService
import '../services/currency_service.dart';
import '../services/receipt_service.dart';
import 'add_update_receipt_screen.dart';
import 'expense_chart_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  static const String id = 'receipt_list_screen';

  const ReceiptListScreen({super.key});

  @override
  ReceiptListScreenState createState() => ReceiptListScreenState();
}

class ReceiptListScreenState extends State<ReceiptListScreen> {
  User? loggedInUser;

  final ReceiptService receiptService = ReceiptService();
  final CategoryService categoryService =
      CategoryService(); // Add CategoryService
  CurrencyService currencyService = CurrencyService();

  Stream<DocumentSnapshot>? receiptsStream;
  List<Map<String, dynamic>> sortedReceiptList = [];
  List<Map<String, dynamic>> userCategories = [];

  // Set default dates
  DateTime? _startDate =
      DateTime(DateTime.now().year, 1, 1); // Start date: first day of the year
  DateTime? _endDate = DateTime.now(); // End date: today

  String currentSortField = 'date';
  bool isDescending = false;

  // Filtering
  List<String> selectedCategoryIds = []; // Store selected category IDs
  bool includeUncategorized = true;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    logger.i('Logged in user: $loggedInUser'); // Log user details for debugging
    setState(() {
      if (loggedInUser != null) {
        receiptsStream = receiptService.fetchReceipts();
        // Fetch user categories directly from the service
        categoryService
            .fetchUserCategories(loggedInUser!.email!)
            .then((categories) {
          userCategories = categories; // Directly assign the fetched categories

          // Initialize selectedCategoryIds with all category IDs and include null for "Uncategorized"
          selectedCategoryIds = userCategories
              .map((category) => category['id'] as String)
              .toList();

          setState(() {}); // Trigger rebuild with new categories
        });
      } else {
        // You can handle the case where the user is not logged in if needed.
        logger.w('No user is logged in.');
      }
    });
  }

  Future<void> _showCalendarFilterDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return CalendarFilterWidget(
          initialStartDate: _startDate!,
          initialEndDate: _endDate!,
          onApply: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
        );
      },
    );
  }

  // TODO: modify the dialog to a modern one
  Future<void> _showCategoryFilterDialog() async {
    List<String> tempSelectedCategoryIds = List.from(selectedCategoryIds);
    bool isUncategorizedSelected = includeUncategorized;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Filter by Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      // Add the "Uncategorized" option
                      CheckboxListTile(
                        title: Text('Uncategorized'),
                        value: isUncategorizedSelected,
                        onChanged: (bool? isChecked) {
                          setState(() {
                            isUncategorizedSelected = isChecked ?? false;
                            if (isUncategorizedSelected) {
                              includeUncategorized = true;
                            } else {
                              includeUncategorized = false;
                            }
                          });
                        },
                      ),
                      // Add the rest of the user-defined categories
                      ...userCategories.map((category) {
                        return CheckboxListTile(
                          title: Text(category['name']),
                          value:
                              tempSelectedCategoryIds.contains(category['id']),
                          onChanged: (bool? isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                tempSelectedCategoryIds.add(category['id']);
                              } else {
                                tempSelectedCategoryIds.remove(category['id']);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Call the new onFilterChanged method with the selected categories and the uncategorized flag
                    onFilterChanged(tempSelectedCategoryIds,
                        isUncategorizedSelected, sortedReceiptList);
                    Navigator.of(context).pop(); // Close the bottom sheet
                  },
                  child: Text('APPLY', style: TextStyle(fontSize: 20)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void onFilterChanged(
      List<String> newSelectedCategoryIds,
      bool isUncategorizedSelected,
      List<Map<String, dynamic>> initialReceiptList) {
    setState(() {
      selectedCategoryIds = newSelectedCategoryIds;
      includeUncategorized = isUncategorizedSelected;

      // Reapply the filtering logic based on the updated selectedCategoryIds and `includeUncategorized`
      _applyFilters(initialReceiptList);
    });
  }

  void _applyFilters(List<Map<String, dynamic>> initialReceiptList) {
    List<Map<String, dynamic>> filteredList = List.from(initialReceiptList);

    // Filter by selected categories and include "Uncategorized" if selected
    if (selectedCategoryIds.isNotEmpty || includeUncategorized) {
      filteredList = filteredList.where((receipt) {
        // Include receipts that match selected categories or have a null categoryId if "Uncategorized" is selected
        if (includeUncategorized && receipt['categoryId'] == null) {
          return true;
        }
        // Check if the receipt matches any of the selected category IDs
        return selectedCategoryIds.contains(receipt['categoryId']);
      }).toList();
    }

    // Filter by date range
    if (_startDate != null && _endDate != null) {
      filteredList = filteredList.where((receipt) {
        final receiptDate = (receipt['date'] as Timestamp).toDate();
        return receiptDate.isAfter(_startDate!) &&
            receiptDate.isBefore(_endDate!);
      }).toList();
    }

    // Update the sortedReceiptList only if it differs from the current list
    if (sortedReceiptList != filteredList) {
      setState(() {
        sortedReceiptList = filteredList;
      });
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int selectedSortOption = 0; // Index for the selected option
        final List<String> sortOptions = [
          'Date: Oldest First',
          'Date: Newest First',
          'Amount: Lowest First',
          'Amount: Highest First',
          'Category: A-Z',
          'Category: Z-A'
        ];

        return SizedBox(
          height: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Sort Options',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36.0, // Height of each item
                  onSelectedItemChanged: (int index) {
                    selectedSortOption = index; // Update the selected option
                  },
                  children: sortOptions.map((String option) {
                    return Center(child: Text(option));
                  }).toList(),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Handle the sorting logic based on selectedSortOption
                  switch (selectedSortOption) {
                    case 0:
                      onSortChanged('date', false); // Date: Oldest First
                      break;
                    case 1:
                      onSortChanged('date', true); // Date: Newest First
                      break;
                    case 2:
                      onSortChanged('amount', false); // Amount: Lowest First
                      break;
                    case 3:
                      onSortChanged('amount', true); // Amount: Highest First
                      break;
                    case 4:
                      onSortChanged('category', false); // Category: A-Z
                      break;
                    case 5:
                      onSortChanged('category', true); // Category: Z-A
                      break;
                  }
                  Navigator.of(context).pop(); // Close the bottom sheet
                },
                child: Text('DONE', style: TextStyle(fontSize: 20)),
              )
            ],
          ),
        );
      },
    );
  }

  void onSortChanged(String newSortField, bool descending) {
    setState(() {
      currentSortField = newSortField;
      isDescending = descending;
    });
    _sortReceiptList();
  }

  Future<void> _sortReceiptList() async {
    // If sorting by amount, start with the original amounts and update asynchronously
    if (currentSortField == 'amount') {
      // Display initial list while processing the conversions
      setState(() {
        // Sort the list by original amounts while the conversion happens
        sortedReceiptList.sort((a, b) {
          var aValue = (a['amount'] as num).toDouble();
          var bValue = (b['amount'] as num).toDouble();
          return isDescending
              ? bValue.compareTo(aValue)
              : aValue.compareTo(bValue);
        });
      });

      // Process currency conversion asynchronously
      for (var receipt in sortedReceiptList) {
        double amount = (receipt['amount'] as num).toDouble();
        double convertedAmount = await currencyService.convertToBaseCurrency(
          amount,
          receipt['currency'],
          'USD',
        );
        receipt['convertedAmount'] = convertedAmount;
      }

      // Update the list after all conversions are done
      setState(() {
        sortedReceiptList.sort((a, b) {
          var aValue = a['convertedAmount'];
          var bValue = b['convertedAmount'];
          return isDescending
              ? bValue.compareTo(aValue)
              : aValue.compareTo(bValue);
        });
      });
    } else if (currentSortField == 'category') {
      // Create a map to store category names for quick access
      Map<String, String?> categoryNamesMap = {};

// Populate the map with category names from userCategories
      for (var category in userCategories) {
        categoryNamesMap[category['id']] = category['name'];
      }

// Sort the list based on fetched category names
      setState(() {
        sortedReceiptList.sort((a, b) {
          var aCategory = categoryNamesMap[a['categoryId']] ?? 'Uncategorized';
          var bCategory = categoryNamesMap[b['categoryId']] ?? 'Uncategorized';
          return isDescending
              ? bCategory.compareTo(aCategory)
              : aCategory.compareTo(bCategory);
        });
      });
    } else {
      // Sort by date immediately
      setState(() {
        sortedReceiptList.sort((a, b) {
          var aValue = (a['date'] as Timestamp).toDate();
          var bValue = (b['date'] as Timestamp).toDate();
          return isDescending
              ? bValue.compareTo(aValue)
              : aValue.compareTo(bValue);
        });
      });
    }
  }

  Center _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildImageSection(String imageUrl) {
    return Container(
      height: 60,
      width: 60,
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Text('Image failed to load');
                },
              ),
            )
          : Container(),
    );
  }

  Widget _buildTextDetails(
      String itemName, String merchant, String date, String categoryName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(itemName, style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Merchant: $merchant'),
        Text('Date: $date'),
        Text('Category: $categoryName'), // Display the fetched category name
      ],
    );
  }

  Widget _buildAmountSection(String currency, double amount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$currency $amount'),
      ],
    );
  }

  Widget _buildReceiptCardContent(
      String imageUrl,
      String itemName,
      String merchant,
      String date,
      String categoryName,
      String currency,
      double amount) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            _buildImageSection(imageUrl),
            Expanded(
              child: _buildTextDetails(itemName, merchant, date, categoryName),
            ),
            _buildAmountSection(currency, amount),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildReceiptCard(Map<String, dynamic> receiptData) {
    Timestamp timestamp = receiptData['date'] ?? Timestamp.now();
    DateTime dateTime = timestamp.toDate();
    String date = DateFormat('yyyy-MM-dd').format(dateTime);
    String itemName = receiptData['itemName'] ?? '';
    String merchant = receiptData['merchant'] ?? '';
    String? categoryId = receiptData['categoryId']; // Nullable categoryId
    double amount = (receiptData['amount'] is int)
        ? (receiptData['amount'] as int).toDouble()
        : (receiptData['amount'] as double);
    String currency = receiptData['currency'] ?? '';
    String imageUrl = receiptData['imageUrl'] ?? '';
    String receiptId = receiptData['id'] ?? ''; // Get receipt ID from data

    // Find the category in the userCategories list
    var category = userCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () =>
          {'name': 'Uncategorized', 'icon': ''}, // Fallback if not found
    );

    return GestureDetector(
      onTap: () {
        // Navigate to AddReceiptScreen and pass receipt data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddOrUpdateReceiptScreen(
              existingReceipt: receiptData, // Pass the receipt data
              receiptId: receiptId, // Pass the receipt ID
            ),
          ),
        );
      },
      child: _buildReceiptCardContent(
        imageUrl,
        itemName,
        merchant,
        date,
        category['name'], // Use the fetched category name directly
        currency,
        amount,
      ),
    );
  }

  StreamBuilder<DocumentSnapshot> _buildReceiptList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: receiptsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.data() == null) {
          return Center(child: Text('No receipts found.'));
        }

        final receiptList =
            snapshot.data!.get('receiptlist') as List<dynamic>? ?? [];
        sortedReceiptList = receiptList.cast<Map<String, dynamic>>();

        // Filter by selected categories and include "Uncategorized" if selected
        if (selectedCategoryIds.isNotEmpty || includeUncategorized) {
          sortedReceiptList = sortedReceiptList.where((receipt) {
            // Include receipts that match selected categories or have a null categoryId if "Uncategorized" is selected
            if (includeUncategorized && receipt['categoryId'] == null) {
              return true;
            }
            // Check if the receipt matches any of the selected category IDs
            return selectedCategoryIds.contains(receipt['categoryId']);
          }).toList();
        }

        // Filter by date range
        if (_startDate != null && _endDate != null) {
          sortedReceiptList = sortedReceiptList.where((receipt) {
            final receiptDate = (receipt['date'] as Timestamp).toDate();
            return receiptDate.isAfter(_startDate!) &&
                receiptDate.isBefore(_endDate!);
          }).toList();
        }

        _sortReceiptList();

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 80),
          itemCount: sortedReceiptList.length,
          itemBuilder: (context, index) {
            final receipt = sortedReceiptList[index];
            return _buildReceiptCard(receipt);
          },
        );
      },
    );
  }

  Stack _buildFloatingActionButtons() {
    return Stack(
      children: [
        Positioned(
          bottom: 3,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, AddOrUpdateReceiptScreen.id);
            },
            backgroundColor: Colors.lightBlueAccent,
            heroTag: 'addReceiptFAB',
            elevation: 6,
            child: Icon(Icons.add),
          ),
        ),
        Positioned(
          bottom: 3,
          left: 46,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, ExpenseChartScreen.id);
            },
            backgroundColor: Colors.lightBlueAccent,
            heroTag: 'expenseChartFAB',
            elevation: 6,
            child: Icon(Icons.bar_chart),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Receipts'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: CustomDrawer(),
      body: loggedInUser == null
          ? _buildLoadingIndicator()
          : Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                // Buttons (actions) above the scrolling list
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12), // Apply padding to the Row
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Minimize the size of the Row
                    children: [
                      DateRangeContainer(
                        startDate: _startDate!,
                        endDate: _endDate!,
                        onCalendarPressed:
                            _showCalendarFilterDialog, // Pass the calendar callback
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.filter_alt_outlined,
                            color: Colors.lightBlue), // Filter icon
                        onPressed:
                            _showCategoryFilterDialog, // Show category filter dialog
                      ),
                      IconButton(
                        icon: Icon(Icons.sort,
                            color: Colors.lightBlue), // Sort button icon
                        onPressed: () {
                          _showSortBottomSheet(
                              context); // Trigger the rolling picker when the button is pressed
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _buildReceiptList(), // The receipt list that can scroll
                ),
              ],
            ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }
}
