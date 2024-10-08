import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/calendar_filter_widget.dart'; // Import the CalendarFilterWidget
import '../components/custom_drawer.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart'; // Import CategoryService
import '../services/receipt_service.dart';
import 'add_update_receipt_screen.dart';
import 'expense_chart_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  static const String id = 'receipt_list_screen';

  @override
  _ReceiptListScreenState createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  User? loggedInUser;
  final ReceiptService receiptService = ReceiptService();
  final CategoryService categoryService =
      CategoryService(); // Add CategoryService

  Stream<DocumentSnapshot>? receiptsStream;
  String currentSortField = 'date';
  bool isDescending = false;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> sortedReceiptList = [];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    if (loggedInUser != null) {
      setState(() {
        receiptsStream = receiptService.fetchReceipts();
      });
    }
  }

  void onSortChanged(String newSortField, bool descending) {
    setState(() {
      currentSortField = newSortField;
      isDescending = descending;
    });
    _sortReceiptList();
  }

  void _sortReceiptList() {
    sortedReceiptList.sort((a, b) {
      var aValue, bValue;

      if (currentSortField == 'date') {
        aValue = (a['date'] as Timestamp).toDate();
        bValue = (b['date'] as Timestamp).toDate();
      } else if (currentSortField == 'amount') {
        aValue = (a['amount'] as num).toDouble();
        bValue = (b['amount'] as num).toDouble();
      }

      return isDescending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
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
          initialStartDate: _startDate ?? DateTime.now(),
          initialEndDate: _endDate ?? DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: CustomDrawer(),
      body:
          loggedInUser == null ? _buildLoadingIndicator() : _buildReceiptList(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Receipt List'),
      backgroundColor: Colors.lightBlueAccent,
      actions: [
        IconButton(
          icon: Icon(Icons.calendar_today, color: Colors.white),
          onPressed: _showCalendarFilterDialog,
        ),
        _buildSortPopup(),
      ],
    );
  }

  PopupMenuButton<String> _buildSortPopup() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'date_asc') {
          onSortChanged('date', false);
        } else if (value == 'date_desc') {
          onSortChanged('date', true);
        } else if (value == 'amount_asc') {
          onSortChanged('amount', false);
        } else if (value == 'amount_desc') {
          onSortChanged('amount', true);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'date_asc', child: Text('Date: Oldest First')),
        PopupMenuItem(value: 'date_desc', child: Text('Date: Newest First')),
        PopupMenuItem(value: 'amount_asc', child: Text('Amount: Lowest First')),
        PopupMenuItem(
            value: 'amount_desc', child: Text('Amount: Highest First')),
      ],
      icon: Icon(Icons.sort),
    );
  }

  Center _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
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
      child: (loggedInUser?.email != null && categoryId != null)
          ? FutureBuilder<Map<String, dynamic>?>(
              future: categoryService.fetchCategoryById(
                  loggedInUser!.email!, categoryId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                String categoryName = snapshot.data?['name'] ?? 'Uncategorized';
                String categoryIcon = snapshot.data?['icon'] ??
                    '📦'; // Default icon for uncategorized

                return _buildReceiptCardContent(imageUrl, itemName, merchant,
                    date, categoryName, currency, amount);
              },
            )
          : _buildReceiptCardContent(
              imageUrl,
              itemName,
              merchant,
              date,
              'Uncategorized',
              currency,
              amount), // Handle case where categoryId is null
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
      String itemName, String merchant, String date, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(itemName, style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Merchant: $merchant'),
        Text('Date: $date'),
        Text('Category: $category'), // Display the fetched category name
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
            child: Icon(Icons.add),
            backgroundColor: Colors.lightBlueAccent,
            heroTag: 'addReceiptFAB',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 6,
          ),
        ),
        Positioned(
          bottom: 3,
          left: 46,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, ExpenseChartScreen.id);
            },
            child: Icon(Icons.pie_chart),
            backgroundColor: Colors.lightBlueAccent,
            heroTag: 'expenseChartFAB',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 6,
          ),
        ),
      ],
    );
  }
}
