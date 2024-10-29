import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../logger.dart';
import '../services/currency_service.dart';

class CurrencyPicker extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;

  const CurrencyPicker({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  Future<List<String>> fetchCurrencyCodes() async {
    try {
      return await CurrencyService.fetchCurrencyCodes();
    } catch (e) {
      logger.e('Failed to fetch available currencies: $e');
      return []; // Return an empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchCurrencyCodes(),
      builder: (context, snapshot) {
        final List<String> defaultCodelist = [
          'AED',
          'AFN',
          'ALL',
          'AMD',
          'ANG',
          'AOA',
          'ARS',
          'AUD',
          'AWG',
          'AZN',
          'BAM',
          'BBD',
          'BDT',
          'BGN',
          'BHD',
          'BIF',
          'BMD',
          'BND',
          'BOB',
          'BRL',
          'BSD',
          'BTC',
          'BTN',
          'BWP',
          'BYN',
          'BZD',
          'CAD',
          'CDF',
          'CHF',
          'CLF',
          'CLP',
          'CNH',
          'CNY',
          'COP',
          'CRC',
          'CUC',
          'CUP',
          'CVE',
          'CZK',
          'DJF',
          'DKK',
          'DOP',
          'DZD',
          'EGP',
          'ERN',
          'ETB',
          'EUR',
          'FJD',
          'FKP',
          'GBP',
          'GEL',
          'GGP',
          'GHS',
          'GIP',
          'GMD',
          'GNF',
          'GTQ',
          'GYD',
          'HKD',
          'HNL',
          'HRK',
          'HTG',
          'HUF',
          'IDR',
          'ILS',
          'IMP',
          'INR',
          'IQD',
          'IRR',
          'ISK',
          'JEP',
          'JMD',
          'JOD',
          'JPY',
          'KES',
          'KGS',
          'KHR',
          'KMF',
          'KPW',
          'KRW',
          'KWD',
          'KYD',
          'KZT',
          'LAK',
          'LBP',
          'LKR',
          'LRD',
          'LSL',
          'LYD',
          'MAD',
          'MDL',
          'MGA',
          'MKD',
          'MMK',
          'MNT',
          'MOP',
          'MRU',
          'MUR',
          'MVR',
          'MWK',
          'MXN',
          'MYR',
          'MZN',
          'NAD',
          'NGN',
          'NIO',
          'NOK',
          'NPR',
          'NZD',
          'OMR',
          'PAB',
          'PEN',
          'PGK',
          'PHP',
          'PKR',
          'PLN',
          'PYG',
          'QAR',
          'RON',
          'RSD',
          'RUB',
          'RWF',
          'SAR',
          'SBD',
          'SCR',
          'SDG',
          'SEK',
          'SGD',
          'SHP',
          'SLL',
          'SOS',
          'SRD',
          'SSP',
          'STD',
          'STN',
          'SVC',
          'SYP',
          'SZL',
          'THB',
          'TJS',
          'TMT',
          'TND',
          'TOP',
          'TRY',
          'TTD',
          'TWD',
          'TZS',
          'UAH',
          'UGX',
          'USD',
          'UYU',
          'UZS',
          'VEF',
          'VES',
          'VND',
          'VUV',
          'WST',
          'XAF',
          'XAG',
          'XAU',
          'XCD',
          'XDR',
          'XOF',
          'XPD',
          'XPF',
          'XPT',
          'YER',
          'ZAR',
          'ZMW',
          'ZWL'
        ];

        // Use a default list until data loads
        final List<String> currencyList =
            snapshot.hasData && snapshot.data!.isNotEmpty
                ? snapshot.data!
                : defaultCodelist; // Default currencies

        int initialIndex = currencyList.indexOf(selectedCurrency);
        if (initialIndex == -1) initialIndex = 0;

        // Track the selected currency locally
        String currentSelectedCurrency = currencyList[initialIndex];

        return Container(
          padding: EdgeInsets.all(16),
          height: 300,
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
                          initialItem: initialIndex == -1 ? 0 : initialIndex,
                        ),
                        itemExtent: 32.0,
                        onSelectedItemChanged: (int index) {
                          currentSelectedCurrency = currencyList[index];
                        },
                        children: currencyList
                            .map((currency) => Center(child: Text(currency)))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        // Call onCurrencySelected when DONE is pressed
                        onCurrencySelected(currentSelectedCurrency);
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
      },
    );
  }
}
