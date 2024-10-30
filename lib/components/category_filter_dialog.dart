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
          Text(
            'Filter by Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView(
              children: [
                // Add the "Uncategorized" option
                CheckboxListTile(
                  title: Text('? Uncategorized'),
                  value: isUncategorizedSelected,
                  onChanged: (bool? isChecked) {
                    setState(() {
                      isUncategorizedSelected = isChecked ?? false;
                    });
                  },
                ),
                // Add the rest of the user-defined categories
                ...widget.userCategories.map((category) {
                  return CheckboxListTile(
                    title: Text(category['icon'] + ' ' + category['name']),
                    value: tempSelectedCategoryIds.contains(category['id']),
                    onChanged: (bool? isChecked) {
                      setState(() {
                        if (isChecked == true) {
                          tempSelectedCategoryIds.add(category['id']);
                        } else {
                          tempSelectedCategoryIds.remove(category['id']);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
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
