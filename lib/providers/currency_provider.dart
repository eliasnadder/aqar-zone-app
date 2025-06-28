import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/currency_service.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _selectedCurrencyKey = 'selected_currency';

  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {};
  bool _isLoading = false;
  DateTime? _lastUpdate;
  String? _error;

  // Getters
  String get selectedCurrency => _selectedCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;
  String? get error => _error;

  String get selectedCurrencySymbol =>
      CurrencyService.getCurrencySymbol(_selectedCurrency);

  String get selectedCurrencyName =>
      CurrencyService.getCurrencyName(_selectedCurrency);

  CurrencyProvider() {
    _loadSelectedCurrency();
    _loadExchangeRates();
  }

  /// Load saved currency preference
  Future<void> _loadSelectedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString(_selectedCurrencyKey);

      if (savedCurrency != null &&
          CurrencyService.supportedCurrencies.contains(savedCurrency)) {
        _selectedCurrency = savedCurrency;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading selected currency: $e');
    }
  }

  /// Save currency preference
  Future<void> _saveSelectedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCurrencyKey, _selectedCurrency);
    } catch (e) {
      debugPrint('Error saving selected currency: $e');
    }
  }

  /// Change selected currency
  Future<void> setSelectedCurrency(String currency) async {
    if (!CurrencyService.supportedCurrencies.contains(currency)) {
      throw ArgumentError('Unsupported currency: $currency');
    }

    if (_selectedCurrency != currency) {
      final oldCurrency = _selectedCurrency;

      // Set loading state
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        // Update selected currency
        _selectedCurrency = currency;
        await _saveSelectedCurrency();

        // Reload exchange rates with new base currency
        await _loadExchangeRates(forceRefresh: true);

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        // Revert currency change on error
        _selectedCurrency = oldCurrency;
        _isLoading = false;
        _error = 'Failed to change currency: ${e.toString()}';
        notifyListeners();
        rethrow;
      }
    }
  }

  /// Load exchange rates
  Future<void> _loadExchangeRates({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final rates = await CurrencyService.getExchangeRates(
        baseCurrency: _selectedCurrency,
        forceRefresh: forceRefresh,
      );

      _exchangeRates = rates;
      _lastUpdate = await CurrencyService.getLastUpdateTime();
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();

      debugPrint('Error loading exchange rates: $e');
    }
  }

  /// Refresh exchange rates
  Future<void> refreshExchangeRates() async {
    await _loadExchangeRates(forceRefresh: true);
  }

  /// Convert amount from selected currency to target currency
  double convertFromSelected(double amount, String targetCurrency) {
    if (_selectedCurrency == targetCurrency) return amount;

    try {
      // The exchange rates are fetched with the selected currency as base
      // So to convert FROM selected currency TO target currency, we multiply by the rate
      final rate = _exchangeRates[targetCurrency];
      if (rate != null) {
        return amount * rate;
      }
    } catch (e) {
      debugPrint('Error converting currency: $e');
    }

    return amount; // Return original amount if conversion fails
  }

  /// Convert amount to selected currency from source currency
  double convertToSelected(double amount, String sourceCurrency) {
    if (sourceCurrency == _selectedCurrency) return amount;

    // If loading or no rates available, don't convert - keep original amount
    if (_isLoading || _exchangeRates.isEmpty) {
      return amount;
    }

    try {
      // The exchange rates are fetched with the selected currency as base
      // So _selectedCurrency always has rate 1.0, and other currencies have rates relative to it
      // For example, if selected currency is USD and rates are {USD: 1.0, AED: 3.67, SYP: 2500}
      // This means 1 USD = 3.67 AED = 2500 SYP

      final rate = _exchangeRates[sourceCurrency];
      if (rate != null && rate != 0) {
        // To convert FROM source currency TO selected currency,
        // we divide by the rate since the rate tells us how many source currency units = 1 selected currency unit
        return amount / rate;
      }
    } catch (e) {
      debugPrint('Error converting currency: $e');
    }

    return amount; // Return original amount if conversion fails
  }

  /// Format amount in selected currency
  String formatAmount(double amount) {
    return CurrencyService.formatCurrency(amount, _selectedCurrency);
  }

  /// Format amount in specific currency
  String formatAmountInCurrency(double amount, String currency) {
    return CurrencyService.formatCurrency(amount, currency);
  }

  /// Get formatted price with conversion
  String getFormattedPrice(double originalAmount, String originalCurrency) {
    if (originalCurrency == _selectedCurrency) {
      return formatAmount(originalAmount);
    }

    // If loading, show original price with original currency
    if (_isLoading) {
      return CurrencyService.formatCurrency(originalAmount, originalCurrency);
    }

    final convertedAmount = convertToSelected(originalAmount, originalCurrency);
    return formatAmount(convertedAmount);
  }

  /// Get exchange rate between two currencies
  double? getExchangeRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1.0;

    try {
      if (fromCurrency == 'USD') {
        return _exchangeRates[toCurrency];
      } else if (toCurrency == 'USD') {
        final rate = _exchangeRates[fromCurrency];
        return rate != null && rate != 0 ? 1 / rate : null;
      } else {
        final fromRate = _exchangeRates[fromCurrency];
        final toRate = _exchangeRates[toCurrency];

        if (fromRate != null && toRate != null && fromRate != 0) {
          return toRate / fromRate;
        }
      }
    } catch (e) {
      debugPrint('Error getting exchange rate: $e');
    }

    return null;
  }

  /// Check if rates need refresh (older than 6 hours)
  bool get needsRefresh {
    if (_lastUpdate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastUpdate!);
    return difference.inHours >= 6;
  }

  /// Get time until next recommended refresh
  Duration? get timeUntilRefresh {
    if (_lastUpdate == null) return null;

    final nextRefresh = _lastUpdate!.add(const Duration(hours: 6));
    final now = DateTime.now();

    if (nextRefresh.isAfter(now)) {
      return nextRefresh.difference(now);
    }

    return null;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await CurrencyService.clearCache();
    _exchangeRates.clear();
    _lastUpdate = null;
    _error = null;
    notifyListeners();
  }

  /// Get currency info for display
  Map<String, dynamic> getCurrencyInfo(String currency) {
    return {
      'code': currency,
      'symbol': CurrencyService.getCurrencySymbol(currency),
      'name': CurrencyService.getCurrencyName(currency),
      'rate': _exchangeRates[currency],
    };
  }

  /// Get all supported currencies info
  List<Map<String, dynamic>> getAllCurrenciesInfo() {
    return CurrencyService.supportedCurrencies
        .map((currency) => getCurrencyInfo(currency))
        .toList();
  }
}
