import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ExpenseChartScreen extends StatefulWidget {
  static const String id = 'expense_chart_screen';

  @override
  _ExpenseChartScreenState createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  Map<String, double> categoryTotals =
      {}; // To store total expenses by category
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    // Fetch the expense data after getting the user
    fetchExpenseData();
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
        title: Text('Expenses Analysis'),
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
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: getSections(),
                            centerSpaceRadius:
                                60, // Larger center space for better look
                            borderData: FlBorderData(show: false),
                            sectionsSpace:
                                4, // Spacing between sections for clarity
                            startDegreeOffset:
                                -90, // Start from the top for pie sections
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Adding a legend for better understanding
                      Wrap(
                        spacing: 10,
                        children: categoryTotals.entries.map((entry) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: getColorForCategory(entry.key),
                              ),
                              SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          );
                        }).toList(),
                      )
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
        radius: 70, // Increase the radius of pie sections for a better view
        titleStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  // This function assigns a color to each category
  Color getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.blueAccent;
      case 'Transport':
        return Colors.greenAccent;
      case 'Entertainment':
        return Colors.orangeAccent;
      case 'Shopping':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }
}
