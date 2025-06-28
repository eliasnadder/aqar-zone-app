import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'currency_rates';
  static const String _lastUpdateKey = 'currency_last_update';
  static const Duration _cacheExpiry = Duration(hours: 6); // Cache for 6 hours

  // Supported currencies for the real estate app
  static const List<String> supportedCurrencies = ['USD', 'AED', 'SYP'];

  // Currency symbols and names
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'AED': 'AED',
    'SYP': 'SYP',
  };

  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'AED': 'UAE Dirham',
    'SYP': 'Syrian Pound',
  };

  /// Get exchange rates for all supported currencies
  static Future<Map<String, double>> getExchangeRates({
    String baseCurrency = 'USD',
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first unless force refresh is requested
      if (!forceRefresh) {
        final cachedRates = await _getCachedRates(baseCurrency);
        if (cachedRates != null) {
          debugPrint('Using cached currency rates for $baseCurrency');
          return cachedRates;
        }
      }

      // Fetch fresh rates from API
      debugPrint('Fetching fresh currency rates for $baseCurrency');
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$baseCurrency'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success' || data['rates'] != null) {
          final rates = <String, double>{};

          // Add base currency
          rates[baseCurrency] = 1.0;

          // Add supported currencies
          for (String currency in supportedCurrencies) {
            if (currency != baseCurrency && data['rates'][currency] != null) {
              rates[currency] = (data['rates'][currency] as num).toDouble();
            }
          }

          // Cache the rates
          await _cacheRates(baseCurrency, rates);

          debugPrint('Successfully fetched rates: $rates');
          return rates;
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');

      // Try to return cached rates as fallback
      final cachedRates = await _getCachedRates(
        baseCurrency,
        ignoreExpiry: true,
      );
      if (cachedRates != null) {
        debugPrint('Using expired cached rates as fallback');
        return cachedRates;
      }

      // Return default rates if all else fails
      return _getDefaultRates(baseCurrency);
    }
  }

  /// Convert amount from one currency to another
  static Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    Map<String, double>? rates,
  }) async {
    try {
      // Validate inputs
      if (amount.isNaN || amount.isInfinite) {
        throw ArgumentError('Invalid amount: $amount');
      }

      if (fromCurrency.isEmpty || toCurrency.isEmpty) {
        throw ArgumentError('Currency codes cannot be empty');
      }

      if (fromCurrency == toCurrency) return amount;

      // Get rates if not provided
      rates ??= await getExchangeRates(baseCurrency: fromCurrency);

      if (rates.isEmpty) {
        throw Exception('No exchange rates available');
      }

      // The rates are fetched with fromCurrency as base
      // So fromCurrency has rate 1.0, and other currencies have rates relative to it
      // To convert FROM fromCurrency TO toCurrency, we multiply by the rate
      final rate = rates[toCurrency];
      if (rate != null && rate > 0 && rate.isFinite) {
        return amount * rate;
      }

      // If conversion fails, return original amount as fallback
      debugPrint('Currency conversion failed, returning original amount');
      return amount;
    } catch (e) {
      debugPrint('Error in currency conversion: $e');
      // Return original amount as safe fallback
      return amount;
    }
  }

  /// Format currency amount with proper symbol and formatting
  static String formatCurrency(double amount, String currency) {
    final symbol = currencySymbols[currency] ?? currency;

    // Format based on currency
    switch (currency) {
      case 'USD':
      case 'AED':
        if (amount >= 1000000) {
          return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
        } else if (amount >= 1000) {
          return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
        } else {
          return '$symbol${amount.toStringAsFixed(0)}';
        }

      case 'SYP':
        // SYP amounts are typically very large, so always use K/M format
        if (amount >= 1000000000) {
          return '$symbol${(amount / 1000000000).toStringAsFixed(1)}B';
        } else if (amount >= 1000000) {
          return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
        } else if (amount >= 1000) {
          return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
        } else {
          return '$symbol${amount.toStringAsFixed(0)}';
        }

      default:
        return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }

  /// Get currency name
  static String getCurrencyName(String currency) {
    return currencyNames[currency] ?? currency;
  }

  /// Cache rates locally
  static Future<void> _cacheRates(
    String baseCurrency,
    Map<String, double> rates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'base': baseCurrency,
        'rates': rates,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_cacheKey, json.encode(cacheData));
      debugPrint('Cached currency rates for $baseCurrency');
    } catch (e) {
      debugPrint('Error caching currency rates: $e');
    }
  }

  /// Get cached rates
  static Future<Map<String, double>?> _getCachedRates(
    String baseCurrency, {
    bool ignoreExpiry = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = data['timestamp'] as int;
        final cachedBase = data['base'] as String;

        // Check if cache is for the same base currency
        if (cachedBase != baseCurrency) return null;

        // Check if cache is still valid
        if (!ignoreExpiry) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (cacheAge > _cacheExpiry.inMilliseconds) {
            debugPrint('Currency cache expired');
            return null;
          }
        }

        final rates = Map<String, double>.from(
          (data['rates'] as Map).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        );

        return rates;
      }
    } catch (e) {
      debugPrint('Error reading cached currency rates: $e');
    }

    return null;
  }

  /// Get default rates as fallback
  static Map<String, double> _getDefaultRates(String baseCurrency) {
    debugPrint('Using default currency rates for $baseCurrency');

    // Default rates (approximate, for fallback only)
    const defaultRates = {
      'USD': {'USD': 1.0, 'AED': 3.67, 'SYP': 2500.0},
      'AED': {'USD': 0.27, 'AED': 1.0, 'SYP': 680.0},
      'SYP': {'USD': 0.0004, 'AED': 0.0015, 'SYP': 1.0},
    };

    return Map<String, double>.from(
      defaultRates[baseCurrency] ?? defaultRates['USD']!,
    );
  }

  /// Clear cached rates
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('Currency cache cleared');
    } catch (e) {
      debugPrint('Error clearing currency cache: $e');
    }
  }

  /// Check if rates are cached and valid
  static Future<bool> hasCachedRates(String baseCurrency) async {
    final rates = await _getCachedRates(baseCurrency);
    return rates != null;
  }

  /// Get last update time
  static Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = data['timestamp'] as int;
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Error getting last update time: $e');
    }

    return null;
  }
}
