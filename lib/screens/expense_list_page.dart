import 'package:flutter/material.dart';

import '../components/custom_bottom_nav_bar.dart';

class ExpenseListPage extends StatefulWidget {
  static const String id = 'expense_list_page';
  const ExpenseListPage({super.key});

  @override
  ExpenseListPageState createState() => ExpenseListPageState();
}

class ExpenseListPageState extends State<ExpenseListPage> {
  int _selectedIndex = 1; // Default to the "Transaction" tab

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add your navigation logic here based on the selected index
    // Example: Navigate to different pages
    // if (index == 0) { navigate to home page }
    // if (index == 2) { navigate to budget page }
    // if (index == 3) { navigate to profile page }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialReportButton(),
            const SizedBox(height: 16),
            _buildTransactionSection("Today"),
            const SizedBox(height: 16),
            _buildTransactionSection("Yesterday"),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        initialIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle add new transaction
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Transaction',
        style: TextStyle(color: Colors.black),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Handle menu action
          },
        ),
      ],
    );
  }

  Widget _buildFinancialReportButton() {
    return TextButton(
      onPressed: () {
        // Handle financial report navigation
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.purple.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        "See your financial report",
        style: TextStyle(color: Colors.purple.shade700),
      ),
    );
  }

  Widget _buildTransactionSection(String sectionTitle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView(
              children: _buildTransactionItems(sectionTitle),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionItems(String section) {
    // Define your transactions here based on the section (Today, Yesterday, etc.)
    // Replace with dynamic data or API data if needed.
    final transactions = section == "Today"
        ? [
            _transactionData(
              icon: Icons.shopping_bag,
              iconColor: Colors.orange.shade200,
              title: "Shopping",
              subtitle: "Buy some grocery",
              amount: "- \$120",
              amountColor: Colors.red,
              time: "10:00 AM",
            ),
            _transactionData(
              icon: Icons.subscriptions,
              iconColor: Colors.purple.shade200,
              title: "Subscription",
              subtitle: "Disney+ Annual",
              amount: "- \$80",
              amountColor: Colors.red,
              time: "03:30 PM",
            ),
            _transactionData(
              icon: Icons.restaurant,
              iconColor: Colors.red.shade200,
              title: "Food",
              subtitle: "Buy a ramen",
              amount: "- \$32",
              amountColor: Colors.red,
              time: "07:30 PM",
            ),
          ]
        : [
            _transactionData(
              icon: Icons.monetization_on,
              iconColor: Colors.green.shade200,
              title: "Salary",
              subtitle: "Salary for July",
              amount: "+ \$5000",
              amountColor: Colors.green,
              time: "04:30 PM",
            ),
            _transactionData(
              icon: Icons.directions_car,
              iconColor: Colors.blue.shade200,
              title: "Transportation",
              subtitle: "Charging Tesla",
              amount: "- \$18",
              amountColor: Colors.red,
              time: "08:30 PM",
            ),
          ];

    return transactions
        .map((transaction) => _buildTransactionItem(transaction))
        .toList();
  }

  Map<String, dynamic> _transactionData({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
    required String time,
  }) {
    return {
      "icon": icon,
      "iconColor": iconColor,
      "title": title,
      "subtitle": subtitle,
      "amount": amount,
      "amountColor": amountColor,
      "time": time,
    };
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: data['iconColor'],
          child: Icon(data['icon'], color: Colors.white),
        ),
        title: Text(
          data['title'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(data['subtitle'], style: TextStyle(color: Colors.grey)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data['amount'],
              style: TextStyle(
                color: data['amountColor'],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              data['time'],
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
