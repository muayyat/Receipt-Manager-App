import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CurrencyPicker extends StatefulWidget {
  final List<String> availableCurrencies;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;

  const CurrencyPicker({
    super.key,
    required this.availableCurrencies,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  CurrencyPickerState createState() => CurrencyPickerState();
}

class CurrencyPickerState extends State<CurrencyPicker> {
  String? tempSelectedCurrency;

  @override
  void initState() {
    super.initState();
    tempSelectedCurrency =
        widget.selectedCurrency; // Initialize temporary value
  }

  @override
  Widget build(BuildContext context) {
    int initialIndex =
        widget.availableCurrencies.indexOf(widget.selectedCurrency);

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
                    scrollController:
                        FixedExtentScrollController(initialItem: initialIndex),
                    itemExtent: 32.0, // Height of each item
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        tempSelectedCurrency =
                            widget.availableCurrencies[index];
                      });
                    },
                    children: widget.availableCurrencies
                        .map((currency) => Center(child: Text(currency)))
                        .toList(),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    widget.onCurrencySelected(tempSelectedCurrency!);
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
