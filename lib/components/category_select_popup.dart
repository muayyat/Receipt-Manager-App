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
          .doc(widget.userId)
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

      // If the document does not exist, create it with the default categories
      if (!userDoc.exists || userDoc.data() == null) {
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
        // Safely handle the case where userDoc.data() is not a Map<String, dynamic>
        var data = userDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          List<dynamic> categoryList = data['categorylist'] ?? [];

          setState(() {
            userCategories = categoryList
                .map((category) => {
                      'id': userDoc.id, // Assuming user ID is the document ID
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
            onCategoryAdded: () {
              // Refresh categories when a new category is added
              fetchUserCategories();
            },
          ),
        );
      },
    );
  }

  Future<void> deleteCategory(String name) async {
    try {
      // Find the category that matches the name
      var categoryToRemove = userCategories.firstWhere(
        (category) => category['name'] == name,
        orElse: () => <String, dynamic>{},
      );

      if (categoryToRemove != null) {
        // Remove the category from Firestore first
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.userId)
            .update({
          'categorylist': FieldValue.arrayRemove([
            {
              'name': name,
              'icon': categoryToRemove['icon'], // Use the correct icon value
            }
          ])
        });

        // Once Firestore is updated, remove it locally
        setState(() {
          userCategories.removeWhere((category) => category['name'] == name);
        });

        print("has deleted category: $name");

        fetchUserCategories();
      } else {
        print("Category not found locally: $name");
      }
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      String categoryName =
                          userCategories[index]['name']?.trim() ??
                              ''; // Safely get and trim category name

                      // Debugging print statement
                      print(
                          'Category: $categoryName, Selected: ${selectedCategory?.trim() ?? ''}');

                      bool isSelected = categoryName ==
                          (selectedCategory?.trim() ??
                              ''); // Compare trimmed values

                      return Container(
                        color: isSelected
                            ? Colors.lightBlue.withOpacity(0.2)
                            : null, // Highlight selected row
                        child: ListTile(
                          leading: Text(userCategories[index]['icon'] ?? '',
                              style: TextStyle(fontSize: 24)),
                          title: Text(
                            categoryName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight
                                      .normal, // Make text bold if selected
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              deleteCategory(userCategories[index]['name']);
                            },
                          ),
                          onTap: () {
                            setState(() {
                              selectedCategory =
                                  categoryName; // Update selected category
                            });
                            Navigator.pop(context,
                                selectedCategory); // Return selected category
                          },
                        ),
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
