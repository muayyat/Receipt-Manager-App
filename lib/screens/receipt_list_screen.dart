import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final _firestore = FirebaseFirestore.instance;

class ReceiptListScreen extends StatefulWidget {
  static const String id = 'receipt_list_screen';

  @override
  _ReceiptListScreenState createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  late Stream<QuerySnapshot> receiptsStream;

  @override
  void initState() {
    super.initState();
    receiptsStream = _firestore.collection('receipts').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              var receiptData = receipts[index].data() as Map<String, dynamic>;

              // Extract fields from Firestore data
              String date = receiptData['date'] ?? '';
              String itemName = receiptData['itemName'] ?? '';
              String merchant = receiptData['merchant'] ?? '';
              String category = receiptData['category'] ?? '';
              double amount = receiptData['amount'] ?? 0.0;
              String currency = receiptData['currency'] ?? '';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
    );
  }
}
