import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../components/currency_roller_picker.dart';
import '../components/custom_drawer.dart';
import '../components/date_range_container.dart';
import '../components/date_roller_picker.dart';
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
  Map<String, double> categoryGroupedTotals = {};
  Map<String, Map<String, String>> categoryNamesMap =
      {}; // To store category IDs, names, and icons

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

    // Fetch user categories directly from the service
    var userCategories =
        await categoryService.fetchUserCategories(loggedInUser!.email!);

    // Transform the list into a Map<String, Map<String, String>> format
    userCategories.forEach((category) {
      final id = category['id'] as String? ?? '';
      final name = category['name'] as String? ?? 'Uncategorized';
      final icon = category['icon'] as String? ?? '❓';

      // Only add to the map if the ID is not empty
      if (id.isNotEmpty) {
        categoryNamesMap[id] = {'name': name, 'icon': icon};
      }
    });

    setState(() {}); // Trigger rebuild with new categories

    // Run the rest of the methods in parallel
    await Future.wait([
      fetchCurrencyCodes(),
      fetchCategoryGroupedExpenseData(),
      fetchIntervalGroupedExpenseData(),
    ] as Iterable<Future>);
  }

  Future<void> getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CurrencyPicker(
          availableCurrencies: availableCurrencies,
          selectedCurrency: selectedBaseCurrency,
          onCurrencySelected: (String newCurrency) {
            setState(() {
              selectedBaseCurrency = newCurrency;
            });

            // Refresh your data after selection
            fetchCategoryGroupedExpenseData();
            fetchIntervalGroupedExpenseData();
          },
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

      // Sort the entries based on value in descending order
      List<MapEntry<String, double>> sortedEntries = groupedExpenses.entries
          .toList()
        ..sort((a, b) =>
            b.value.compareTo(a.value)); // Sort by value in descending order

      // Convert the sorted list of entries back into a map
      Map<String, double> sortedGroupedExpenses =
          Map.fromEntries(sortedEntries);

      // Generate the color mapping for the sorted categories
      generateColorMapping(sortedGroupedExpenses.keys.toSet());

      // Update the categoryTotals and refresh the UI
      setState(() {
        categoryGroupedTotals = sortedGroupedExpenses;
      });
    } catch (e) {
      logger.e('Error fetching category totals: $e');
    }
  }

// Method to get category icon and name by ID
  Future<String> getCategoryIconNameById(
      String userId, String categoryId) async {
    // Fetch the category name and icon asynchronously
    String? categoryName =
        await categoryService.fetchCategoryNameById(userId, categoryId);
    String? categoryIcon =
        await categoryService.fetchCategoryIconById(userId, categoryId);

    // Use default values if category name or icon is not found
    categoryName ??= 'Uncategorized';
    categoryIcon ??= '❓';

    // Concatenate icon and name
    String categoryDisplay = '$categoryIcon $categoryName';

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
        categoryGroupedTotals.isEmpty
            ? Center(child: Text('No data available.'))
            : SizedBox(
                height: 300, // Set a fixed height for the pie chart
                child: PieChart(
                  PieChartData(
                    sections: getPieSections(),
                    centerSpaceRadius: 60,
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0, // Set to 0 to remove the white gap
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

            // Access category details directly from categoryNamesMap
            var categoryDetails = categoryNamesMap[entry.key] ??
                {'name': 'Uncategorized', 'icon': '❓'};
            String? categoryName = categoryDetails['name'];
            String? categoryIcon = categoryDetails['icon'];
            String categoryDisplay =
                '$categoryIcon $categoryName'; // Combine icon and name
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: categoryColors[entry.key],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        '$categoryDisplay: ${total.toStringAsFixed(2)} $selectedBaseCurrency (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.left,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        )
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

      // Sort the intervalGroupedTotals by date (assuming the keys are date strings)
      List<MapEntry<String, double>> sortedEntries =
          intervalGroupedTotals.entries.toList()
            ..sort((a, b) {
              DateTime aDate =
                  DateTime.parse(a.key); // Assuming keys are date strings
              DateTime bDate = DateTime.parse(b.key);
              return aDate.compareTo(bDate);
            });

      // Convert sorted list back to a map
      intervalGroupedTotals = Map.fromEntries(sortedEntries);

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

  double getMaxYValue() {
    // Find the maximum value in the dataset and add some margin (e.g., 10%)
    double maxY = intervalGroupedTotals.values
        .fold(0, (prev, next) => prev > next ? prev : next);
    return maxY * 1.1; // Increase the maxY by 10%
  }

  Widget buildBarChart() {
    if (intervalGroupedTotals.isEmpty) {
      return Center(child: Text('No data available.'));
    }

    // Calculate the width dynamically based on the number of bar groups
    double chartWidth = intervalGroupedTotals.length *
        100.0; // Adjust 50.0 as per your bar width

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 350, // Set the minimum width
          maxWidth: double.infinity, // You can set the maximum width as needed
        ),
        child: SizedBox(
          width: chartWidth, // Set dynamic width for scrolling
          height: 300, // Set a fixed height for the bar chart
          child: BarChart(
            BarChartData(
              maxY:
                  getMaxYValue(), // Set maxY to a value slightly more than the largest data point
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
            chart, // The chart will define the card size
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
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize
                            .min, // Ensure the row takes the minimum width needed
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Center the items within the row
                        children: [
                          DateRangeContainer(
                            startDate: _startDate!, // Your startDate
                            endDate: _endDate!, // Your endDate
                            onCalendarPressed:
                                _showCalendarFilterDialog, // Pass the calendar callback
                          ),
                          SizedBox(width: 16),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors
                                  .transparent, // No background color for outlined look
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    8.0), // Same border radius as the date range picker
                                side: BorderSide(
                                    color: Colors
                                        .lightBlue), // Border color and width
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14), // Match padding
                            ),
                            onPressed: () {
                              _showCurrencyPicker(
                                  context); // Show the currency picker when button is pressed
                            },
                            child: Text(
                              selectedBaseCurrency,
                              style: TextStyle(
                                color: Colors
                                    .lightBlue, // Text color similar to date range picker
                                fontSize:
                                    16, // Match font size with DateRangeContainer
                              ),
                            ),
                          ),
                        ],
                      ),
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
