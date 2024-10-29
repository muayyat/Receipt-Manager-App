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
            'controller': TextEditingController(
              text: budgetAmount.toStringAsFixed(2),
            ), // Initialize with the budget amount
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

      // Ensure the widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Budgets saved successfully'),
          backgroundColor: Colors.green,
        ));
      }

      // Refresh the list after saving
      await fetchUserCategoriesAndBudgets();

      // Forcefully refresh the list
      setState(() {
        fetchUserCategoriesAndBudgets();
      });
    } catch (e) {
      logger.e("Error saving budgets: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save budgets'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure dropdown values have defaults if they are null
    final periodOptions = ['Monthly'];
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
            Center(
              child: Row(
                mainAxisSize:
                    MainAxisSize.min, // Adjust to center the Row content
                children: [
                  // Styled Period DropdownButton
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.lightBlue), // Border color
                      borderRadius:
                          BorderRadius.circular(8.0), // Rounded corners
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPeriod,
                        items: periodOptions
                            .map((period) => DropdownMenuItem(
                                  value: period,
                                  child: Text(
                                    'Period: $period', // Display as "Period: Monthly"
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.lightBlue),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPeriod = value!;
                          });
                        },
                        icon: Icon(Icons.arrow_drop_down,
                            color: Colors.lightBlue),
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                      width: 16), // Space between the Dropdown and TextButton
                  // Styled Currency Picker Button
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(color: Colors.lightBlue),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onPressed: () {
                      _showCurrencyPicker(
                          context); // Show the currency picker when button is pressed
                    },
                    child: Text(
                      selectedCurrency,
                      style: TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Category List with Budget Input
            Expanded(
              child: ListView.builder(
                itemCount: userCategories.length,
                itemBuilder: (context, index) {
                  String categoryName = userCategories[index]['categoryName'];
                  String categoryIcon = userCategories[index]['categoryIcon'];
                  TextEditingController controller =
                      userCategories[index]['controller'];

                  return ListTile(
                    leading: Text(
                      categoryIcon,
                      style: TextStyle(fontSize: 26),
                    ),
                    title: Text(categoryName, style: TextStyle(fontSize: 16)),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12), // Add padding
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Rounded corners
                            borderSide: BorderSide(
                              color: Colors.grey[300]!, // Default border color
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.lightBlue, // Focused border color
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!, // Enabled border color
                              width: 1.0,
                            ),
                          ),
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
