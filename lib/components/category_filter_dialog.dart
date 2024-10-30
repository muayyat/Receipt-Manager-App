import 'package:flutter/material.dart';

class CategoryFilterDialog extends StatefulWidget {
  final List<String> initialSelectedCategoryIds;
  final bool initialIncludeUncategorized;
  final List<Map<String, dynamic>> userCategories;
  final Function(List<String> selectedCategoryIds, bool includeUncategorized)
      onApply;

  const CategoryFilterDialog({
    super.key,
    required this.initialSelectedCategoryIds,
    required this.initialIncludeUncategorized,
    required this.userCategories,
    required this.onApply,
  });

  @override
  CategoryFilterDialogState createState() => CategoryFilterDialogState();
}

class CategoryFilterDialogState extends State<CategoryFilterDialog> {
  late List<String> tempSelectedCategoryIds;
  late bool isUncategorizedSelected;

  @override
  void initState() {
    super.initState();
    tempSelectedCategoryIds = List.from(widget.initialSelectedCategoryIds);
    isUncategorizedSelected = widget.initialIncludeUncategorized;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount:
                  3, // Adjust the number of columns to your preference
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                // Add the "Uncategorized" option as a card
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isUncategorizedSelected = !isUncategorizedSelected;
                    });
                  },
                  child: Card(
                    color: isUncategorizedSelected
                        ? Colors.lightBlue
                        : Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '❓',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text('Uncategorized'),
                      ],
                    ),
                  ),
                ),
                // Add the rest of the user-defined categories as cards
                ...widget.userCategories.map((category) {
                  bool isSelected =
                      tempSelectedCategoryIds.contains(category['id']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          tempSelectedCategoryIds.remove(category['id']);
                        } else {
                          tempSelectedCategoryIds.add(category['id']);
                        }
                      });
                    },
                    child: Card(
                      color:
                          isSelected ? Colors.lightBlue : Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category['icon'],
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(category['name']),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              widget.onApply(tempSelectedCategoryIds, isUncategorizedSelected);
              Navigator.of(context).pop(); // Close the bottom sheet
            },
            child: Text('APPLY'),
          ),
        ],
      ),
    );
  }
}
