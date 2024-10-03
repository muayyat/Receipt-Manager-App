import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:receipt_manager/components/rounded_button.dart';

class AddCategoryWidget extends StatefulWidget {
  final String userId; // Add userId parameter
  final VoidCallback
      onCategoryAdded; // Callback to trigger after adding category

  AddCategoryWidget({required this.userId, required this.onCategoryAdded});

  @override
  _AddCategoryWidgetState createState() => _AddCategoryWidgetState();
}

class _AddCategoryWidgetState extends State<AddCategoryWidget> {
  String categoryName = '';
  String selectedIcon = '😊'; // Default icon
  bool showEmojiPicker = false; // Track whether to show emoji picker
  String? _errorMessage; // Error message for duplicate category names

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon selection
          GestureDetector(
            onTap: () {
              setState(() {
                showEmojiPicker = !showEmojiPicker; // Toggle emoji picker
              });
            },
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueAccent,
              child: Text(
                selectedIcon,
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Category name input field
          TextField(
            onChanged: (value) {
              setState(() {
                categoryName = value;
                _errorMessage = null; // Reset error when input changes
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Category name',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          // Display error message below the text field if exists
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(height: 20),
          // Show emoji picker if toggled
          if (showEmojiPicker)
            SizedBox(
              height: 250, // Adjust height as necessary
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    selectedIcon = emoji.emoji; // Update selected emoji
                  });
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  viewOrderConfig: const ViewOrderConfig(),
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.2
                            : 1.0),
                  ),
                ),
              ),
            ),
          // Add button
          RoundedButton(
            color: Colors.blueAccent,
            title: 'Add Category',
            onPressed: () async {
              if (categoryName.isNotEmpty) {
                // Check if the category exists
                bool categoryExists = await _categoryExists(categoryName);

                if (categoryExists) {
                  // Show error if category already exists
                  setState(() {
                    _errorMessage = "Category '$categoryName' already exists.";
                  });
                } else {
                  // Add category to Firestore if it doesn't exist
                  await addCategoryToFirestore(
                      widget.userId, categoryName, selectedIcon);

                  // Call the callback after adding category
                  widget.onCategoryAdded();

                  // Close the dialog
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Function to check if the category already exists
  Future<bool> _categoryExists(String name) async {
    try {
      // Get the user's categories from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        // Check if the category with the same name already exists
        return categoryList.any((category) =>
            category['name'].toString().toLowerCase() == name.toLowerCase());
      }
      return false;
    } catch (e) {
      print("Error checking if category exists: $e");
      return false;
    }
  }

  // Function to add a category to Firestore
  Future<void> addCategoryToFirestore(
      String userId, String name, String icon) async {
    try {
      // Add the new category to Firestore
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(userId)
          .update({
        'categorylist': FieldValue.arrayUnion([
          {'name': name, 'icon': icon}
        ]),
      });
    } catch (e) {
      print("Error adding category: $e");
    }
  }
}
