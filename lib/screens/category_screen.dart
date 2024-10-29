import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/add_category_widget.dart';
import '../components/custom_drawer.dart';
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/receipt_service.dart';

class CategoryScreen extends StatefulWidget {
  static const String id = 'category_screen';

  const CategoryScreen({super.key});

  @override
  CategoryScreenState createState() => CategoryScreenState();
}

class CategoryScreenState extends State<CategoryScreen> {
  User? loggedInUser;

  List<Map<String, dynamic>> userCategories = [];
  String? selectedCategoryId;

  final ReceiptService receiptService = ReceiptService();

  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = await AuthService.getCurrentUser();
    if (loggedInUser != null) {
      fetchUserCategories(); // Call fetchUserCategories only after loggedInUser is assigned.
    }
  }

  Future<void> fetchUserCategories() async {
    try {
      List<Map<String, dynamic>> categories =
          await _categoryService.fetchUserCategories(loggedInUser!.email!);

      setState(() {
        userCategories = categories;
      });
    } catch (e) {
      logger.e("Error fetching user categories: $e");
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
            userId: loggedInUser!.email!,
            onCategoryAdded: () {
              // Refresh categories when a new category is added
              fetchUserCategories();
            },
          ),
        );
      },
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      var categoryToRemove = userCategories.firstWhere(
        (category) => category['id'] == categoryId,
        orElse: () => <String, dynamic>{},
      );

      if (categoryToRemove.isNotEmpty) {
        bool? confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Category'),
              content: Text(
                  'If you delete this category, the receipts belonging to it will have a null category value. Are you sure you want to delete this category?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Cancel the deletion
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Confirm deletion
                  },
                  child:
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        );

        if (confirmDelete == true) {
          await _categoryService.deleteCategory(
              loggedInUser!.email!, categoryId);
          await receiptService.setReceiptsCategoryToNull(categoryId);
          setState(() {
            userCategories
                .removeWhere((category) => category['id'] == categoryId);
          });
          fetchUserCategories();
        }
      }
    } catch (e) {
      logger.e("Error deleting category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Categories'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: userCategories.length,
                itemBuilder: (context, index) {
                  String categoryId = userCategories[index]['id'] ?? '';
                  String categoryName =
                      userCategories[index]['name']?.trim() ?? '';
                  bool isSelected = categoryId == selectedCategoryId;

                  return Container(
                    color: isSelected
                        ? Colors.lightBlue.withOpacity(0.2)
                        : null, // Highlight selected row
                    child: ListTile(
                      leading: Text(userCategories[index]['icon'] ?? '',
                          style: TextStyle(fontSize: 26)),
                      title: Text(
                        categoryName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          deleteCategory(categoryId);
                        },
                      ),
                      onTap: () {
                        setState(() {
                          selectedCategoryId = categoryId;
                        });
                        Navigator.pop(context, selectedCategoryId);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.lightBlueAccent,
        elevation: 6,
        child: Icon(Icons.add),
      ),
    );
  }
}
