import 'package:firebase_auth/firebase_auth.dart';
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
      print("Error loading data: $e");
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

                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 16.0),
                              title: Row(
                                children: [
                                  Text(categoryIcon,
                                      style: TextStyle(fontSize: 26.0)),
                                  SizedBox(width: 8.0),
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Budget: ${budget['currency']} ${budgetAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14.0),
                                      ),
                                      Text(
                                        'Spent: ${budget['currency']} ${spent.toStringAsFixed(2)} ($ratioText)',
                                        style: TextStyle(
                                          color: getColor(ratio),
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
