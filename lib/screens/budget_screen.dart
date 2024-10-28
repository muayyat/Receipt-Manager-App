import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/add_budget_widget.dart';
import '../components/custom_drawer.dart';
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  static const String id = 'budget_screen';

  const BudgetScreen({super.key});

  @override
  BudgetScreenState createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  User? loggedInUser;

  List<Map<String, dynamic>> userBudgets = [];
  String? selectedBudgetId;

  final BudgetService _budgetService = BudgetService();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    if (loggedInUser != null) {
      fetchUserBudgets(); // Call fetchUserBudgets only after loggedInUser is assigned.
    }
  }

  Future<void> fetchUserBudgets() async {
    try {
      List<Map<String, dynamic>> budgets =
          await _budgetService.fetchUserBudgets(loggedInUser!.email!);

      setState(() {
        userBudgets = budgets;
      });
    } catch (e) {
      logger.e("Error fetching user budgets: $e");
    }
  }

  // Function to show the AddBudgetWidget dialog
  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: AddBudgetWidget(
            userId: loggedInUser!.email!,
            onBudgetAdded: () {
              // Refresh budgets when a new budget is added
              fetchUserBudgets();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Budgets'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: userBudgets.length,
                itemBuilder: (context, index) {
                  String budgetId = userBudgets[index]['categoryId'] ?? '';
                  String budgetAmount =
                      userBudgets[index]['amount']?.toString() ?? '0';
                  String budgetCurrency =
                      userBudgets[index]['currency'] ?? 'USD';
                  String budgetPeriod =
                      userBudgets[index]['period'] ?? 'monthly';
                  bool isSelected = budgetId == selectedBudgetId;

                  return Container(
                    color: isSelected
                        ? Colors.lightBlue.withOpacity(0.2)
                        : null, // Highlight selected row
                    child: ListTile(
                      title: Text(
                        'Budget for $budgetId: $budgetAmount $budgetCurrency',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('Period: $budgetPeriod'),
                      onTap: () {
                        setState(() {
                          selectedBudgetId = budgetId;
                        });
                        Navigator.pop(context, selectedBudgetId);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetDialog,
        backgroundColor: Colors.lightBlueAccent,
        elevation: 6,
        child: Icon(Icons.add),
      ),
    );
  }
}
