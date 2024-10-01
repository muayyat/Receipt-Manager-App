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
  Map<String, Color> categoryColors = {}; // To store category to color mapping
  bool isLoading = true;

  // Predefined list of colors
  final List<Color> availableColors = [
    Color(0xFF42A5F5), // Soft Blue
    Color(0xFF66BB6A), // Soft Green
    Color(0xFFEF5350), // Soft Red
    Color(0xFFFFCA28), // Soft Yellow
    Color(0xFFAB47BC), // Soft Purple
    Color(0xFFFF7043), // Soft Orange
    Color(0xFF26C6DA), // Soft Cyan
    Color(0xFF8D6E63), // Soft Brown
  ];

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
      Set<String> categories = {}; // To track unique categories

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String category = data['category'];
        double amount = (data['amount'] as num).toDouble();

        // Add category to the set
        categories.add(category);

        if (tempCategoryTotals.containsKey(category)) {
          tempCategoryTotals[category] = tempCategoryTotals[category]! + amount;
        } else {
          tempCategoryTotals[category] = amount;
        }
      }

      // Generate a color mapping for the categories
      generateColorMapping(categories);

      setState(() {
        categoryTotals = tempCategoryTotals;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  // Generate colors for each unique category
  void generateColorMapping(Set<String> categories) {
    categoryColors.clear(); // Clear previous mappings if any
    int colorIndex = 0;

    for (var category in categories) {
      // Assign colors from the available list in a round-robin manner
      categoryColors[category] =
          availableColors[colorIndex % availableColors.length];
      colorIndex++;
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
                            centerSpaceRadius: 60,
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                            startDegreeOffset: -90,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        children: categoryTotals.entries.map((entry) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: categoryColors[entry.key],
                              ),
                              SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          );
                        }).toList(),
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
        color: categoryColors[category], // Get color from the map
        value: total,
        title:
            '${category}\n(${total.toStringAsFixed(2)})', // Add new line for better spacing
        radius: 70,
        titleStyle: TextStyle(
            fontSize: 14, // Slightly smaller for longer names
            fontWeight: FontWeight.bold),
      );
    }).toList();
  }
}
