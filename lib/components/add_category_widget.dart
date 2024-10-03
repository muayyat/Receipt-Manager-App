import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:receipt_manager/components/rounded_button.dart';

class AddCategoryWidget extends StatefulWidget {
  final String userId; // Add userId parameter
  final Function(String name, String icon)
      onAdd; // Callback for adding a category

  AddCategoryWidget({required this.userId, required this.onAdd});

  @override
  _AddCategoryWidgetState createState() => _AddCategoryWidgetState();
}

class _AddCategoryWidgetState extends State<AddCategoryWidget> {
  String categoryName = '';
  String selectedIcon = '😊'; // Default icon
  bool showEmojiPicker = false; // Track whether to show emoji picker

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
                    // Issue: https://github.com/flutter/flutter/issues/28894
                    emojiSizeMax: 28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.2
                            : 1.0),
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(),
                  bottomActionBarConfig: const BottomActionBarConfig(),
                  searchViewConfig: const SearchViewConfig(),
                ),
              ),
            ),
          // Add button
          RoundedButton(
            color: Colors.blueAccent,
            title: 'Add Category',
            onPressed: () {
              if (categoryName.isNotEmpty) {
                // Call the onAdd callback and add to Firestore
                addCategoryToFirestore(
                    widget.userId, categoryName, selectedIcon);
                widget.onAdd(categoryName, selectedIcon); // Call the callback
                Navigator.pop(context); // Close the dialog
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> addCategoryToFirestore(
      String userId, String name, String icon) async {
    try {
      // Add the new category to the Firestore document for the user
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
