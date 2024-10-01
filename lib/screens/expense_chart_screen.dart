import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/currency_service.dart';

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
  String selectedBaseCurrency = 'EUR'; // Default base currency

  // List of available currencies for filtering
  final List<String> availableCurrencies = ['EUR', 'USD', 'GBP'];

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

  DateTimeRange? selectedDateRange; // Store the selected date range

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchConversionRates();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    // Fetch the expense data after getting the user
    fetchExpenseData();
  }

  // Example static conversion rates
  Map<String, double> conversionRates = {
    'USD': 0.85, // Fallback rate if fetch fails
    'EUR': 1.0,
    'GBP': 1.17,
  };

  // Fetch real-time conversion rates
  Future<void> fetchConversionRates() async {
    try {
      final rates = await CurrencyService.fetchConversionRates();
      setState(() {
        conversionRates = rates; // Update the conversion rates in state
      });
    } catch (e) {
      print('Failed to fetch conversion rates: $e');
    }
  }

  // Convert the amount to the selected base currency with logging
  double convertToBaseCurrency(double amount, String currency) {
    print("Original Amount: $amount $currency");
    print("Selected base currency: $selectedBaseCurrency");

    // If the selected base currency is the same as the original currency, no conversion is needed
    if (currency == selectedBaseCurrency) {
      print(
          "Selected base currency is the same as the original currency. Amount remains: $amount");
      return amount;
    }

    // Convert to USD if needed
    double amountInUSD;
    if (currency != 'USD') {
      double rateToUSD = conversionRates[currency] ?? 1.0;
      amountInUSD = amount / rateToUSD; // Convert to USD
      print("Converted $amount $currency to USD: $amountInUSD");
    } else {
      amountInUSD = amount;
      print("Amount is already in USD: $amountInUSD");
    }

    // Convert from USD to the selected base currency (if it's not already USD)
    if (selectedBaseCurrency != 'USD') {
      double rateToBaseCurrency = conversionRates[selectedBaseCurrency] ?? 1.0;
      double convertedAmount = amountInUSD *
          rateToBaseCurrency; // Convert to the selected base currency
      print(
          "Converted $amountInUSD USD to $selectedBaseCurrency: $convertedAmount");
      return convertedAmount;
    } else {
      print("Selected base currency is USD. Amount remains: $amountInUSD");
      return amountInUSD; // No conversion needed if base currency is USD
    }
  }

  Future<void> fetchExpenseData() async {
    if (loggedInUser == null) return;

    try {
      if (selectedDateRange == null) {
        QuerySnapshot snapshot = await _firestore
            .collection('receipts')
            .where('userId', isEqualTo: loggedInUser?.email)
            .orderBy('date', descending: false)
            .get();

        if (snapshot.docs.isNotEmpty) {
          Timestamp earliestDate =
              snapshot.docs.first['date'] ?? Timestamp.now();
          Timestamp latestDate = snapshot.docs.last['date'] ?? Timestamp.now();

          setState(() {
            selectedDateRange = DateTimeRange(
              start: earliestDate.toDate(),
              end: latestDate.toDate(),
            );
          });
        }
      }

      QuerySnapshot snapshot = await _firestore
          .collection('receipts')
          .where('userId', isEqualTo: loggedInUser?.email)
          .where('date',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(selectedDateRange!.start))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.end))
          .get();

      Map<String, double> tempCategoryTotals = {};
      Set<String> categories = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String category = data['category'];
        double amount = (data['amount'] as num).toDouble();
        String currency = data['currency'];

        double convertedAmount = convertToBaseCurrency(amount, currency);

        categories.add(category);

        if (tempCategoryTotals.containsKey(category)) {
          tempCategoryTotals[category] =
              tempCategoryTotals[category]! + convertedAmount;
        } else {
          tempCategoryTotals[category] = convertedAmount;
        }
      }

      generateColorMapping(categories);

      setState(() {
        categoryTotals = tempCategoryTotals;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void generateColorMapping(Set<String> categories) {
    categoryColors.clear();
    int colorIndex = 0;

    for (var category in categories) {
      categoryColors[category] =
          availableColors[colorIndex % availableColors.length];
      colorIndex++;
    }
  }

  // Method to open the date range picker
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: selectedDateRange,
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        isLoading = true;
        fetchExpenseData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses Analysis'),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
          SizedBox(width: 16), // Add some space between the buttons
          DropdownButton<String>(
            value: selectedBaseCurrency,
            icon: Icon(Icons.money),
            onChanged: (String? newValue) {
              setState(() {
                selectedBaseCurrency = newValue!;
                isLoading = true;
                fetchExpenseData();
              });
            },
            items: availableCurrencies
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
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
                        'Expenses by Category in $selectedBaseCurrency',
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
        color: categoryColors[category],
        value: total,
        title:
            '${category}\n(${total.toStringAsFixed(2)} $selectedBaseCurrency)',
        radius: 70,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }
}
