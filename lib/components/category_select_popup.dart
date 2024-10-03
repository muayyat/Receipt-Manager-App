import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategorySelectPopup extends StatefulWidget {
  final String userId;

  CategorySelectPopup({required this.userId});

  @override
  _CategorySelectPopupState createState() => _CategorySelectPopupState();
}

class _CategorySelectPopupState extends State<CategorySelectPopup> {
  List<Map<String, dynamic>> userCategories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchUserCategories();
  }

  Future<void> fetchUserCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('userId', isEqualTo: widget.userId)
          .get();

      List<Map<String, dynamic>> categories = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        List<dynamic> categoryList =
            data['categorylist'] ?? []; // Ensure it's a list

        for (var category in categoryList) {
          categories.add({
            'id': doc.id,
            'name': category['name'] ?? 'Unknown', // Handle null case
            'icon': category['icon'] ?? '', // Handle null case
          });
        }
      }

      setState(() {
        userCategories = categories;
      });
    } catch (e) {
      print("Error fetching user categories: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    // Find the index of the category to delete
    int indexToDelete =
        userCategories.indexWhere((category) => category['id'] == id);

    // Remove the category locally for immediate feedback
    if (indexToDelete != -1) {
      setState(() {
        userCategories.removeAt(indexToDelete);
      });
    }

    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(id)
          .delete();

      // Optionally, fetch the updated categories again if needed
      fetchUserCategories();
    } catch (e) {
      print("Error deleting category: $e");
      // Optionally, you could add back the deleted category if the deletion fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Category',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: userCategories.isEmpty
          ? CircularProgressIndicator()
          : SizedBox(
              height: 400,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: userCategories.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Text(userCategories[index]['icon'] ?? '',
                        style: TextStyle(fontSize: 24)), // Handle null case
                    title: Text(userCategories[index]['name'] ??
                        'Unknown'), // Handle null case
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteCategory(userCategories[index]['id']);
                      },
                    ),
                    onTap: () {
                      setState(() {
                        selectedCategory = userCategories[index]['name'];
                      });
                      Navigator.pop(context, selectedCategory);
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
