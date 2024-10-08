import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user categories
  Future<List<Map<String, dynamic>>> fetchUserCategories(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        // If the document does not exist, return an empty list
        return [];
      }

      var data = userDoc.data() as Map<String, dynamic>?;

      List<dynamic> categoryList = data?['categorylist'] ?? [];

      return categoryList
          .map((category) => {
                'id': category['id'] ?? '', // Add the random key (id)
                'name': category['name'] ?? 'Unknown',
                'icon': category['icon'] ?? '',
              })
          .toList();
    } catch (e) {
      print("Error fetching user categories: $e");
      return [];
    }
  }

  // Fetch category name and icon by category ID
  Future<Map<String, dynamic>?> fetchCategoryById(
      String userId, String categoryId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        // Find the category by its ID
        var category = categoryList.firstWhere(
            (category) => category['id'] == categoryId,
            orElse: () => null);

        if (category != null) {
          return {
            'name': category['name'] ?? 'Unknown',
            'icon': category['icon'] ?? ''
          };
        }
      }

      return null; // Return null if category not found
    } catch (e) {
      print("Error fetching category by ID: $e");
      return null;
    }
  }

  // Add a new category with a random key
  Future<void> addCategoryToFirestore(
      String userId, String name, String icon) async {
    try {
      // Generate a unique random key for the category
      String categoryId = _firestore.collection('categories').doc().id;

      await _firestore.collection('categories').doc(userId).update({
        'categorylist': FieldValue.arrayUnion([
          {
            'id': categoryId,
            'name': name,
            'icon': icon
          } // Store id along with name and icon
        ]),
      });
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  // Delete category by its random key (id)
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        // Find the category by its ID
        var categoryToDelete = categoryList.firstWhere(
            (category) => category['id'] == categoryId,
            orElse: () => null);

        if (categoryToDelete != null) {
          // Remove the category using FieldValue.arrayRemove
          await _firestore.collection('categories').doc(userId).update({
            'categorylist': FieldValue.arrayRemove([categoryToDelete])
          });
        }
      }
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  // Check if a category exists (by name) in the Firestore
  Future<bool> categoryExists(String userId, String categoryName) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        return categoryList.any((category) =>
            category['name'].toString().toLowerCase() ==
            categoryName.toLowerCase());
      }

      return false;
    } catch (e) {
      print("Error checking if category exists: $e");
      return false;
    }
  }

  // Fetch the icon by category name
  Future<String?> fetchIconByCategoryName(
      String userId, String categoryName) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        for (var category in categoryList) {
          if (category['name'].toString().toLowerCase() ==
              categoryName.toLowerCase()) {
            return category['icon'] ?? null;
          }
        }
      }

      return null; // Return null if category not found
    } catch (e) {
      print("Error fetching icon by category name: $e");
      return null;
    }
  }
}
