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
  Stream<QuerySnapshot>? receiptsStream;
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
          .where('userId', isEqualTo: loggedInUser?.email)
          .orderBy(currentSortField, descending: isDescending)
          .snapshots();
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
      appBar: AppBar(
        title: Text('Receipt List'),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          PopupMenuButton<String>(
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
              PopupMenuItem(
                  value: 'date_asc',
                  child: Text('Date: Oldest First')), // Correct value
              PopupMenuItem(
                  value: 'date_desc',
                  child: Text('Date: Newest First')), // Correct value
              PopupMenuItem(
                  value: 'amount_asc',
                  child: Text('Amount: Lowest First')), // Correct value
              PopupMenuItem(
                  value: 'amount_desc',
                  child: Text('Amount: Highest First')), // Correct value
            ],
            icon: Icon(Icons.sort),
          ),
        ],
      ),
      body: loggedInUser == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: receiptsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final receipts = snapshot.data?.docs ?? [];

                if (receipts.isEmpty) {
                  return Center(child: Text('No receipts found.'));
                }

                return ListView.builder(
                  padding: EdgeInsets.only(bottom: 80),
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    var receiptData =
                        receipts[index].data() as Map<String, dynamic>;

                    Timestamp timestamp =
                        receiptData['date'] ?? Timestamp.now();
                    DateTime dateTime = timestamp.toDate();
                    String date = DateFormat('yyyy-MM-dd').format(dateTime);
                    String itemName = receiptData['itemName'] ?? '';
                    String merchant = receiptData['merchant'] ?? '';
                    String category = receiptData['category'] ?? '';
                    double amount = receiptData['amount'] ?? 0.0;
                    String currency = receiptData['currency'] ?? '';
                    String imageUrl =
                        receiptData['imageUrl'] ?? ''; // Get the image URL

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: ListTile(
                        title: Text(itemName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Merchant: $merchant'),
                            Text('Date: $date'),
                            Text('Category: $category'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$currency $amount'),
                            if (imageUrl
                                .isNotEmpty) // Check if image URL is not empty
                              Container(
                                height: 40, // Set a fixed height for the image
                                width: 40, // Set a fixed width for the image
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover, // Adjust image fit
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                              : null),
                                    );
                                  },
                                  errorBuilder: (BuildContext context,
                                      Object error, StackTrace? stackTrace) {
                                    return Text('Image failed to load');
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Stack(
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
      ),
    );
  }
}
