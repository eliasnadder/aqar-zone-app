// Test file to demonstrate price formatting
// This file can be deleted after testing

import 'lib/models/property_model.dart';

void main() {
  // Test different price ranges
  print('Price Formatting Examples:');
  print('========================');
  
  // Test values under 1000
  print('${Property.formatPrice(500, 'USD')}'); // Expected: 500 USD
  print('${Property.formatPrice(999, 'AED')}'); // Expected: 999 AED
  
  // Test values in thousands
  print('${Property.formatPrice(1000, 'USD')}'); // Expected: 1K USD
  print('${Property.formatPrice(1500, 'USD')}'); // Expected: 1.5K USD
  print('${Property.formatPrice(25000, 'AED')}'); // Expected: 25K AED
  print('${Property.formatPrice(150000, 'USD')}'); // Expected: 150K USD
  print('${Property.formatPrice(500000, 'AED')}'); // Expected: 500K AED
  
  // Test values in millions
  print('${Property.formatPrice(1000000, 'USD')}'); // Expected: 1M USD
  print('${Property.formatPrice(1500000, 'USD')}'); // Expected: 1.5M USD
  print('${Property.formatPrice(2750000, 'AED')}'); // Expected: 2.8M AED
  print('${Property.formatPrice(10000000, 'USD')}'); // Expected: 10M USD
  
  print('\nReal Estate Examples:');
  print('====================');
  print('Studio Apartment: ${Property.formatPrice(450000, 'AED')}'); // 450K AED
  print('1BR Apartment: ${Property.formatPrice(750000, 'AED')}'); // 750K AED
  print('2BR Apartment: ${Property.formatPrice(1200000, 'AED')}'); // 1.2M AED
  print('3BR Villa: ${Property.formatPrice(2500000, 'AED')}'); // 2.5M AED
  print('Luxury Villa: ${Property.formatPrice(8750000, 'AED')}'); // 8.8M AED
}
