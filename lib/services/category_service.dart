import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                'id': userDoc.id,
                'name': category['name'] ?? 'Unknown',
                'icon': category['icon'] ?? '',
              })
          .toList();
    } catch (e) {
      print("Error fetching user categories: $e");
      return [];
    }
  }

  Future<void> addCategoryToFirestore(
      String userId, String name, String icon) async {
    try {
      await _firestore.collection('categories').doc(userId).update({
        'categorylist': FieldValue.arrayUnion([
          {'name': name, 'icon': icon}
        ]),
      });
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  Future<void> deleteCategory(String userId, String name, String icon) async {
    try {
      await _firestore.collection('categories').doc(userId).update({
        'categorylist': FieldValue.arrayRemove([
          {'name': name, 'icon': icon}
        ]),
      });
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

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
}
