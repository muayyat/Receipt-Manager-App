import 'package:cloud_firestore/cloud_firestore.dart';

import '../logger.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all budgets for a user
  Future<List<Map<String, dynamic>>> fetchUserBudgets(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('budgets').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> budgetList = data['budgetlist'] ?? [];

        return budgetList.map((budget) {
          return {
            'categoryId': budget['categoryId'] ?? '',
            'amount': budget['amount'] ?? 0.0,
            'currency': budget['currency'] ?? 'USD',
            'period': budget['period'] ?? 'monthly',
          };
        }).toList();
      } else {
        // If the document doesn't exist, create a new one with an empty budget list
        await _firestore.collection('budgets').doc(userId).set({
          'budgetlist': [],
        });
        return []; // Return an empty list since there are no budgets yet
      }
    } catch (e) {
      logger.e("Error fetching user budgets: $e");
      return [];
    }
  }

  Future<void> updateUserBudgets(
      String userId, List<Map<String, dynamic>> budgetList) async {
    try {
      await _firestore.collection('budgets').doc(userId).update({
        'budgetlist': budgetList,
      });
    } catch (e) {
      logger.e("Error updating user budgets: $e");
      rethrow;
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

        // Find the specific budget by categoryId
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
                'period': budget['period'],
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
