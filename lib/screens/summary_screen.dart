import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/custom_drawer.dart';
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';
import '../services/receipt_service.dart';

class SummaryScreen extends StatefulWidget {
  static const String id = 'summary_screen';

  const SummaryScreen({super.key});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  User? loggedInUser;

  final CategoryService _categoryService = CategoryService();
  final BudgetService _budgetService = BudgetService();
  final ReceiptService _receiptService = ReceiptService();

  String? baseCurrency;

  DateTime selectedDate = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> budgetData = {};
  bool isLoading = true;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  final List<int> years = List<int>.generate(
      20, (index) => 2020 + index); // Range from 2020 to 2039

  @override
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    if (loggedInUser != null) {
      _loadData(); // Only load data after authentication is complete
    } else {
      setState(() {
        isLoading = false; // Stop loading if user is not authenticated
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      DateTime endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      List<Map<String, dynamic>> budgets =
          await _budgetService.fetchUserBudgets(loggedInUser!.email!);
      if (budgets.isNotEmpty && budgets[0]['currency'] != null) {
        baseCurrency = budgets[0]['currency'];
      } else {
        baseCurrency = 'EUR';
      }

      if (baseCurrency != null) {
        Map<String, double> expenses = await _receiptService
            .groupReceiptsByCategory(baseCurrency!, startDate, endDate);

        // Fetch categories and convert to map format with categoryId as the key
        List<Map<String, dynamic>> categoriesList =
            await _categoryService.fetchUserCategories(loggedInUser!.email!);
        Map<String, Map<String, dynamic>> categoryMap = {
          for (var category in categoriesList)
            category['id']: {
              'name': category['name'],
              'icon': category[
                  'icon'], // Ensure icon is stored as IconData if possible
            },
        };

        setState(() {
          budgetData = {
            'budgets': budgets.map((budget) {
              String categoryId = budget['categoryId'];
              Map<String, dynamic> categoryDetails =
                  categoryMap[categoryId] ?? {};
              budget['categoryName'] = categoryDetails['name'] ?? 'Unknown';
              budget['categoryIcon'] = categoryDetails['icon'] ?? '';
              return budget;
            }).toList(),
            'expenses': expenses
          };
          isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Error loading data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getColor(double ratio) {
    if (ratio < 0.75) return Colors.green;
    if (ratio < 1.0) {
      return Color(
          0xFFF0C808); // A softer yellow, less intense but still distinct.
    }
    return Colors.red;
  }

  // Show month picker with a "Done" button
  void _showMonthPicker() {
    int initialMonthIndex = selectedDate.month - 1;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int tempSelectedMonth = initialMonthIndex + 1;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month Picker
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: initialMonthIndex),
                itemExtent: 36.0,
                onSelectedItemChanged: (int index) {
                  tempSelectedMonth = index + 1; // Update temp month selection
                },
                children: months
                    .map((month) => Text(month, style: TextStyle(fontSize: 24)))
                    .toList(),
              ),
            ),
            // "Done" Button
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    selectedDate =
                        DateTime(selectedDate.year, tempSelectedMonth);
                    _loadData();
                  });
                  Navigator.pop(context);
                },
                child: Text('DONE'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show year picker with a "Done" button
  void _showYearPicker() {
    int initialYearIndex = years.indexOf(selectedDate.year);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int tempSelectedYear = selectedDate.year;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year Picker
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: initialYearIndex),
                itemExtent: 36.0,
                onSelectedItemChanged: (int index) {
                  tempSelectedYear = years[index]; // Update temp year selection
                },
                children: years
                    .map((year) =>
                        Text(year.toString(), style: TextStyle(fontSize: 24)))
                    .toList(),
              ),
            ),
            // "Done" Button
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    selectedDate =
                        DateTime(tempSelectedYear, selectedDate.month);
                    _loadData();
                  });
                  Navigator.pop(context);
                },
                child: Text('DONE'),
              ),
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
        title: Text('Monthly Spending'),
        backgroundColor: Colors.lightBlue,
      ),
      drawer: CustomDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24), // Add padding
                    child: Row(
                      mainAxisSize: MainAxisSize
                          .min, // Ensure the row takes the minimum width needed
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Center the items within the row
                      children: [
                        // Month Button
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors
                                .transparent, // No background color for outlined look
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Same border radius as the date range picker
                              side: BorderSide(
                                  color: Colors
                                      .lightBlue), // Border color and width
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14), // Match padding
                          ),
                          onPressed: _showMonthPicker,
                          child: Text(
                            DateFormat.MMMM().format(selectedDate),
                            style: TextStyle(
                              color: Colors
                                  .lightBlue, // Text color similar to date range picker
                              fontSize:
                                  16, // Match font size with DateRangeContainer
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Year Button
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors
                                .transparent, // No background color for outlined look
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Same border radius as the date range picker
                              side: BorderSide(
                                  color: Colors
                                      .lightBlue), // Border color and width
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14), // Match padding
                          ),
                          onPressed: _showYearPicker,
                          child: Text(
                            selectedDate.year.toString(),
                            style: TextStyle(
                              color: Colors
                                  .lightBlue, // Text color similar to date range picker
                              fontSize:
                                  16, // Match font size with DateRangeContainer
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Budget and Expenses List
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: budgetData['budgets']?.length ?? 0,
                          itemBuilder: (context, index) {
                            var budget = budgetData['budgets'][index];
                            String categoryName = budget['categoryName'];
                            String categoryIcon = budget['categoryIcon'];
                            double budgetAmount = budget['amount'];
                            double spent = budgetData['expenses']
                                    [budget['categoryId']] ??
                                0.0;
                            String ratioText;
                            double ratio;

                            if (budgetAmount == 0) {
                              if (spent > 0) {
                                // Indicate over-budget with no budget set
                                ratioText = '∞%'; // or use 'Over Budget'
                                ratio = 1.0; // Force progress bar to full
                              } else {
                                // No budget and no spending
                                ratioText = '0.0%';
                                ratio = 0.0; // Keep progress bar empty
                              }
                            } else {
                              // Normal case where budgetAmount > 0
                              ratio = spent / budgetAmount;
                              ratioText =
                                  '${(ratio * 100).toStringAsFixed(1)}%';
                            }

                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 16.0),
                                leading: Container(
                                  width: 8.0,
                                  height: double.infinity,
                                  color: getColor(ratio),
                                ),
                                title: Row(
                                  children: [
                                    Text(categoryIcon,
                                        style: TextStyle(fontSize: 26.0)),
                                    SizedBox(width: 8.0),
                                    Text(
                                      categoryName,
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Budget Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Budget:',
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14.0),
                                        ),
                                        Text(
                                          '${budget['currency']} ${budgetAmount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 15.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        height:
                                            4.0), // Space between Budget and Spent rows

                                    // Spent Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Spent:',
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14.0),
                                        ),
                                        Text(
                                          '${budget['currency']} ${spent.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: getColor(ratio),
                                            fontSize: 15.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        height:
                                            4.0), // Space between Spent and Percentage rows

                                    // Percentage Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Percentage:',
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14.0),
                                        ),
                                        Text(
                                          ratioText,
                                          style: TextStyle(
                                            color: getColor(ratio),
                                            fontSize: 15.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
