import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import 'add_receipt_screen.dart';
import 'expense_chart_screen.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ReceiptListScreen extends StatefulWidget {
  static const String id = 'receipt_list_screen';

  @override
  _ReceiptListScreenState createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  Stream<DocumentSnapshot>? receiptsStream;
  String currentSortField = 'date';
  bool isDescending = false;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    if (loggedInUser != null) {
      setState(() {
        fetchReceipts();
      });
    }
  }

  void fetchReceipts() {
    setState(() {
      receiptsStream = _firestore
              .collection('receipts')
              .doc(loggedInUser?.email) // Fetch the document using email (userId)
              .snapshots()
          as Stream<
              DocumentSnapshot<
                  Object?>>?; // Return the document snapshot stream
    });
  }

  void onSortChanged(String newSortField, bool descending) {
    setState(() {
      currentSortField = newSortField;
      isDescending = descending;
      fetchReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body:
          loggedInUser == null ? _buildLoadingIndicator() : _buildReceiptList(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Receipt List'),
      backgroundColor: Colors.lightBlueAccent,
      actions: [_buildSortPopup()],
    );
  }

  PopupMenuButton<String> _buildSortPopup() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        // Handle sort selection
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
      stream: receiptsStream, // Stream for the single document snapshot
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Check if the document exists and has data
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.data() == null) {
          return Center(child: Text('No receipts found.'));
        }

        // Get the receiptlist array from the document
        final receiptList =
            snapshot.data!.get('receiptlist') as List<dynamic>? ?? [];

        // Check if the receiptlist array is empty
        if (receiptList.isEmpty) {
          return Center(child: Text('No receipts available.'));
        }

        // Display the receipt cards using ListView.builder
        return ListView.builder(
          padding: EdgeInsets.only(bottom: 80),
          itemCount: receiptList.length,
          itemBuilder: (context, index) {
            final receipt = receiptList[index]
                as Map<String, dynamic>; // Treat each receipt as a Map
            return _buildReceiptCard(
                receipt); // Pass the receipt map to _buildReceiptCard
          },
        );
      },
    );
  }

  Card _buildReceiptCard(Map<String, dynamic> receiptData) {
    // Extract data from the receipt map
    Timestamp timestamp = receiptData['date'] ?? Timestamp.now();
    DateTime dateTime = timestamp.toDate();
    String date = DateFormat('yyyy-MM-dd').format(dateTime);
    String itemName = receiptData['itemName'] ?? '';
    String merchant = receiptData['merchant'] ?? '';
    String category = receiptData['category'] ?? '';
    double amount = receiptData['amount'] ?? 0.0;
    String currency = receiptData['currency'] ?? '';
    String imageUrl = receiptData['imageUrl'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            _buildImageSection(imageUrl),
            Expanded(
                child: _buildTextDetails(itemName, merchant, date, category)),
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
      margin: EdgeInsets.only(right: 10), // Space between image and text
      decoration: BoxDecoration(
        color: Colors.grey[300], // Placeholder color
        borderRadius: BorderRadius.circular(4),
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius:
                  BorderRadius.circular(4), // Add border radius to image
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
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
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return Text('Image failed to load');
                },
              ),
            )
          : Container(), // Empty container when image URL is not provided
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
        Text('Category: $category'),
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
              Navigator.pushNamed(context, AddReceiptScreen.id);
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
