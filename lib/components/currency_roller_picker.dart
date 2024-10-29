import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../logger.dart';
import '../services/currency_service.dart';

class CurrencyPicker extends StatefulWidget {
  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;

  const CurrencyPicker({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  CurrencyPickerState createState() => CurrencyPickerState();
}

class CurrencyPickerState extends State<CurrencyPicker> {
  String? tempSelectedCurrency;
  List<String> availableCurrencies = []; // Initialize as empty list

  @override
  void initState() {
    super.initState();
    tempSelectedCurrency =
        widget.selectedCurrency; // Initialize temporary value
    fetchCurrencyCodes(); // Fetch currencies when widget is initialized
  }

  Future<void> fetchCurrencyCodes() async {
    try {
      availableCurrencies = await CurrencyService.fetchCurrencyCodes();
      setState(() {}); // Update UI after fetching currency codes
    } catch (e) {
      logger.e('Failed to fetch available currencies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (availableCurrencies.isEmpty) {
      return Center(
          child: CircularProgressIndicator()); // Show loading indicator
    }

    int initialIndex = availableCurrencies.indexOf(widget.selectedCurrency);

    return Container(
      padding: EdgeInsets.all(16),
      height: 300, // Set an appropriate height for the picker
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Currency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: initialIndex == -1 ? 0 : initialIndex),
                    itemExtent: 32.0, // Height of each item
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        tempSelectedCurrency = availableCurrencies[index];
                      });
                    },
                    children: availableCurrencies
                        .map((currency) => Center(child: Text(currency)))
                        .toList(),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    if (tempSelectedCurrency != null) {
                      widget.onCurrencySelected(tempSelectedCurrency!);
                    }
                    Navigator.pop(context); // Close the picker
                  },
                  child: Text('DONE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
