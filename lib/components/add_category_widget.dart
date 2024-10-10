import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:receipt_manager/components/rounded_button.dart';

import '../services/category_service.dart';

class AddCategoryWidget extends StatefulWidget {
  final String userId; // Add userId parameter
  final VoidCallback
      onCategoryAdded; // Callback to trigger after adding category

  const AddCategoryWidget(
      {super.key, required this.userId, required this.onCategoryAdded});

  @override
  AddCategoryWidgetState createState() => AddCategoryWidgetState();
}

class AddCategoryWidgetState extends State<AddCategoryWidget> {
  String categoryName = '';
  String selectedIcon = '😊'; // Default icon
  bool showEmojiPicker = false; // Track whether to show emoji picker
  String? _errorMessage; // Error message for duplicate category names

  final CategoryService _categoryService = CategoryService();

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
              // Move Navigator.pop(context) before any async operation
              if (mounted) {
                Navigator.pop(context); // Close the dialog immediately
              }

              if (categoryName.isNotEmpty) {
                // Check if the category exists
                bool categoryExists = await _categoryService.categoryExists(
                    widget.userId, categoryName);

                if (categoryExists) {
                  // Show error if category already exists
                  setState(() {
                    _errorMessage = "Category '$categoryName' already exists.";
                  });
                } else {
                  // Add category to Firestore if it doesn't exist
                  await _categoryService.addCategoryToFirestore(
                      widget.userId, categoryName, selectedIcon);

                  // Call the callback after adding category
                  widget.onCategoryAdded();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
