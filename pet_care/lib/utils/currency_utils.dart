/// Currency utility functions for Thai Baht (THB) formatting and conversion
/// 
/// This file provides utilities for handling currency formatting and conversion
/// for the Thai-based pet care application.

class CurrencyUtils {
  // Current exchange rate: 1 USD = 36 THB (approximate)
  // You may want to use a real-time API for dynamic rates
  static const double USD_TO_THB_RATE = 36.0;
  
  // Thai Baht symbol and currency code
  static const String THB_SYMBOL = '฿';
  static const String THB_CODE = 'THB';
  static const String USD_SYMBOL = '\$';
  static const String USD_CODE = 'USD';

  /// Convert USD amount to THB
  static double convertUsdToThb(double usdAmount) {
    return usdAmount * USD_TO_THB_RATE;
  }

  /// Convert THB amount to USD
  static double convertThbToUsd(double thbAmount) {
    return thbAmount / USD_TO_THB_RATE;
  }

  /// Format THB amount with currency symbol
  /// Example: formatThb(100.50) returns "฿100.50"
  static String formatThb(double amount) {
    return '$THB_SYMBOL${amount.toStringAsFixed(2)}';
  }

  /// Format THB amount as integer (for whole numbers)
  /// Example: formatThbInt(100) returns "฿100"
  static String formatThbInt(double amount) {
    return '$THB_SYMBOL${amount.round()}';
  }

  /// Format USD amount and convert to THB display
  /// This is useful for converting existing USD prices to THB display
  static String formatUsdAsThb(double usdAmount) {
    double thbAmount = convertUsdToThb(usdAmount);
    return formatThb(thbAmount);
  }

  /// Format USD amount as integer and convert to THB display
  static String formatUsdAsThbInt(double usdAmount) {
    double thbAmount = convertUsdToThb(usdAmount);
    return formatThbInt(thbAmount);
  }

  /// Get currency code for Stripe and other payment processors
  static String getPaymentCurrencyCode() {
    return THB_CODE.toLowerCase(); // Stripe uses lowercase currency codes
  }

  /// Convert amount to cents/minor units for payment processing
  /// THB uses satang (1 THB = 100 satang), similar to USD cents
  static String getPaymentAmount(double thbAmount) {
    return (thbAmount * 100).round().toString();
  }

  /// Parse a formatted THB string back to double
  /// Example: parseThb("฿100.50") returns 100.50
  static double parseThb(String thbString) {
    String cleanString = thbString.replaceAll(THB_SYMBOL, '').trim();
    return double.tryParse(cleanString) ?? 0.0;
  }
}

/// Common pricing conversions for the app
class CommonPrices {
  // Convert common USD prices to THB equivalents
  static double get deliveryFee => CurrencyUtils.convertUsdToThb(30.0); // Was $30 USD
  static double get baseMealCost => CurrencyUtils.convertUsdToThb(8.0); // Base meal cost in THB
  static double get ingredientBaseCost => CurrencyUtils.convertUsdToThb(2.0); // Base ingredient cost
  
  // Subscription pricing tiers in THB
  static Map<String, double> get subscriptionBasePrices => {
    'weekly': CurrencyUtils.convertUsdToThb(25.0),
    'bi-weekly': CurrencyUtils.convertUsdToThb(45.0),
    'monthly': CurrencyUtils.convertUsdToThb(80.0),
  };
  
  // Dog size multipliers (same as before, but applied to THB prices)
  static Map<String, double> get dogSizeMultipliers => {
    'Small': 0.8,
    'Medium': 1.0,
    'Large': 1.3,
    'Extra Large': 1.6,
  };
}
