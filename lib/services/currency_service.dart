import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyService {
  static const String apiUrl = 'https://openexchangerates.org/api/latest.json';
  static const String apiKey =
      '993d0a7a5f4a49a5afd265505f2ee93c'; // Replace with your API key

  // Fetch the conversion rates from Open Exchange Rates API
  static Future<Map<String, double>> fetchConversionRates() async {
    final response = await http.get(Uri.parse('$apiUrl?app_id=$apiKey'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> rates = data['rates'];

      // Convert the rates to double safely
      Map<String, double> conversionRates = rates.map((key, value) {
        // Check if the value is an int and convert it to a double
        if (value is int) {
          return MapEntry(key, value.toDouble());
        } else if (value is double) {
          return MapEntry(key, value);
        } else {
          throw Exception("Unexpected type for rate value");
        }
      });

      return conversionRates; // Return the fetched conversion rates
    } else {
      throw Exception('Failed to load conversion rates');
    }
  }
}
