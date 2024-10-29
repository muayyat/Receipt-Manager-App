import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/custom_drawer.dart';
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
        baseCurrency = 'EUR'; // Default currency
      }

      if (baseCurrency != null) {
        Map<String, double> expenses = await _receiptService
            .groupReceiptsByCategory(baseCurrency!, startDate, endDate);

        setState(() {
          budgetData = {'budgets': budgets, 'expenses': expenses};
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        isLoading = false; // Stop loading if an error occurs
      });
    }
  }

  Color getColor(double ratio) {
    if (ratio < 0.75) return Colors.green;
    if (ratio < 1.0) return Colors.yellow;
    return Colors.red;
  }

  void _selectMonth() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        int selectedYear = selectedDate.year;
        int selectedMonth = selectedDate.month;

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Select Month',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Year Picker
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedYear - 2020, // Start from 2020
                      ),
                      itemExtent: 32.0,
                      onSelectedItemChanged: (index) {
                        selectedYear = 2020 + index;
                      },
                      children: List<Widget>.generate(
                        20,
                        (index) => Center(child: Text('${2020 + index}')),
                      ),
                    ),
                  ),
                  // Month Picker
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedMonth - 1,
                      ),
                      itemExtent: 32.0,
                      onSelectedItemChanged: (index) {
                        selectedMonth = index + 1;
                      },
                      children: List<Widget>.generate(
                        12,
                        (index) => Center(child: Text('${index + 1}')),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(selectedYear, selectedMonth);
                  });
                  Navigator.pop(context);
                },
                child: Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Budget Status'),
        backgroundColor: Colors.lightBlue,
      ),
      drawer: CustomDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month and Year Dropdown Menus
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Month Dropdown
                      DropdownButton<String>(
                        value: months[selectedDate.month - 1],
                        items: months.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: (String? newMonth) {
                          setState(() {
                            int monthIndex = months.indexOf(newMonth!) + 1;
                            selectedDate =
                                DateTime(selectedDate.year, monthIndex);
                            _loadData(); // Reload data for the new month and year
                          });
                        },
                      ),
                      SizedBox(width: 20),
                      // Year Dropdown
                      DropdownButton<int>(
                        value: selectedDate.year,
                        items: years.map((int year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (int? newYear) {
                          setState(() {
                            selectedDate =
                                DateTime(newYear!, selectedDate.month);
                            _loadData(); // Reload data for the new month and year
                          });
                        },
                      ),
                    ],
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
                            String categoryId = budget['categoryId'];
                            double budgetAmount = budget['amount'];
                            double spent =
                                budgetData['expenses'][categoryId] ?? 0.0;
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

                            return ListTile(
                              title: Text(categoryId),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Budget: ${budget['currency']} ${budgetAmount.toStringAsFixed(2)}, Spent: ${budget['currency']} ${spent.toStringAsFixed(2)}',
                                  ),
                                  LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    color: getColor(ratio),
                                    backgroundColor: Colors.grey[300],
                                  ),
                                ],
                              ),
                              trailing: Text(
                                ratioText,
                                style: TextStyle(
                                  color: getColor(ratio),
                                  fontWeight: FontWeight.bold,
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
