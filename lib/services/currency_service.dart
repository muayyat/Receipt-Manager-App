import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;

import '../logger.dart';

class CurrencyService {
  Map<String, double>? conversionRates;

  // Method to get the API key from Firebase Remote Config
  static Future<String> getApiKey() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    // Set default values for Remote Config
    await remoteConfig.setDefaults(<String, dynamic>{
      'API_KEY': 'default_api_key', // Provide a fallback API key or message
    });

    // Fetch the latest values from Firebase Remote Config
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      logger.e('Failed to fetch remote config: $e');
      // Optionally return a default or error message if needed
    }

    // Retrieve the API key from the Remote Config
    String apiKey = remoteConfig.getString('API_KEY');
    // Ensure we have a valid API key (fallback to default if not set)
    if (apiKey == 'default_api_key' || apiKey.isEmpty) {
      throw Exception('API key is not set in Remote Config');
    }

    return apiKey;
  }

  // Fetch the currency codes as a list
  static Future<List<String>> fetchCurrencyCodes() async {
    final String apiKey = await getApiKey();
    const String apiUrl = 'https://openexchangerates.org/api/currencies.json';

    try {
      final response = await http.get(Uri.parse('$apiUrl?app_id=$apiKey'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> currencies = json.decode(response.body);
        return currencies.keys.toList(); // Return the list of currency codes
      } else {
        throw Exception('Failed to load currency codes');
      }
    } catch (e) {
      throw Exception('Error fetching currency codes: $e');
    }
  }

  // Fetch conversion rates using the API key from Remote Config
  Future<void> fetchConversionRates() async {
    final String apiKey =
        await getApiKey(); // Get the API key from Remote Config
    const String apiUrl = 'https://openexchangerates.org/api/latest.json';

    try {
      final response = await http.get(Uri.parse('$apiUrl?app_id=$apiKey'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'];

        // Convert the rates to a Map<String, double>
        conversionRates = rates.map((key, value) {
          if (value is int) {
            return MapEntry(key, value.toDouble());
          } else if (value is double) {
            return MapEntry(key, value);
          } else {
            throw Exception("Unexpected type for rate value");
          }
        });
      } else {
        throw Exception('Failed to load conversion rates');
      }
    } catch (e) {
      logger.e('Error fetching conversion rates: $e');
      conversionRates = {};
    }
  }

  // Method to convert amount to the base currency
  Future<double> convertToBaseCurrency(
      double amount, String currency, String selectedBaseCurrency) async {
    // Ensure conversion rates are fetched
    if (conversionRates == null || conversionRates!.isEmpty) {
      await fetchConversionRates();
    }

    // If the amount is already in the base currency, return it as is
    if (currency == selectedBaseCurrency) {
      return amount;
    }

    double amountInUSD;

    // Convert from the original currency to USD first
    if (currency != 'USD') {
      double rateToUSD =
          conversionRates![currency] ?? 1.0; // Default to 1.0 if rate not found
      amountInUSD = amount / rateToUSD;
    } else {
      amountInUSD = amount;
    }

    // Convert from USD to the base currency
    if (selectedBaseCurrency != 'USD') {
      double rateToBaseCurrency = conversionRates![selectedBaseCurrency] ??
          1.0; // Default to 1.0 if rate not found
      return amountInUSD * rateToBaseCurrency;
    } else {
      return amountInUSD;
    }
  }
}
