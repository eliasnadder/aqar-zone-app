import 'package:equatable/equatable.dart';

abstract class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object?> get props => [];
}

class LoadCurrencyRates extends CurrencyEvent {
  final String baseCurrency;
  final bool forceRefresh;

  const LoadCurrencyRates({
    this.baseCurrency = 'USD',
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [baseCurrency, forceRefresh];
}

class ChangeCurrency extends CurrencyEvent {
  final String currency;

  const ChangeCurrency({required this.currency});

  @override
  List<Object?> get props => [currency];
}

class RefreshCurrencyRates extends CurrencyEvent {
  const RefreshCurrencyRates();
}

class ConvertCurrency extends CurrencyEvent {
  final double amount;
  final String fromCurrency;
  final String toCurrency;

  const ConvertCurrency({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [amount, fromCurrency, toCurrency];
}

class InitializeCurrency extends CurrencyEvent {
  const InitializeCurrency();
}

class ClearCurrencyCache extends CurrencyEvent {
  const ClearCurrencyCache();
}

class UpdateCurrencyPreferences extends CurrencyEvent {
  final String selectedCurrency;
  final bool autoRefresh;
  final Duration refreshInterval;

  const UpdateCurrencyPreferences({
    required this.selectedCurrency,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(hours: 6),
  });

  @override
  List<Object?> get props => [selectedCurrency, autoRefresh, refreshInterval];
}

class CheckCurrencyRatesExpiry extends CurrencyEvent {
  const CheckCurrencyRatesExpiry();
}

class SetOfflineMode extends CurrencyEvent {
  final bool isOffline;

  const SetOfflineMode({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}

class ValidateCurrencySupport extends CurrencyEvent {
  final String currency;

  const ValidateCurrencySupport({required this.currency});

  @override
  List<Object?> get props => [currency];
}

class FormatCurrencyAmount extends CurrencyEvent {
  final double amount;
  final String currency;

  const FormatCurrencyAmount({
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [amount, currency];
}

class GetExchangeRate extends CurrencyEvent {
  final String fromCurrency;
  final String toCurrency;

  const GetExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [fromCurrency, toCurrency];
}

class BatchConvertCurrency extends CurrencyEvent {
  final List<double> amounts;
  final String fromCurrency;
  final String toCurrency;

  const BatchConvertCurrency({
    required this.amounts,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [amounts, fromCurrency, toCurrency];
}

class SubscribeToRateUpdates extends CurrencyEvent {
  final Duration updateInterval;

  const SubscribeToRateUpdates({
    this.updateInterval = const Duration(hours: 1),
  });

  @override
  List<Object?> get props => [updateInterval];
}

class UnsubscribeFromRateUpdates extends CurrencyEvent {
  const UnsubscribeFromRateUpdates();
}

class HandleCurrencyError extends CurrencyEvent {
  final String error;
  final String? errorCode;

  const HandleCurrencyError({
    required this.error,
    this.errorCode,
  });

  @override
  List<Object?> get props => [error, errorCode];
}

class RestoreCurrencyFromCache extends CurrencyEvent {
  const RestoreCurrencyFromCache();
}

class BackupCurrencyData extends CurrencyEvent {
  const BackupCurrencyData();
}
