import 'package:equatable/equatable.dart';

abstract class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object?> get props => [];
}

class CurrencyInitial extends CurrencyState {
  const CurrencyInitial();
}

class CurrencyLoading extends CurrencyState {
  const CurrencyLoading();
}

class CurrencyLoaded extends CurrencyState {
  final String selectedCurrency;
  final Map<String, double> exchangeRates;
  final DateTime lastUpdate;
  final bool isOffline;
  final bool autoRefresh;
  final Duration refreshInterval;

  const CurrencyLoaded({
    required this.selectedCurrency,
    required this.exchangeRates,
    required this.lastUpdate,
    this.isOffline = false,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(hours: 6),
  });

  CurrencyLoaded copyWith({
    String? selectedCurrency,
    Map<String, double>? exchangeRates,
    DateTime? lastUpdate,
    bool? isOffline,
    bool? autoRefresh,
    Duration? refreshInterval,
  }) {
    return CurrencyLoaded(
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isOffline: isOffline ?? this.isOffline,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }

  String get selectedCurrencySymbol {
    const symbols = {'USD': '\$', 'AED': 'AED', 'SYP': 'SYP'};
    return symbols[selectedCurrency] ?? selectedCurrency;
  }

  String get selectedCurrencyName {
    const names = {
      'USD': 'US Dollar',
      'AED': 'UAE Dirham',
      'SYP': 'Syrian Pound',
    };
    return names[selectedCurrency] ?? selectedCurrency;
  }

  bool get needsRefresh {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference >= refreshInterval;
  }

  Duration? get timeUntilRefresh {
    final nextRefresh = lastUpdate.add(refreshInterval);
    final now = DateTime.now();

    if (nextRefresh.isAfter(now)) {
      return nextRefresh.difference(now);
    }

    return null;
  }

  @override
  List<Object?> get props => [
    selectedCurrency,
    exchangeRates,
    lastUpdate,
    isOffline,
    autoRefresh,
    refreshInterval,
  ];
}

class CurrencyRefreshing extends CurrencyState {
  final String selectedCurrency;
  final Map<String, double> currentRates;

  const CurrencyRefreshing({
    required this.selectedCurrency,
    required this.currentRates,
  });

  @override
  List<Object?> get props => [selectedCurrency, currentRates];
}

class CurrencyError extends CurrencyState {
  final String message;
  final String? errorCode;
  final String? selectedCurrency;
  final Map<String, double>? cachedRates;
  final DateTime? lastUpdate;

  const CurrencyError({
    required this.message,
    this.errorCode,
    this.selectedCurrency,
    this.cachedRates,
    this.lastUpdate,
  });

  @override
  List<Object?> get props => [
    message,
    errorCode,
    selectedCurrency,
    cachedRates,
    lastUpdate,
  ];
}

class CurrencyConverted extends CurrencyState {
  final double originalAmount;
  final double convertedAmount;
  final String fromCurrency;
  final String toCurrency;
  final double exchangeRate;
  final DateTime conversionTime;

  const CurrencyConverted({
    required this.originalAmount,
    required this.convertedAmount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.exchangeRate,
    required this.conversionTime,
  });

  @override
  List<Object?> get props => [
    originalAmount,
    convertedAmount,
    fromCurrency,
    toCurrency,
    exchangeRate,
    conversionTime,
  ];
}

class CurrencyFormatted extends CurrencyState {
  final double amount;
  final String currency;
  final String formattedAmount;

  const CurrencyFormatted({
    required this.amount,
    required this.currency,
    required this.formattedAmount,
  });

  @override
  List<Object?> get props => [amount, currency, formattedAmount];
}

class ExchangeRateRetrieved extends CurrencyState {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime retrievalTime;

  const ExchangeRateRetrieved({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.retrievalTime,
  });

  @override
  List<Object?> get props => [fromCurrency, toCurrency, rate, retrievalTime];
}

class CurrencyBatchConverted extends CurrencyState {
  final List<double> originalAmounts;
  final List<double> convertedAmounts;
  final String fromCurrency;
  final String toCurrency;
  final double exchangeRate;
  final DateTime conversionTime;

  const CurrencyBatchConverted({
    required this.originalAmounts,
    required this.convertedAmounts,
    required this.fromCurrency,
    required this.toCurrency,
    required this.exchangeRate,
    required this.conversionTime,
  });

  @override
  List<Object?> get props => [
    originalAmounts,
    convertedAmounts,
    fromCurrency,
    toCurrency,
    exchangeRate,
    conversionTime,
  ];
}

class CurrencyValidated extends CurrencyState {
  final String currency;
  final bool isSupported;
  final String? reason;

  const CurrencyValidated({
    required this.currency,
    required this.isSupported,
    this.reason,
  });

  @override
  List<Object?> get props => [currency, isSupported, reason];
}

class CurrencyOfflineMode extends CurrencyState {
  final bool isOffline;
  final String selectedCurrency;
  final Map<String, double>? cachedRates;
  final DateTime? lastCacheUpdate;

  const CurrencyOfflineMode({
    required this.isOffline,
    required this.selectedCurrency,
    this.cachedRates,
    this.lastCacheUpdate,
  });

  @override
  List<Object?> get props => [
    isOffline,
    selectedCurrency,
    cachedRates,
    lastCacheUpdate,
  ];
}

class CurrencySubscribed extends CurrencyState {
  final Duration updateInterval;
  final DateTime subscriptionTime;

  const CurrencySubscribed({
    required this.updateInterval,
    required this.subscriptionTime,
  });

  @override
  List<Object?> get props => [updateInterval, subscriptionTime];
}

class CurrencyUnsubscribed extends CurrencyState {
  final DateTime unsubscriptionTime;

  const CurrencyUnsubscribed({required this.unsubscriptionTime});

  @override
  List<Object?> get props => [unsubscriptionTime];
}

class CurrencyBackedUp extends CurrencyState {
  final DateTime backupTime;
  final int dataSize;

  const CurrencyBackedUp({required this.backupTime, required this.dataSize});

  @override
  List<Object?> get props => [backupTime, dataSize];
}

class CurrencyRestored extends CurrencyState {
  final DateTime restoreTime;
  final String selectedCurrency;
  final Map<String, double> exchangeRates;

  const CurrencyRestored({
    required this.restoreTime,
    required this.selectedCurrency,
    required this.exchangeRates,
  });

  @override
  List<Object?> get props => [restoreTime, selectedCurrency, exchangeRates];
}
