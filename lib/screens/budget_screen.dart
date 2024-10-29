import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/currency_roller_picker.dart';
import '../components/custom_drawer.dart';
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';

class BudgetScreen extends StatefulWidget {
  static const String id = 'budget_screen';

  const BudgetScreen({super.key});

  @override
  BudgetScreenState createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  User? loggedInUser;
  List<Map<String, dynamic>> userCategories =
      []; // Store categories with budget
  String selectedPeriod = 'Monthly';
  String selectedCurrency = 'EUR';

  final CategoryService _categoryService = CategoryService();
  final BudgetService _budgetService = BudgetService();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    if (loggedInUser != null) {
      fetchUserCategoriesAndBudgets(); // Fetch categories and budgets after assigning loggedInUser
    }
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CurrencyPicker(
          selectedCurrency: selectedCurrency,
          onCurrencySelected: (String newCurrency) {
            setState(() {
              selectedCurrency = newCurrency;
            });
          },
        );
      },
    );
  }

  Future<void> fetchUserCategoriesAndBudgets() async {
    try {
      logger.i(
          "Fetching categories and budgets for user: ${loggedInUser!.email}");

      // Fetch categories and budget data from services
      List<Map<String, dynamic>> categories =
          await _categoryService.fetchUserCategories(loggedInUser!.email!);
      List<Map<String, dynamic>> budgets =
          await _budgetService.fetchUserBudgets(loggedInUser!.email!);

      logger.i("Fetched categories: $categories");
      logger.i("Fetched budgets: $budgets");

      if (budgets.isNotEmpty) {
        selectedCurrency = budgets[0]['currency'] ?? 'EUR';
        selectedPeriod = budgets[0]['period'] ?? 'Monthly';
      }

      // Map budgets by categoryId for quick lookup
      Map<String, dynamic> budgetMap = {
        for (var budget in budgets)
          budget['categoryId']: budget['amount'] ?? 0.0
      };
      logger.i("Mapped budget data by categoryId: $budgetMap");

      // Combine categories with their respective budget amounts
      setState(() {
        userCategories = categories.map((category) {
          String categoryId = category['id'] ?? '';
          String categoryName = category['name'] ?? 'Unknown';
          String categoryIcon = category['icon'] ?? '📦';
          double budgetAmount = budgetMap[categoryId] ?? 0.0;

          logger.i(
              "Processing category - ID: $categoryId, Name: $categoryName, Icon: $categoryIcon, Budget: $budgetAmount");

          return {
            'categoryId': categoryId,
            'categoryName': categoryName,
            'categoryIcon': categoryIcon,
            'budget': budgetAmount,
          };
        }).toList();
      });

      logger.i("Final user categories with budgets: $userCategories");
    } catch (e) {
      logger.e("Error fetching user categories or budgets: $e");
    }
  }

  Future<void> saveAllBudgets() async {
    try {
      logger.i("Saving all budgets for user: ${loggedInUser!.email}");

      // Create a list of budget entries to save
      List<Map<String, dynamic>> budgetList = userCategories.map((category) {
        return {
          'categoryId': category['categoryId'],
          'amount': category['budget'],
          'currency': selectedCurrency,
          'period': selectedPeriod,
        };
      }).toList();

      // Call the service to update the user's budget list in the backend
      await _budgetService.updateUserBudgets(loggedInUser!.email!, budgetList);

      logger.i("Successfully saved all budgets");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Budgets saved successfully'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      logger.e("Error saving budgets: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save budgets'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure dropdown values have defaults if they are null
    final periodOptions = ['Monthly', 'Yearly'];
    if (!periodOptions.contains(selectedPeriod)) selectedPeriod = 'Monthly';

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Budgets'),
        backgroundColor: Colors.lightBlue,
      ),
      drawer: CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period and Currency Dropdowns
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedPeriod,
                  items: periodOptions
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value!;
                    });
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors
                        .transparent, // No background color for outlined look
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          8.0), // Same border radius as the date range picker
                      side: BorderSide(
                          color: Colors.lightBlue), // Border color and width
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14), // Match padding
                  ),
                  onPressed: () {
                    _showCurrencyPicker(
                        context); // Show the currency picker when button is pressed
                  },
                  child: Text(
                    selectedCurrency,
                    style: TextStyle(
                      color: Colors
                          .lightBlue, // Text color similar to date range picker
                      fontSize: 16, // Match font size with DateRangeContainer
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 10),
            // Category List with Budget Input
            Expanded(
              child: ListView.builder(
                itemCount: userCategories.length,
                itemBuilder: (context, index) {
                  String categoryName = userCategories[index]['categoryName'];
                  String categoryIcon = userCategories[index]['categoryIcon'];
                  double budgetAmount = userCategories[index]['budget'];

                  return ListTile(
                    leading: Text(
                      categoryIcon,
                      style: TextStyle(fontSize: 28),
                    ),
                    title: Text(categoryName, style: TextStyle(fontSize: 18)),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: budgetAmount.toStringAsFixed(2),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            userCategories[index]['budget'] =
                                double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveAllBudgets,
        backgroundColor: Colors.lightBlueAccent,
        elevation: 6,
        child: Icon(Icons.save),
      ),
    );
  }
}
