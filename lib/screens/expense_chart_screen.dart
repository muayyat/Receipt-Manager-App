import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/calendar_filter_widget.dart';
import '../components/custom_drawer.dart';
import '../components/date_range_container.dart';
import '../components/rounded_button.dart';
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/currency_service.dart';
import '../services/receipt_service.dart';

class ExpenseChartScreen extends StatefulWidget {
  static const String id = 'expense_chart_screen';

  const ExpenseChartScreen({super.key});

  @override
  ExpenseChartScreenState createState() => ExpenseChartScreenState();
}

class ExpenseChartScreenState extends State<ExpenseChartScreen> {
  User? loggedInUser;

  final ReceiptService receiptService = ReceiptService();
  final CategoryService categoryService = CategoryService();

  bool isLoading = true;
  String selectedBaseCurrency = 'EUR';
  late List<String> availableCurrencies = [];

  // Set default dates
  DateTime? _startDate =
      DateTime(DateTime.now().year, 1, 1); // Start date: first day of the year
  DateTime? _endDate = DateTime.now(); // End date: today

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
  Map<String, Color> categoryColors = {};
  List<Map<String, dynamic>> userCategories = [];
  Map<String, double> categoryGroupedTotals = {};

  TimeInterval selectedInterval =
      TimeInterval.day; // Default time interval (day)
  Map<String, double> intervalGroupedTotals =
      {}; // Stores grouped expenses based on interval

  @override
  void initState() {
    super.initState();
    initializeData(); // Initialize the data properly
  }

  Future<void> initializeData() async {
    await getCurrentUser(); // Ensure the user is fetched first
    await fetchCategories(); // Fetch categories after getting the user
    fetchCurrencyCodes(); // These can run in parallel or after the user fetch
    fetchCategoryGroupedExpenseData(); // Fetch expense data
    fetchIntervalGroupedExpenseData(); // Fetch interval data
  }

  Future<void> getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
  }

  // Method to fetch and store the categories
  Future<void> fetchCategories() async {
    try {
      List<Map<String, dynamic>> fetchedCategories =
          await categoryService.fetchUserCategories(loggedInUser!.email!);

      setState(() {
        userCategories = fetchedCategories; // Store categories in state
        isLoading = false; // Stop loading spinner
      });
    } catch (e) {
      logger.e('Error fetching categories: $e');

      setState(() {
        isLoading = false; // Stop loading even if there's an error
      });
    }
  }

  Future<void> _showCalendarFilterDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return CalendarFilterWidget(
          initialStartDate: _startDate!,
          initialEndDate: _endDate!,
          onApply: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
            // Call the methods to refresh the data and charts
            fetchCategoryGroupedExpenseData(); // Refresh pie chart data
            fetchIntervalGroupedExpenseData(); // Refresh bar chart data
          },
        );
      },
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    int initialIndex = availableCurrencies.indexOf(selectedBaseCurrency);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 300, // Set an appropriate height for the picker
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 32.0, // Height of each item
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      selectedBaseCurrency = availableCurrencies[index];
                    });
                    // Call the methods to refresh the data and charts
                    fetchCategoryGroupedExpenseData(); // Refresh pie chart data
                    fetchIntervalGroupedExpenseData(); // Refresh bar chart data
                  },
                  children: availableCurrencies
                      .map((currency) => Center(child: Text(currency)))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> fetchCurrencyCodes() async {
    try {
      availableCurrencies = await CurrencyService.fetchCurrencyCodes();
      setState(() {}); // Update the UI after fetching currency codes
    } catch (e) {
      logger.e('Failed to fetch available currencies: $e');
    }
  }

  // Method to fetch and set categoryTotals using the groupReceiptsByCategory
  Future<void> fetchCategoryGroupedExpenseData() async {
    try {
      // Use the receipt service to get the category totals with the selected base currency
      Map<String, double> groupedExpenses =
          await receiptService.groupReceiptsByCategory(selectedBaseCurrency,
              _startDate!, _endDate!); // Use selectedBaseCurrency from state

      // Generate the color mapping for the categories
      generateColorMapping(groupedExpenses.keys.toSet());

      // Update the categoryTotals and refresh the UI
      setState(() {
        categoryGroupedTotals = groupedExpenses;
      });
    } catch (e) {
      logger.e('Error fetching category totals: $e');
    }
  }

  // Method to get category name by ID
  String getCategoryIconNameById(String categoryId) {
    final category = userCategories.firstWhere(
      (category) => category['id'] == categoryId,
      orElse: () => {
        'icon': '❓',
        'name': 'Uncategorized'
      }, // Return a default if not found
    );

    String categoryDisplay = category['icon'] + category['name'];

    return categoryDisplay;
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

  List<PieChartSectionData> getPieSections() {
    return categoryGroupedTotals.entries.map((entry) {
      final categoryId = entry.key;
      final total = entry.value;

      return PieChartSectionData(
        color: categoryColors[categoryId],
        value: total,
        title: '', // Set the title to empty
        radius: 70,
        titleStyle:
            TextStyle(fontSize: 0), // Set title style font size to 0 to hide it
      );
    }).toList();
  }

  // Method to build the pie chart
  Widget buildPieChart() {
    return Column(
      children: [
        SizedBox(
          height: 300, // Set a fixed height for the pie chart
          child: categoryGroupedTotals.isEmpty
              ? Center(child: Text('No data available.'))
              : PieChart(
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
          children: categoryGroupedTotals.entries.map((entry) {
            final total = entry.value;
            final percentage = (total /
                    categoryGroupedTotals.values
                        .fold(0, (sum, item) => sum + item)) *
                100;
            final categoryDisplay = getCategoryIconNameById(entry.key);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color:
                          categoryColors[entry.key], // Set the background color
                      borderRadius: BorderRadius.circular(
                          5), // Rounded corners (8 is just an example)
                    ),
                  ),
                  SizedBox(width: 8), // Space between color box and text
                  Text(
                    '$categoryDisplay: ${total.toStringAsFixed(2)} $selectedBaseCurrency (${percentage.toStringAsFixed(1)}%)',
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

  void fetchIntervalGroupedExpenseData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Call the groupReceiptsByInterval method based on the selected interval
      intervalGroupedTotals = await receiptService.groupReceiptsByInterval(
          selectedInterval, selectedBaseCurrency, _startDate!, _endDate!);
      setState(() {
        isLoading = false; // Data has been loaded
      });
    } catch (e) {
      logger.e('Error fetching grouped expense data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to handle the button click and update the selected interval
  void onIntervalSelected(TimeInterval interval) {
    setState(() {
      selectedInterval = interval;
      fetchIntervalGroupedExpenseData(); // Call your method when interval changes
    });
  }

  String getIntervalLabel(TimeInterval interval) {
    switch (interval) {
      case TimeInterval.day:
        return 'Daily';
      case TimeInterval.week:
        return 'Weekly';
      case TimeInterval.month:
        return 'Monthly';
      case TimeInterval.year:
        return 'Yearly';
      default:
        return '';
    }
  }

  List<BarChartGroupData> getBarChartGroups() {
    return intervalGroupedTotals.entries.map((entry) {
      final index = intervalGroupedTotals.keys.toList().indexOf(entry.key);
      final total = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            color: availableColors[
                index % availableColors.length], // Use available colors
            width: 22,
            borderRadius: BorderRadius.circular(1),
            // Add a label for the value above the bar
            rodStackItems: [
              BarChartRodStackItem(
                  0, total, availableColors[index % availableColors.length])
            ],
          ),
        ],
        // Show tooltip or indicator with value above the bar
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  Widget buildBarChart() {
    if (intervalGroupedTotals.isEmpty) {
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
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false, // Hide the top axis titles
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  // Display the interval (day, week, month, or year) as the title
                  final key =
                      intervalGroupedTotals.keys.elementAt(value.toInt());
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
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false, // Hide the left axis values
              ),
            ),
          ),
          barGroups: getBarChartGroups(),
          barTouchData: BarTouchData(
            // enabled: false,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                // Customize the tooltip text
                return BarTooltipItem(
                  rod.toY.toStringAsFixed(1), // Format the value displayed
                  const TextStyle(
                    color: Colors.black, // Tooltip text color
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
              getTooltipColor: (group) =>
                  Colors.transparent, // Set background color
              tooltipPadding:
                  const EdgeInsets.all(0), // Padding inside the tooltip
              tooltipMargin: 0, // Margin from the bar
            ),
          ),
        ),
      ),
    );
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
            SizedBox(height: 32),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Enable horizontal scrolling
              child: Container(
                width: MediaQuery.of(context).size.width *
                    1.5, // Adjust width as needed
                child: chart, // The chart will define the card size
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to capitalize the first letter of a string
  String capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Graphs'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: CustomDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DateRangeContainer(
                          startDate: _startDate!, // Your startDate
                          endDate: _endDate!, // Your endDate
                          onCalendarPressed:
                              _showCalendarFilterDialog, // Pass the calendar callback
                        ),
                        SizedBox(width: 16),
                        RoundedButton(
                          width: 80,
                          color: Colors.lightBlueAccent,
                          title:
                              selectedBaseCurrency, // Use the function to display descriptive text
                          onPressed: () {
                            _showCurrencyPicker(
                                context); // Show the picker when button is pressed
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20), // Space between controls and charts

                    // Pie Chart Card
                    buildCard(
                      context,
                      'Expenses by Category in $selectedBaseCurrency',
                      buildPieChart(), // Build the pie chart here
                    ),
                    SizedBox(
                        height: 20), // Space between pie chart and bar chart
                    // Row of buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: TimeInterval.values.map((interval) {
                        return RoundedButton(
                          width: 60,
                          color: selectedInterval == interval
                              ? Colors.blueAccent
                              : Colors.grey,
                          title: getIntervalLabel(
                              interval), // Use the function to display descriptive text
                          onPressed: () => onIntervalSelected(interval),
                        );
                      }).toList(),
                    ),
                    // Bar Chart Card
                    buildCard(
                      context,
                      'Expenses by ${capitalize(selectedInterval.toString().split('.').last)} in $selectedBaseCurrency',
                      buildBarChart(), // Build the bar chart here
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
