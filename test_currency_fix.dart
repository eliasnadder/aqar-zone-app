import 'package:flutter/material.dart';
import 'lib/providers/currency_provider.dart';
import 'lib/services/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔧 Testing Currency Conversion Fix');
  print('==================================');

  // Test CurrencyService first
  print('\n🧪 Testing CurrencyService:');
  try {
    final rates = await CurrencyService.getExchangeRates(baseCurrency: 'USD');
    print('USD-based rates: $rates');

    // Test conversion
    final converted = await CurrencyService.convertCurrency(
      amount: 100.0,
      fromCurrency: 'USD',
      toCurrency: 'AED',
      rates: rates,
    );
    print('100 USD to AED: $converted');
  } catch (e) {
    print('CurrencyService test failed: $e');
  }

  // Create a currency provider instance
  final currencyProvider = CurrencyProvider();

  // Wait for initial load
  await Future.delayed(const Duration(seconds: 3));

  print('\n📊 Initial State:');
  print('Selected Currency: ${currencyProvider.selectedCurrency}');
  print('Is Loading: ${currencyProvider.isLoading}');
  print('Exchange Rates: ${currencyProvider.exchangeRates}');

  // Test property price
  const double testPrice = 150000.0;
  const String originalCurrency = 'USD';

  print('\n🏠 Test Property:');
  print('Original Price: $testPrice $originalCurrency');

  // Test formatting before currency change
  final initialFormatted = currencyProvider.getFormattedPrice(
    testPrice,
    originalCurrency,
  );
  print('Initial Formatted: $initialFormatted');

  // Test currency change to SYP
  print('\n💱 Changing currency to SYP...');

  // Listen to changes
  currencyProvider.addListener(() {
    print('Currency Provider Updated:');
    print('  - Selected: ${currencyProvider.selectedCurrency}');
    print('  - Loading: ${currencyProvider.isLoading}');
    print('  - Error: ${currencyProvider.error}');

    final formattedPrice = currencyProvider.getFormattedPrice(
      testPrice,
      originalCurrency,
    );
    print('  - Formatted Price: $formattedPrice');
  });

  try {
    await currencyProvider.setSelectedCurrency('SYP');

    // Wait for completion
    await Future.delayed(const Duration(seconds: 3));

    print('\n✅ Final State:');
    print('Selected Currency: ${currencyProvider.selectedCurrency}');
    print('Is Loading: ${currencyProvider.isLoading}');
    print('Error: ${currencyProvider.error}');

    final finalFormatted = currencyProvider.getFormattedPrice(
      testPrice,
      originalCurrency,
    );
    print('Final Formatted Price: $finalFormatted');

    // Test conversion
    final convertedAmount = currencyProvider.convertToSelected(
      testPrice,
      originalCurrency,
    );
    print('Converted Amount: $convertedAmount');
  } catch (e) {
    print('❌ Error during currency change: $e');
  }

  print('\n🔄 Testing currency change to AED...');

  try {
    await currencyProvider.setSelectedCurrency('AED');

    await Future.delayed(const Duration(seconds: 3));

    final aedFormatted = currencyProvider.getFormattedPrice(
      testPrice,
      originalCurrency,
    );
    print('AED Formatted Price: $aedFormatted');
  } catch (e) {
    print('❌ Error during AED change: $e');
  }

  print('\n✨ Test completed!');
}
