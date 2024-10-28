import 'package:cloud_firestore/cloud_firestore.dart';

import '../logger.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user budgets
  Future<List<Map<String, dynamic>>> fetchUserBudgets(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('budgets').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> budgetList = data['budgetlist'] ?? [];

        return budgetList
            .map((budget) => {
                  'categoryId': budget['categoryId'] ?? '',
                  'amount': budget['amount'] ?? 0,
                  'currency': budget['currency'] ?? 'USD',
                  'period':
                      budget['period'] ?? 'monthly' // Default to 'monthly'
                })
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      logger.e("Error fetching user budgets: $e");
      return [];
    }
  }

  // Add or Update budget for a specific category
  Future<void> addOrUpdateBudget(String userId, String categoryId,
      double amount, String currency, String period) async {
    try {
      DocumentReference userDocRef =
          _firestore.collection('budgets').doc(userId);

      // Fetch the user's document
      DocumentSnapshot userDoc = await userDocRef.get();

      // Define the new budget data
      Map<String, dynamic> newBudget = {
        'categoryId': categoryId,
        'amount': amount,
        'currency': currency,
        'period':
            period, // Accept period as a String (e.g., 'daily', 'monthly')
      };

      if (!userDoc.exists) {
        // If the document doesn't exist, create it and initialize budgetlist with the new budget
        await userDocRef.set({
          'budgetlist': [newBudget],
        });
      } else {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> budgetList = data['budgetlist'] ?? [];

        // Check if budget for categoryId exists
        var existingBudgetIndex = budgetList
            .indexWhere((budget) => budget['categoryId'] == categoryId);

        if (existingBudgetIndex != -1) {
          // Update existing budget
          budgetList[existingBudgetIndex] = newBudget;
        } else {
          // Add new budget
          budgetList.add(newBudget);
        }

        await userDocRef.update({'budgetlist': budgetList});
      }
    } catch (e) {
      logger.e("Error adding/updating budget: $e");
    }
  }

  // Fetch budget by category ID
  Future<Map<String, dynamic>?> fetchBudgetByCategoryId(
      String userId, String categoryId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('budgets').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> budgetList = data['budgetlist'] ?? [];

        // Find the budget by categoryId
        var budget = budgetList.firstWhere(
          (budget) => budget['categoryId'] == categoryId,
          orElse: () {
            logger.w('Budget with categoryId $categoryId not found.');
            return null;
          },
        );

        return budget != null
            ? {
                'categoryId': budget['categoryId'],
                'amount': budget['amount'],
                'currency': budget['currency'],
                'period': budget['period']
              }
            : null;
      }

      return null;
    } catch (e) {
      logger.e("Error fetching budget by categoryId: $e");
      return null;
    }
  }
}
