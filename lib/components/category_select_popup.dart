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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 50, horizontal: 20), // Adjusted for buttons
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select Category',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                userCategories.isEmpty
                    ? CircularProgressIndicator()
                    : SizedBox(
                        height: 400,
                        width: double.maxFinite,
                        child: ListView.builder(
                          itemCount: userCategories.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Text(userCategories[index]['icon'] ?? '',
                                  style: TextStyle(fontSize: 24)),
                              title: Text(
                                  userCategories[index]['name'] ?? 'Unknown'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () {
                                  deleteCategory(userCategories[index]['id']);
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  selectedCategory =
                                      userCategories[index]['name'];
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
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // Add your add category logic here
              },
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
