import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/currency_service.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  static const String _selectedCurrencyKey = 'selected_currency';
  static const String _exchangeRatesKey = 'exchange_rates';
  static const String _lastUpdateKey = 'currency_last_update';
  static const String _autoRefreshKey = 'auto_refresh';
  static const String _refreshIntervalKey = 'refresh_interval';

  Timer? _refreshTimer;
  Timer? _subscriptionTimer;

  CurrencyBloc() : super(const CurrencyInitial()) {
    on<InitializeCurrency>(_onInitializeCurrency);
    on<LoadCurrencyRates>(_onLoadCurrencyRates);
    on<ChangeCurrency>(_onChangeCurrency);
    on<RefreshCurrencyRates>(_onRefreshCurrencyRates);
    on<ConvertCurrency>(_onConvertCurrency);
    on<ClearCurrencyCache>(_onClearCurrencyCache);
    on<UpdateCurrencyPreferences>(_onUpdateCurrencyPreferences);
    on<CheckCurrencyRatesExpiry>(_onCheckCurrencyRatesExpiry);
    on<SetOfflineMode>(_onSetOfflineMode);
    on<ValidateCurrencySupport>(_onValidateCurrencySupport);
    on<FormatCurrencyAmount>(_onFormatCurrencyAmount);
    on<GetExchangeRate>(_onGetExchangeRate);
    on<BatchConvertCurrency>(_onBatchConvertCurrency);
    on<SubscribeToRateUpdates>(_onSubscribeToRateUpdates);
    on<UnsubscribeFromRateUpdates>(_onUnsubscribeFromRateUpdates);
    on<HandleCurrencyError>(_onHandleCurrencyError);
    on<RestoreCurrencyFromCache>(_onRestoreCurrencyFromCache);
    on<BackupCurrencyData>(_onBackupCurrencyData);

    // Initialize currency on startup
    add(const InitializeCurrency());
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _subscriptionTimer?.cancel();
    return super.close();
  }

  Future<void> _onInitializeCurrency(
    InitializeCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      emit(const CurrencyLoading());

      final prefs = await SharedPreferences.getInstance();
      final selectedCurrency = prefs.getString(_selectedCurrencyKey) ?? 'USD';
      final autoRefresh = prefs.getBool(_autoRefreshKey) ?? true;
      final refreshIntervalHours = prefs.getInt(_refreshIntervalKey) ?? 6;
      final refreshInterval = Duration(hours: refreshIntervalHours);

      // Try to load cached rates first
      final cachedRatesJson = prefs.getString(_exchangeRatesKey);
      final lastUpdateTimestamp = prefs.getInt(_lastUpdateKey);

      if (cachedRatesJson != null && lastUpdateTimestamp != null) {
        final cachedRates = Map<String, double>.from(
          json
              .decode(cachedRatesJson)
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
        final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
          lastUpdateTimestamp,
        );

        emit(
          CurrencyLoaded(
            selectedCurrency: selectedCurrency,
            exchangeRates: cachedRates,
            lastUpdate: lastUpdate,
            autoRefresh: autoRefresh,
            refreshInterval: refreshInterval,
          ),
        );

        // Disable auto-refresh to prevent conflicts with CurrencyProvider
        // if (autoRefresh) {
        //   add(const CheckCurrencyRatesExpiry());
        // }
      } else {
        // Load fresh rates
        add(LoadCurrencyRates(baseCurrency: selectedCurrency));
      }
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  Future<void> _onLoadCurrencyRates(
    LoadCurrencyRates event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      if (!event.forceRefresh && state is CurrencyLoaded) {
        final currentState = state as CurrencyLoaded;
        emit(
          CurrencyRefreshing(
            selectedCurrency: currentState.selectedCurrency,
            currentRates: currentState.exchangeRates,
          ),
        );
      } else {
        emit(const CurrencyLoading());
      }

      final rates = await CurrencyService.getExchangeRates(
        baseCurrency: event.baseCurrency,
        forceRefresh: event.forceRefresh,
      );

      final now = DateTime.now();

      // Save to preferences
      await _saveToPreferences(event.baseCurrency, rates, now);

      emit(
        CurrencyLoaded(
          selectedCurrency: event.baseCurrency,
          exchangeRates: rates,
          lastUpdate: now,
          autoRefresh:
              state is CurrencyLoaded
                  ? (state as CurrencyLoaded).autoRefresh
                  : true,
          refreshInterval:
              state is CurrencyLoaded
                  ? (state as CurrencyLoaded).refreshInterval
                  : const Duration(hours: 6),
        ),
      );

      // Disable auto-refresh to prevent conflicts with CurrencyProvider
      // if (state is CurrencyLoaded && (state as CurrencyLoaded).autoRefresh) {
      //   _scheduleAutoRefresh((state as CurrencyLoaded).refreshInterval);
      // }
    } catch (e) {
      // Try to load cached rates on error
      final cachedData = await _loadCachedData();
      emit(
        CurrencyError(
          message: e.toString(),
          selectedCurrency: cachedData['currency'],
          cachedRates: cachedData['rates'],
          lastUpdate: cachedData['lastUpdate'],
        ),
      );
    }
  }

  Future<void> _onChangeCurrency(
    ChangeCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      if (event.currency.isEmpty) {
        emit(const CurrencyError(message: 'Currency code cannot be empty'));
        return;
      }

      if (!CurrencyService.supportedCurrencies.contains(event.currency)) {
        emit(CurrencyError(message: 'Unsupported currency: ${event.currency}'));
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCurrencyKey, event.currency);

      // Load rates for new currency
      add(LoadCurrencyRates(baseCurrency: event.currency, forceRefresh: true));
    } catch (e) {
      emit(
        CurrencyError(message: 'Failed to change currency: ${e.toString()}'),
      );
    }
  }

  Future<void> _onRefreshCurrencyRates(
    RefreshCurrencyRates event,
    Emitter<CurrencyState> emit,
  ) async {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      add(
        LoadCurrencyRates(
          baseCurrency: currentState.selectedCurrency,
          forceRefresh: true,
        ),
      );
    } else {
      add(const LoadCurrencyRates(forceRefresh: true));
    }
  }

  Future<void> _onConvertCurrency(
    ConvertCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      Map<String, double>? rates;

      if (state is CurrencyLoaded) {
        rates = (state as CurrencyLoaded).exchangeRates;
      } else {
        // Load rates if not available
        rates = await CurrencyService.getExchangeRates();
      }

      final convertedAmount = await CurrencyService.convertCurrency(
        amount: event.amount,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
        rates: rates,
      );

      final exchangeRate = _calculateExchangeRate(
        event.fromCurrency,
        event.toCurrency,
        rates,
      );

      emit(
        CurrencyConverted(
          originalAmount: event.amount,
          convertedAmount: convertedAmount,
          fromCurrency: event.fromCurrency,
          toCurrency: event.toCurrency,
          exchangeRate: exchangeRate,
          conversionTime: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  Future<void> _onClearCurrencyCache(
    ClearCurrencyCache event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      await CurrencyService.clearCache();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_exchangeRatesKey);
      await prefs.remove(_lastUpdateKey);

      emit(const CurrencyInitial());
      add(const InitializeCurrency());
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCurrencyPreferences(
    UpdateCurrencyPreferences event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCurrencyKey, event.selectedCurrency);
      await prefs.setBool(_autoRefreshKey, event.autoRefresh);
      await prefs.setInt(_refreshIntervalKey, event.refreshInterval.inHours);

      if (state is CurrencyLoaded) {
        final currentState = state as CurrencyLoaded;
        emit(
          currentState.copyWith(
            selectedCurrency: event.selectedCurrency,
            autoRefresh: event.autoRefresh,
            refreshInterval: event.refreshInterval,
          ),
        );

        // Disable auto-refresh to prevent conflicts with CurrencyProvider
        // if (event.autoRefresh) {
        //   _scheduleAutoRefresh(event.refreshInterval);
        // } else {
        //   _refreshTimer?.cancel();
        // }
      }

      // Load rates for new currency if changed
      if (state is CurrencyLoaded &&
          (state as CurrencyLoaded).selectedCurrency !=
              event.selectedCurrency) {
        add(LoadCurrencyRates(baseCurrency: event.selectedCurrency));
      }
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  Future<void> _onCheckCurrencyRatesExpiry(
    CheckCurrencyRatesExpiry event,
    Emitter<CurrencyState> emit,
  ) async {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      if (currentState.needsRefresh && currentState.autoRefresh) {
        add(const RefreshCurrencyRates());
      }
    }
  }

  Future<void> _onSetOfflineMode(
    SetOfflineMode event,
    Emitter<CurrencyState> emit,
  ) async {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      emit(currentState.copyWith(isOffline: event.isOffline));
    } else {
      final cachedData = await _loadCachedData();
      emit(
        CurrencyOfflineMode(
          isOffline: event.isOffline,
          selectedCurrency: cachedData['currency'] ?? 'USD',
          cachedRates: cachedData['rates'],
          lastCacheUpdate: cachedData['lastUpdate'],
        ),
      );
    }
  }

  Future<void> _onValidateCurrencySupport(
    ValidateCurrencySupport event,
    Emitter<CurrencyState> emit,
  ) async {
    final isSupported = CurrencyService.supportedCurrencies.contains(
      event.currency,
    );
    final reason = isSupported ? null : 'Currency not in supported list';

    emit(
      CurrencyValidated(
        currency: event.currency,
        isSupported: isSupported,
        reason: reason,
      ),
    );
  }

  Future<void> _onFormatCurrencyAmount(
    FormatCurrencyAmount event,
    Emitter<CurrencyState> emit,
  ) async {
    final formattedAmount = CurrencyService.formatCurrency(
      event.amount,
      event.currency,
    );

    emit(
      CurrencyFormatted(
        amount: event.amount,
        currency: event.currency,
        formattedAmount: formattedAmount,
      ),
    );
  }

  Future<void> _onGetExchangeRate(
    GetExchangeRate event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      Map<String, double>? rates;

      if (state is CurrencyLoaded) {
        rates = (state as CurrencyLoaded).exchangeRates;
      } else {
        rates = await CurrencyService.getExchangeRates();
      }

      final rate = _calculateExchangeRate(
        event.fromCurrency,
        event.toCurrency,
        rates,
      );

      emit(
        ExchangeRateRetrieved(
          fromCurrency: event.fromCurrency,
          toCurrency: event.toCurrency,
          rate: rate,
          retrievalTime: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  Future<void> _onBatchConvertCurrency(
    BatchConvertCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      Map<String, double>? rates;

      if (state is CurrencyLoaded) {
        rates = (state as CurrencyLoaded).exchangeRates;
      } else {
        rates = await CurrencyService.getExchangeRates();
      }

      final convertedAmounts = <double>[];
      for (final amount in event.amounts) {
        final converted = await CurrencyService.convertCurrency(
          amount: amount,
          fromCurrency: event.fromCurrency,
          toCurrency: event.toCurrency,
          rates: rates,
        );
        convertedAmounts.add(converted);
      }

      final exchangeRate = _calculateExchangeRate(
        event.fromCurrency,
        event.toCurrency,
        rates,
      );

      emit(
        CurrencyBatchConverted(
          originalAmounts: event.amounts,
          convertedAmounts: convertedAmounts,
          fromCurrency: event.fromCurrency,
          toCurrency: event.toCurrency,
          exchangeRate: exchangeRate,
          conversionTime: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  Future<void> _onSubscribeToRateUpdates(
    SubscribeToRateUpdates event,
    Emitter<CurrencyState> emit,
  ) async {
    _subscriptionTimer?.cancel();
    _subscriptionTimer = Timer.periodic(event.updateInterval, (_) {
      add(const RefreshCurrencyRates());
    });

    emit(
      CurrencySubscribed(
        updateInterval: event.updateInterval,
        subscriptionTime: DateTime.now(),
      ),
    );
  }

  Future<void> _onUnsubscribeFromRateUpdates(
    UnsubscribeFromRateUpdates event,
    Emitter<CurrencyState> emit,
  ) async {
    _subscriptionTimer?.cancel();
    _subscriptionTimer = null;

    emit(CurrencyUnsubscribed(unsubscriptionTime: DateTime.now()));
  }

  Future<void> _onHandleCurrencyError(
    HandleCurrencyError event,
    Emitter<CurrencyState> emit,
  ) async {
    final cachedData = await _loadCachedData();
    emit(
      CurrencyError(
        message: event.error,
        errorCode: event.errorCode,
        selectedCurrency: cachedData['currency'],
        cachedRates: cachedData['rates'],
        lastUpdate: cachedData['lastUpdate'],
      ),
    );
  }

  Future<void> _onRestoreCurrencyFromCache(
    RestoreCurrencyFromCache event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      final cachedData = await _loadCachedData();

      if (cachedData['rates'] != null) {
        emit(
          CurrencyRestored(
            restoreTime: DateTime.now(),
            selectedCurrency: cachedData['currency'] ?? 'USD',
            exchangeRates: cachedData['rates']!,
          ),
        );
      } else {
        emit(const CurrencyError(message: 'No cached data available'));
      }
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  Future<void> _onBackupCurrencyData(
    BackupCurrencyData event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      if (state is CurrencyLoaded) {
        final currentState = state as CurrencyLoaded;
        await _saveToPreferences(
          currentState.selectedCurrency,
          currentState.exchangeRates,
          currentState.lastUpdate,
        );

        final dataSize = json.encode(currentState.exchangeRates).length;

        emit(CurrencyBackedUp(backupTime: DateTime.now(), dataSize: dataSize));
      }
    } catch (e) {
      emit(CurrencyError(message: e.toString()));
    }
  }

  // Helper methods
  double _calculateExchangeRate(
    String fromCurrency,
    String toCurrency,
    Map<String, double> rates,
  ) {
    if (fromCurrency == toCurrency) return 1.0;

    if (fromCurrency == 'USD') {
      return rates[toCurrency] ?? 1.0;
    } else if (toCurrency == 'USD') {
      final rate = rates[fromCurrency];
      return rate != null && rate != 0 ? 1 / rate : 1.0;
    } else {
      final fromRate = rates[fromCurrency];
      final toRate = rates[toCurrency];

      if (fromRate != null && toRate != null && fromRate != 0) {
        return toRate / fromRate;
      }
    }

    return 1.0;
  }

  Future<void> _saveToPreferences(
    String currency,
    Map<String, double> rates,
    DateTime lastUpdate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCurrencyKey, currency);
    await prefs.setString(_exchangeRatesKey, json.encode(rates));
    await prefs.setInt(_lastUpdateKey, lastUpdate.millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currency = prefs.getString(_selectedCurrencyKey);
      final ratesJson = prefs.getString(_exchangeRatesKey);
      final lastUpdateTimestamp = prefs.getInt(_lastUpdateKey);

      Map<String, double>? rates;
      DateTime? lastUpdate;

      if (ratesJson != null) {
        rates = Map<String, double>.from(
          json
              .decode(ratesJson)
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
      }

      if (lastUpdateTimestamp != null) {
        lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateTimestamp);
      }

      return {'currency': currency, 'rates': rates, 'lastUpdate': lastUpdate};
    } catch (e) {
      return {};
    }
  }

  void _scheduleAutoRefresh(Duration interval) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(interval, () {
      add(const RefreshCurrencyRates());
    });
  }
}
