import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../logger.dart';
import 'currency_service.dart';

final _firestore = FirebaseFirestore.instance;

enum TimeInterval { day, week, month, year }

class ReceiptService {
  User? loggedInUser;

  ReceiptService() {
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = FirebaseAuth.instance.currentUser;
  }

  // Fetch receipts for the current user
  Stream<DocumentSnapshot<Map<String, dynamic>>> fetchReceipts() {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection('receipts')
        .doc(loggedInUser!.email) // Use email or uid for user identification
        .snapshots();
  }

  Future<int> getReceiptCount() async {
    try {
      // Assuming each user has their own receipt document
      DocumentReference userDocRef =
          _firestore.collection('receipts').doc(loggedInUser!.email);

      DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        return 0; // Return 0 if no document is found
      }

      // Get the receipt list from Firestore
      List<dynamic> receiptList = userDoc['receiptlist'] ?? [];
      return receiptList.length;
    } catch (e) {
      throw Exception('Failed to fetch receipt count: $e');
    }
  }

  // Add a new receipt
  Future<void> addReceipt(Map<String, dynamic> receiptData) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    // Generate a unique ID for each receipt
    String receiptId =
        FirebaseFirestore.instance.collection('receipts').doc().id;

    // Add the receipt ID to the receipt data
    receiptData['id'] = receiptId;

    // Get the user document by userId or email
    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    await userDocRef.set({
      'receiptlist': FieldValue.arrayUnion([receiptData])
    }, SetOptions(merge: true));
  }

  // Update an existing receipt
  Future<void> updateReceipt(
      String receiptId, Map<String, dynamic> updatedData) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    // Get the user document by userId or email
    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    // Get the current receipt list
    List<dynamic> receiptList = userDoc['receiptlist'] ?? [];

    // Find the index of the receipt to update by its ID
    int receiptIndex =
        receiptList.indexWhere((receipt) => receipt['id'] == receiptId);

    if (receiptIndex != -1) {
      // Preserve the original ID
      updatedData['id'] = receiptId;

      // Replace the old receipt with the updated data (including the ID)
      receiptList[receiptIndex] = updatedData;

      // Update the receipt list in the document
      await userDocRef.update({'receiptlist': receiptList});
    } else {
      throw Exception('Receipt not found');
    }
  }

  // Delete a receipt by its index (assumes receipts are stored in an array)
  Future<void> deleteReceipt(String receiptId) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    // First, get the current receipt list
    DocumentSnapshot doc = await userDocRef.get();
    if (doc.exists) {
      List<dynamic> receiptList = doc['receiptlist'] ?? [];

      // Find the receipt and remove it
      receiptList.removeWhere((receipt) => receipt['id'] == receiptId);

      // Update the document with the new list
      await userDocRef.update({'receiptlist': receiptList});
    }
  }

  // Set categoryId to null for all receipts that match the given categoryId
  Future<void> setReceiptsCategoryToNull(String categoryId) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    // Fetch the user's receipts
    DocumentSnapshot doc = await userDocRef.get();
    if (doc.exists) {
      List<dynamic> receiptList = doc['receiptlist'] ?? [];

      // Iterate over the receipts and set categoryId to null for those with matching categoryId
      List<dynamic> updatedReceiptList = receiptList.map((receipt) {
        if (receipt['categoryId'] == categoryId) {
          receipt['categoryId'] = null; // Set the categoryId to null
        }
        return receipt;
      }).toList();

      // Update the Firestore document with the modified receipts
      await userDocRef.update({'receiptlist': updatedReceiptList});
    } else {
      throw Exception('No receipts found for the current user');
    }
  }

  // Group receipts by category with date filtering
  Future<Map<String, double>> groupReceiptsByCategory(
      String selectedBaseCurrency, DateTime startDate, DateTime endDate) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    // Get the receipt list
    List<dynamic> receiptList = userDoc['receiptlist'] ?? [];

    // Initialize the map to group expenses by category
    Map<String, double> groupedExpenses = {};

    // Move CurrencyService initialization outside the loop
    CurrencyService currencyService = CurrencyService();

    for (var receipt in receiptList) {
      Map<String, dynamic> receiptData = receipt as Map<String, dynamic>;
      String category = receiptData['categoryId'] ??
          'Uncategorized'; // Handle missing category
      String currency = receiptData['currency'];
      double amount = (receiptData['amount'] as num).toDouble();
      Timestamp timestamp = receiptData['date'];
      DateTime receiptDate = timestamp.toDate();

      // Check if the receipt date falls within the specified date range
      if (receiptDate.isBefore(startDate) || receiptDate.isAfter(endDate)) {
        continue; // Skip this receipt if it's outside the date range
      }

      // Convert the amount to the base currency
      double convertedAmount = await currencyService.convertToBaseCurrency(
          amount, currency, selectedBaseCurrency);

      // Aggregate the expenses by category
      if (groupedExpenses.containsKey(category)) {
        groupedExpenses[category] =
            groupedExpenses[category]! + convertedAmount;
      } else {
        groupedExpenses[category] = convertedAmount;
      }
    }

    return groupedExpenses;
  }

  int getWeekNumber(DateTime date) {
    // Get the first day of the year
    final firstDayOfYear = DateTime(date.year, 1, 1);

    // Calculate the number of days between the given date and the first day of the year
    int daysSinceFirstDay = date.difference(firstDayOfYear).inDays + 1;

    // Calculate the week number (integer division of days by 7, plus 1 to account for the first week)
    return (daysSinceFirstDay / 7).ceil();
  }

  // Group receipts by day, week, month, or year
  Future<Map<String, double>> groupReceiptsByInterval(TimeInterval interval,
      String selectedBaseCurrency, DateTime startDate, DateTime endDate) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    // Get the receipt list
    List<dynamic> receiptList = userDoc['receiptlist'] ?? [];

    // Debugging: Print the number of receipts found
    logger.i('Number of receipts: ${receiptList.length}');

    Map<String, double> groupedExpenses = {};

    CurrencyService currencyService = CurrencyService();

    for (var receipt in receiptList) {
      Map<String, dynamic> receiptData = receipt as Map<String, dynamic>;
      String currency = receiptData['currency'];
      double amount = (receiptData['amount'] as num).toDouble();
      Timestamp timestamp = receiptData['date'];
      DateTime receiptDate = timestamp.toDate();

      // Filter receipts based on the date range
      if (receiptDate.isBefore(startDate) || receiptDate.isAfter(endDate)) {
        continue; // Skip receipts that are outside the date range
      }

      // Generate a grouping key based on the selected interval
      String groupKey;
      switch (interval) {
        case TimeInterval.day:
          groupKey =
              DateFormat('yyyy-MM-dd').format(receiptDate); // Group by day
          break;
        case TimeInterval.week:
          int weekNumber =
              getWeekNumber(receiptDate); // Use the custom week calculation
          groupKey = '${receiptDate.year}-W$weekNumber'; // Group by week
          break;
        case TimeInterval.month:
          groupKey =
              DateFormat('yyyy-MM').format(receiptDate); // Group by month
          break;
        case TimeInterval.year:
          groupKey = DateFormat('yyyy').format(receiptDate); // Group by year
          break;
      }

      // Aggregate the expenses
      if (groupedExpenses.containsKey(groupKey)) {
        groupedExpenses[groupKey] = groupedExpenses[groupKey]! +
            await currencyService.convertToBaseCurrency(
                amount, currency, selectedBaseCurrency);
      } else {
        groupedExpenses[groupKey] = await currencyService.convertToBaseCurrency(
            amount, currency, selectedBaseCurrency);
      }
    }

    // Return the grouped expenses map after processing all receipts
    return groupedExpenses;
  }

  // Method to get the oldest and newest receipt dates
  Future<Map<String, DateTime>> getOldestAndNewestDates() async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    // Get the receipt list
    List<dynamic> receiptList = userDoc['receiptlist'] ?? [];

    if (receiptList.isEmpty) {
      throw Exception('No receipts found');
    }

    // Initialize variables to store the oldest and newest dates
    DateTime? oldestDate;
    DateTime? newestDate;

    for (var receipt in receiptList) {
      Map<String, dynamic> receiptData = receipt as Map<String, dynamic>;
      Timestamp timestamp = receiptData['date'];
      DateTime receiptDate = timestamp.toDate();

      // Initialize the oldest and newest dates if null
      if (oldestDate == null || receiptDate.isBefore(oldestDate)) {
        oldestDate = receiptDate;
      }
      if (newestDate == null || receiptDate.isAfter(newestDate)) {
        newestDate = receiptDate;
      }
    }

    // Return the oldest and newest dates as a map
    return {
      'oldest': oldestDate!,
      'newest': newestDate!,
    };
  }
}
