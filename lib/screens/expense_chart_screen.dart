import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseChartScreen extends StatefulWidget {
  static const String id = 'expense_chart_screen';

  @override
  _ExpenseChartScreenState createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? loggedInUser;

  Map<String, double> categoryTotals =
      {}; // To store total expenses by category
  bool isLoading = true;

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
        });
        // Fetch the expense data after getting the user
        fetchExpenseData();
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  Future<void> fetchExpenseData() async {
    if (loggedInUser == null) return;

    try {
      // Query Firestore to get receipts for the current user only
      QuerySnapshot snapshot = await _firestore
          .collection('receipts')
          .where('userId', isEqualTo: loggedInUser?.email)
          .get();

      // Process the data to calculate total for each category
      Map<String, double> tempCategoryTotals = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String category = data['category'];
        double amount = (data['amount'] as num).toDouble();

        if (tempCategoryTotals.containsKey(category)) {
          tempCategoryTotals[category] = tempCategoryTotals[category]! + amount;
        } else {
          tempCategoryTotals[category] = amount;
        }
      }

      setState(() {
        categoryTotals = tempCategoryTotals;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses by Category'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : categoryTotals.isEmpty
              ? Center(child: Text('No data available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Expenses by Category',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: getSections(),
                            centerSpaceRadius: 40,
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<PieChartSectionData> getSections() {
    return categoryTotals.entries.map((entry) {
      final category = entry.key;
      final total = entry.value;

      return PieChartSectionData(
        color: getColorForCategory(category),
        value: total,
        title: '${category} (${total.toStringAsFixed(2)})',
        radius: 60,
        titleStyle: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  // This function assigns a color to each category
  Color getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.blue;
      case 'Transport':
        return Colors.green;
      case 'Entertainment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
