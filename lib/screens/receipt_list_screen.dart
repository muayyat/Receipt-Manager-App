import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  late Stream<QuerySnapshot> receiptsStream;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;

          // Now that we have the user, fetch receipts for this user only
          receiptsStream = _firestore
              .collection('receipts')
              .where('userId', isEqualTo: loggedInUser?.email)
              .snapshots();
        });
      }
    } catch (e) {
      print("Error fetching user: $e"); // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt List'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: loggedInUser == null
          ? Center(
              child:
                  CircularProgressIndicator()) // Show a loader until the user is loaded
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
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    var receiptData =
                        receipts[index].data() as Map<String, dynamic>;

                    // Extract fields from Firestore data
                    String date = receiptData['date'] ?? '';
                    String itemName = receiptData['itemName'] ?? '';
                    String merchant = receiptData['merchant'] ?? '';
                    String category = receiptData['category'] ?? '';
                    double amount = receiptData['amount'] ?? 0.0;
                    String currency = receiptData['currency'] ?? '';

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
                        trailing: Text('$currency $amount'),
                      ),
                    );
                  },
                );
              },
            ),
      // Use a Stack to position multiple FABs
      floatingActionButton: Stack(
        children: [
          // First FAB (for adding a receipt)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                // Navigate to the AddReceiptScreen when the button is pressed
                Navigator.pushNamed(context, AddReceiptScreen.id);
              },
              child: Icon(Icons.add), // Icon for the FAB
              backgroundColor: Colors.lightBlueAccent,
            ),
          ),
          // Second FAB (for opening the chart screen)
          Positioned(
            bottom: 16,
            left: 46, // Position at the left bottom corner
            child: FloatingActionButton(
              onPressed: () {
                // Navigate to the ExpenseChartScreen when the button is pressed
                Navigator.pushNamed(context, ExpenseChartScreen.id);
              },
              child: Icon(Icons.pie_chart), // Icon for the FAB
              backgroundColor: Colors.lightBlueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
