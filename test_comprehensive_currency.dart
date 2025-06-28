import 'package:flutter/material.dart';
import 'lib/providers/currency_provider.dart';
import 'lib/services/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔧 Comprehensive Currency Conversion Test');
  print('=========================================');
  
  // Test 1: CurrencyService basic functionality
  print('\n1️⃣ Testing CurrencyService:');
  try {
    // Test USD as base
    final usdRates = await CurrencyService.getExchangeRates(baseCurrency: 'USD');
    print('USD-based rates: $usdRates');
    
    // Test conversion USD to AED
    final usdToAed = await CurrencyService.convertCurrency(
      amount: 100.0,
      fromCurrency: 'USD',
      toCurrency: 'AED',
      rates: usdRates,
    );
    print('100 USD to AED: $usdToAed');
    
    // Test AED as base
    final aedRates = await CurrencyService.getExchangeRates(baseCurrency: 'AED');
    print('AED-based rates: $aedRates');
    
    // Test conversion AED to USD
    final aedToUsd = await CurrencyService.convertCurrency(
      amount: 100.0,
      fromCurrency: 'AED',
      toCurrency: 'USD',
      rates: aedRates,
    );
    print('100 AED to USD: $aedToUsd');
    
  } catch (e) {
    print('❌ CurrencyService test failed: $e');
  }
  
  // Test 2: CurrencyProvider functionality
  print('\n2️⃣ Testing CurrencyProvider:');
  final currencyProvider = CurrencyProvider();
  
  // Wait for initial load
  await Future.delayed(const Duration(seconds: 3));
  
  print('Initial state:');
  print('  Selected: ${currencyProvider.selectedCurrency}');
  print('  Loading: ${currencyProvider.isLoading}');
  print('  Rates: ${currencyProvider.exchangeRates}');
  
  // Test property price conversion
  const double testPrice = 150000.0;
  const String originalCurrency = 'USD';
  
  print('\n3️⃣ Testing Property Price Conversion:');
  print('Original: $testPrice $originalCurrency');
  
  // Test initial formatting
  final initialFormatted = currencyProvider.getFormattedPrice(testPrice, originalCurrency);
  print('Initial formatted: $initialFormatted');
  
  // Test currency change to AED
  print('\n4️⃣ Testing Currency Change to AED:');
  try {
    await currencyProvider.setSelectedCurrency('AED');
    await Future.delayed(const Duration(seconds: 2));
    
    final aedFormatted = currencyProvider.getFormattedPrice(testPrice, originalCurrency);
    print('AED formatted: $aedFormatted');
    
    final convertedAmount = currencyProvider.convertToSelected(testPrice, originalCurrency);
    print('Converted amount: $convertedAmount AED');
    
  } catch (e) {
    print('❌ AED conversion failed: $e');
  }
  
  // Test currency change to SYP
  print('\n5️⃣ Testing Currency Change to SYP:');
  try {
    await currencyProvider.setSelectedCurrency('SYP');
    await Future.delayed(const Duration(seconds: 2));
    
    final sypFormatted = currencyProvider.getFormattedPrice(testPrice, originalCurrency);
    print('SYP formatted: $sypFormatted');
    
    final convertedAmount = currencyProvider.convertToSelected(testPrice, originalCurrency);
    print('Converted amount: $convertedAmount SYP');
    
  } catch (e) {
    print('❌ SYP conversion failed: $e');
  }
  
  // Test back to USD
  print('\n6️⃣ Testing Currency Change back to USD:');
  try {
    await currencyProvider.setSelectedCurrency('USD');
    await Future.delayed(const Duration(seconds: 2));
    
    final usdFormatted = currencyProvider.getFormattedPrice(testPrice, originalCurrency);
    print('USD formatted: $usdFormatted');
    
    final convertedAmount = currencyProvider.convertToSelected(testPrice, originalCurrency);
    print('Converted amount: $convertedAmount USD');
    
  } catch (e) {
    print('❌ USD conversion failed: $e');
  }
  
  print('\n✅ Comprehensive test completed!');
}
