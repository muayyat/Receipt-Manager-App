import 'package:flutter/material.dart';

import '../logger.dart';
import '../services/budget_service.dart';

class AddBudgetWidget extends StatefulWidget {
  final String userId;
  final VoidCallback onBudgetAdded;

  const AddBudgetWidget({
    super.key,
    required this.userId,
    required this.onBudgetAdded,
  });

  @override
  AddBudgetWidgetState createState() => AddBudgetWidgetState();
}

class AddBudgetWidgetState extends State<AddBudgetWidget> {
  final BudgetService _budgetService = BudgetService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategoryId;
  double? _amount;
  String _currency = 'USD'; // Default currency
  String _period = 'monthly'; // Default period

  final List<String> _currencies = ['USD', 'EUR', 'JPY', 'GBP'];
  final List<String> _periodOptions = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category ID Input
            TextFormField(
              decoration: InputDecoration(labelText: 'Category ID'),
              onSaved: (value) => _selectedCategoryId = value,
              validator: (value) => value == null || value.isEmpty
                  ? 'Category ID is required'
                  : null,
            ),

            // Amount Input
            TextFormField(
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onSaved: (value) => _amount = double.tryParse(value ?? ''),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Amount is required';
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),

            // Currency Dropdown
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(labelText: 'Currency'),
              items: _currencies
                  .map((currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _currency = value!),
            ),

            // Period Dropdown
            DropdownButtonFormField<String>(
              value: _period,
              decoration: InputDecoration(labelText: 'Period'),
              items: _periodOptions
                  .map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _period = value!),
            ),

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _addBudget,
              child: Text('Add Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBudget() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await _budgetService.addOrUpdateBudget(
          widget.userId,
          _selectedCategoryId!,
          _amount!,
          _currency,
          _period,
        );

        widget
            .onBudgetAdded(); // Notify parent widget to refresh the budget list
        Navigator.of(context).pop(); // Close the dialog
      } catch (e) {
        logger.e("Error adding budget: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding budget. Please try again.')),
        );
      }
    }
  }
}
