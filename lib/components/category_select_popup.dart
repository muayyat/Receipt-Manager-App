import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_category_widget.dart';

class CategorySelectPopup extends StatefulWidget {
  final String userId;

  CategorySelectPopup({required this.userId});

  @override
  _CategorySelectPopupState createState() => _CategorySelectPopupState();
}

class _CategorySelectPopupState extends State<CategorySelectPopup> {
  List<Map<String, dynamic>> userCategories = [];
  String? selectedCategory;

  // Define default categories
  final List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Food', 'icon': '🍔'},
    {'name': 'Gym', 'icon': '🏋️‍♂️'},
    {'name': 'Internet', 'icon': '📞'},
    {'name': 'Rent', 'icon': '🏡'},
    {'name': 'Subscriptions', 'icon': '🔄'},
    {'name': 'Transport', 'icon': '🚗'},
    {'name': 'Utilities', 'icon': '💡'},
    {'name': 'iPhone', 'icon': '📱'},
  ];

  @override
  void initState() {
    super.initState();
    fetchUserCategories();
  }

  Future<void> fetchUserCategories() async {
    try {
      // Check if the document exists for the user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.userId) // Assuming userId is the document ID
          .get();

      // Define the default categories
      List<Map<String, dynamic>> defaultCategories = [
        {'name': 'Food', 'icon': '🍔'},
        {'name': 'Gym', 'icon': '🏋️‍♂️'},
        {'name': 'Internet', 'icon': '📞'},
        {'name': 'Rent', 'icon': '🏡'},
        {'name': 'Subscriptions', 'icon': '🔄'},
        {'name': 'Transport', 'icon': '🚗'},
        {'name': 'Utilities', 'icon': '💡'},
        {'name': 'iPhone', 'icon': '📱'},
      ];

      if (!userDoc.exists) {
        // If the document does not exist, create it with the default categories
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.userId)
            .set({
          'categorylist': defaultCategories,
        });
        // Assign the default categories to userCategories
        setState(() {
          userCategories = defaultCategories;
        });
      } else {
        // If the document exists, check the category list
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        if (categoryList.isEmpty) {
          // If the list is empty, update it with the default categories
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(widget.userId)
              .update({
            'categorylist': defaultCategories,
          });
          // Assign the default categories to userCategories
          setState(() {
            userCategories = defaultCategories;
          });
        } else {
          // If the list is not empty, assign it to userCategories
          setState(() {
            userCategories = categoryList
                .map((category) => {
                      'id': userDoc
                          .id, // You might want to adjust how you store IDs
                      'name': category['name'] ?? 'Unknown',
                      'icon': category['icon'] ?? '',
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching user categories: $e");
    }
  }

  // Function to show the AddCategoryWidget dialog
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: AddCategoryWidget(
            userId: widget.userId,
            onAdd: (name, icon) {
              _addCategoryToFirestore(name, icon);
            },
          ),
        );
      },
    );
  }

  // Function to add a category to Firestore
  Future<void> _addCategoryToFirestore(String name, String icon) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.userId)
          .update({
        'categorylist': FieldValue.arrayUnion([
          {'name': name, 'icon': icon}
        ]),
      });
      fetchUserCategories(); // Refresh the categories
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    int indexToDelete =
        userCategories.indexWhere((category) => category['id'] == id);

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
      fetchUserCategories();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use userCategories if not empty, otherwise use defaultCategories
    userCategories =
        userCategories.isNotEmpty ? userCategories : defaultCategories;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.topCenter, // Center the content horizontally
        children: [
          Padding(
            padding: const EdgeInsets.all(20), // Adjusted for buttons
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wrap text and buttons in a Row for alignment
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Space between text and buttons
                  children: [
                    // Close button on the left
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400], // Light gray background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4.0,
                            offset: Offset(0, 2), // Shadow position
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close,
                            color: Colors.grey[600]), // Icon color
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    // Centered text
                    Text(
                      'Select Category',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // Add button on the right
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400], // Light gray background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4.0,
                            offset: Offset(0, 2), // Shadow position
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add,
                            color: Colors.grey[600]), // Icon color
                        onPressed: _showAddCategoryDialog,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Add some space below the text
                SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: userCategories.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Text(userCategories[index]['icon'] ?? '',
                            style: TextStyle(fontSize: 24)),
                        title: Text(userCategories[index]['name'] ?? 'Unknown'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
