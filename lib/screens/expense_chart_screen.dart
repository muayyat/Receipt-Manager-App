import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../components/custom_drawer.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../services/receipt_service.dart';

class ExpenseChartScreen extends StatefulWidget {
  static const String id = 'expense_chart_screen';

  @override
  _ExpenseChartScreenState createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  User? loggedInUser;

  Map<String, double> categoryTotals = {};
  Map<String, Color> categoryColors = {};
  bool isLoading = true;
  String selectedBaseCurrency = 'EUR';
  late List<String> availableCurrencies = [];
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

  DateTimeRange? selectedDateRange;
  final ReceiptService receiptService = ReceiptService();

  Map<String, double> groupedExpenses =
      {}; // Stores grouped expenses based on interval
  TimeInterval selectedInterval =
      TimeInterval.day; // Default time interval (day)

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchExpenseData(); // Fetch expense data after getting the user
    fetchConversionRates();
    fetchCurrencyCodes();
    fetchGroupedExpenseData(); // Fetch data for the default interval (day)
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

  Future<void> fetchCurrencyCodes() async {
    try {
      availableCurrencies = await CurrencyService.fetchCurrencyCodes();
      setState(() {}); // Update the UI after fetching currency codes
    } catch (e) {
      print('Failed to fetch available currencies: $e');
    }
  }

  Map<String, double> conversionRates = {
    'USD': 0.85,
    'EUR': 1.0,
    'GBP': 1.17,
  };

  Future<void> fetchConversionRates() async {
    try {
      final rates = await CurrencyService.fetchConversionRates();
      setState(() {
        conversionRates = rates;
      });
    } catch (e) {
      print('Failed to fetch conversion rates: $e');
    }
  }

  // Fetch expense data using ReceiptService
  void fetchExpenseData() async {
    try {
      // Listen to the receipts stream
      receiptService.fetchReceipts().listen((userDoc) {
        if (!userDoc.exists) return;

        List<dynamic> receiptList =
            userDoc.get('receiptlist') as List<dynamic>? ?? [];

        Map<String, double> tempCategoryTotals = {};
        Set<String> categories = {};

        for (var receipt in receiptList) {
          Map<String, dynamic> receiptData = receipt as Map<String, dynamic>;
          Timestamp date = receiptData['date'];
          double amount = (receiptData['amount'] as num).toDouble();
          String currency = receiptData['currency'];

          if (selectedDateRange != null) {
            DateTime receiptDate = date.toDate();
            if (receiptDate.isBefore(selectedDateRange!.start) ||
                receiptDate.isAfter(selectedDateRange!.end)) {
              continue; // Skip this receipt if it's outside the date range
            }
          }

          double convertedAmount = CurrencyService.convertToBaseCurrency(
              amount, currency, selectedBaseCurrency, conversionRates);

          String category = receiptData['category'];

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
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void fetchGroupedExpenseData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Call the groupReceiptsByInterval method based on the selected interval
      groupedExpenses =
          await receiptService.groupReceiptsByInterval(selectedInterval);
      setState(() {
        isLoading = false; // Data has been loaded
      });
    } catch (e) {
      print('Error fetching grouped expense data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildBarChart() {
    if (groupedExpenses.isEmpty) {
      return Center(
          child: Text('No data available for the selected interval.'));
    }

    return SizedBox(
      height: 300, // Set a fixed height for the bar chart
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  // Display the interval (day, week, month, or year) as the title
                  final key = groupedExpenses.keys.elementAt(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      key, // Display the grouped interval as the label
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
                reservedSize: 42,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toString(),
                    style: TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          barGroups: getBarChartGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> getBarChartGroups() {
    return groupedExpenses.entries.map((entry) {
      final index = groupedExpenses.keys.toList().indexOf(entry.key);
      final total = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            color: availableColors[
                index % availableColors.length], // Use available colors
            width: 22,
          ),
        ],
      );
    }).toList();
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

  // Method to build the card with gray background
  Widget buildCard(BuildContext context, String title, Widget chart) {
    return Card(
      color: Colors.grey[200], // Set the background color to light grey
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Optional: rounded corners
      ),
      elevation: 4, // Optional: give the card a shadow
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Add padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            chart, // The chart will define the card size
          ],
        ),
      ),
    );
  }

  // Method to build the pie chart
  Widget buildPieChart() {
    return Column(
      children: [
        SizedBox(
          height: 300, // Set a fixed height for the pie chart
          child: PieChart(
            PieChartData(
              sections: getPieSections(),
              centerSpaceRadius: 60,
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              startDegreeOffset: -90,
            ),
          ),
        ),
        SizedBox(height: 20), // Space between the chart and the legend
        // Custom Legend
        Wrap(
          spacing: 10,
          children: categoryTotals.entries.map((entry) {
            final total = entry.value;
            final percentage = (total /
                    categoryTotals.values.fold(0, (sum, item) => sum + item)) *
                100;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: categoryColors[entry.key],
                  ),
                  SizedBox(width: 8), // Space between color box and text
                  Text(
                    '${entry.key}: ${total.toStringAsFixed(2)} $selectedBaseCurrency (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> getPieSections() {
    double totalAmount =
        categoryTotals.values.fold(0, (sum, item) => sum + item);

    return categoryTotals.entries.map((entry) {
      final category = entry.key;
      final total = entry.value;

      return PieChartSectionData(
        color: categoryColors[category],
        value: total,
        title: '', // Set the title to empty
        radius: 70,
        titleStyle:
            TextStyle(fontSize: 0), // Set title style font size to 0 to hide it
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Summary'),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
          SizedBox(width: 16),
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
          DropdownButton<TimeInterval>(
            value: selectedInterval,
            icon: Icon(Icons.filter_alt),
            onChanged: (TimeInterval? newValue) {
              setState(() {
                selectedInterval = newValue!;
                fetchGroupedExpenseData(); // Fetch data for the newly selected interval
              });
            },
            items: TimeInterval.values
                .map<DropdownMenuItem<TimeInterval>>((TimeInterval value) {
              return DropdownMenuItem<TimeInterval>(
                value: value,
                child: Text(value
                    .toString()
                    .split('.')
                    .last), // Display "day", "week", etc.
              );
            }).toList(),
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : categoryTotals.isEmpty
              ? Center(child: Text('No data available.'))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Pie Chart Card
                        buildCard(
                          context,
                          'Expenses by Category in $selectedBaseCurrency',
                          buildPieChart(), // Build the pie chart here
                        ),
                        SizedBox(
                            height:
                                20), // Space between pie chart and bar chart

                        // Bar Chart Card
                        buildCard(
                          context,
                          'Expenses by ${selectedInterval.toString().split('.').last} in $selectedBaseCurrency',
                          buildBarChart(), // Build the bar chart here
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
