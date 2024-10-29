import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/custom_drawer.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/receipt_service.dart';

class SummaryScreen extends StatefulWidget {
  static const String id = 'summary_screen';

  const SummaryScreen({super.key});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  User? loggedInUser;

  final BudgetService _budgetService = BudgetService();
  final ReceiptService _receiptService = ReceiptService();

  String selectedBaseCurrency = 'EUR';

  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, dynamic> budgetData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    _loadData();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Set the start and end dates for the selected month
    DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    DateTime endDate = DateTime(
        selectedDate.year, selectedDate.month + 1, 0); // Last day of the month

    // Fetch budgets and expenses for the selected month
    List<Map<String, dynamic>> budgets =
        await _budgetService.fetchUserBudgets(loggedInUser!.email!);
    Map<String, double> expenses = await _receiptService
        .groupReceiptsByCategory(selectedBaseCurrency, startDate, endDate);

    // Organize data for visualization
    setState(() {
      budgetData = {'budgets': budgets, 'expenses': expenses};
      isLoading = false;
    });
  }

  Color getColor(double ratio) {
    if (ratio < 0.75) return Colors.green;
    if (ratio < 1.0) return Colors.yellow;
    return Colors.red;
  }

  void _selectMonth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light(),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month);
      });
      await _loadData(); // Reload data for the new month
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Budget Status'),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectMonth,
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: budgetData['budgets']?.length ?? 0,
              itemBuilder: (context, index) {
                var budget = budgetData['budgets'][index];
                String categoryId = budget['categoryId'];
                double budgetAmount = budget['amount'];
                double spent = budgetData['expenses'][categoryId] ?? 0.0;
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
                  ratioText = '${(ratio * 100).toStringAsFixed(1)}%';
                }
                return ListTile(
                  title: Text(categoryId),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget: ${budget['currency']} $budgetAmount, Spent: ${budget['currency']} $spent',
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
    );
  }
}
