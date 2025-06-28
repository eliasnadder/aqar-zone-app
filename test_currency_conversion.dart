import 'lib/services/currency_service.dart';

void main() async {
  print('🌍 Testing Currency Conversion API');
  print('=====================================');
  
  try {
    // Test getting exchange rates
    print('\n📊 Fetching exchange rates...');
    final rates = await CurrencyService.getExchangeRates(baseCurrency: 'USD');
    
    print('✅ Exchange rates fetched successfully:');
    rates.forEach((currency, rate) {
      print('   $currency: $rate');
    });
    
    // Test currency conversion
    print('\n💱 Testing currency conversions:');
    
    // Convert $100,000 USD to other currencies
    final usdAmount = 100000.0;
    print('\nConverting \$${usdAmount.toStringAsFixed(0)} USD:');
    
    for (String currency in CurrencyService.supportedCurrencies) {
      if (currency != 'USD') {
        final convertedAmount = await CurrencyService.convertCurrency(
          amount: usdAmount,
          fromCurrency: 'USD',
          toCurrency: currency,
          rates: rates,
        );
        
        final formatted = CurrencyService.formatCurrency(convertedAmount, currency);
        print('   → $formatted ($currency)');
      }
    }
    
    // Test formatting
    print('\n🎨 Testing currency formatting:');
    
    final testAmounts = [1500.0, 25000.0, 150000.0, 2500000.0];
    
    for (String currency in CurrencyService.supportedCurrencies) {
      print('\n$currency formatting:');
      for (double amount in testAmounts) {
        final formatted = CurrencyService.formatCurrency(amount, currency);
        print('   ${amount.toStringAsFixed(0)} → $formatted');
      }
    }
    
    // Test real estate price examples
    print('\n🏠 Real Estate Price Examples:');
    
    final propertyPrices = {
      'Studio Apartment': 75000.0,
      'Two Bedroom': 150000.0,
      'Villa': 500000.0,
      'Luxury Penthouse': 1200000.0,
    };
    
    for (String propertyType in propertyPrices.keys) {
      final priceUSD = propertyPrices[propertyType]!;
      print('\n$propertyType (\$${priceUSD.toStringAsFixed(0)} USD):');
      
      for (String currency in CurrencyService.supportedCurrencies) {
        if (currency != 'USD') {
          final convertedPrice = await CurrencyService.convertCurrency(
            amount: priceUSD,
            fromCurrency: 'USD',
            toCurrency: currency,
            rates: rates,
          );
          
          final formatted = CurrencyService.formatCurrency(convertedPrice, currency);
          print('   → $formatted');
        }
      }
    }
    
    print('\n✅ Currency conversion test completed successfully!');
    
  } catch (e) {
    print('❌ Error during currency conversion test: $e');
  }
}
