import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_key_service.dart';
import '../../services/AI/gemini_service.dart';
import 'api_key_event.dart';
import 'api_key_state.dart';

class ApiKeyBloc extends Bloc<ApiKeyEvent, ApiKeyState> {
  final ApiKeyService _apiKeyService;
  static const String _usageStatsKey = 'api_key_usage_stats';
  static const String _settingsKey = 'api_key_settings';

  Map<String, int> _operationCounts = {};
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  DateTime? _firstUsage;
  DateTime? _lastUsage;

  ApiKeyBloc({ApiKeyService? apiKeyService})
    : _apiKeyService = apiKeyService ?? ApiKeyService.instance,
      super(const ApiKeyInitial()) {
    on<InitializeApiKey>(_onInitializeApiKey);
    on<SetApiKey>(_onSetApiKey);
    on<ValidateApiKey>(_onValidateApiKey);
    on<ClearApiKey>(_onClearApiKey);
    on<LoadApiKey>(_onLoadApiKey);
    on<SaveApiKey>(_onSaveApiKey);
    on<TestApiKeyConnection>(_onTestApiKeyConnection);
    on<CompleteSetup>(_onCompleteSetup);
    on<ResetSetup>(_onResetSetup);
    on<UpdateApiKeySettings>(_onUpdateApiKeySettings);
    on<RefreshApiKeyStatus>(_onRefreshApiKeyStatus);
    on<HandleApiKeyError>(_onHandleApiKeyError);
    on<BackupApiKey>(_onBackupApiKey);
    on<RestoreApiKey>(_onRestoreApiKey);
    on<CheckApiKeyExpiry>(_onCheckApiKeyExpiry);
    on<RenewApiKey>(_onRenewApiKey);
    on<EnableApiKeyAutoRefresh>(_onEnableApiKeyAutoRefresh);
    on<LogApiKeyUsage>(_onLogApiKeyUsage);
    on<GetApiKeyUsageStats>(_onGetApiKeyUsageStats);
    on<ClearApiKeyUsageStats>(_onClearApiKeyUsageStats);
    on<SetApiKeyFromQR>(_onSetApiKeyFromQR);
    on<GenerateApiKeyQR>(_onGenerateApiKeyQR);
    on<ExportApiKeySettings>(_onExportApiKeySettings);
    on<ImportApiKeySettings>(_onImportApiKeySettings);

    // Initialize on startup
    add(const InitializeApiKey());
  }

  Future<void> _onInitializeApiKey(
    InitializeApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      emit(const ApiKeyLoading());

      await _apiKeyService.initialize();
      await _loadUsageStats();

      if (_apiKeyService.hasApiKey) {
        final apiKey = _apiKeyService.apiKey!;
        final isValid = _apiKeyService.isValid;
        final hasCompletedSetup = _apiKeyService.hasCompletedSetup;

        emit(
          ApiKeyLoaded(
            apiKey: apiKey,
            isValid: isValid,
            hasCompletedSetup: hasCompletedSetup,
            lastValidated: DateTime.now(),
          ),
        );

        // Auto-validate if needed
        if (!isValid) {
          add(ValidateApiKey(apiKey: apiKey));
        }
      } else {
        emit(const ApiKeyEmpty());
      }
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onSetApiKey(SetApiKey event, Emitter<ApiKeyState> emit) async {
    try {
      if (event.apiKey.trim().isEmpty) {
        emit(const ApiKeyError(message: 'API key cannot be empty'));
        return;
      }

      // Validate the API key format
      if (!_isValidApiKeyFormat(event.apiKey)) {
        emit(
          ApiKeyError(message: 'Invalid API key format', apiKey: event.apiKey),
        );
        return;
      }

      await _apiKeyService.setApiKey(event.apiKey);

      emit(
        ApiKeySaved(
          apiKey: event.apiKey,
          savedAt: DateTime.now(),
          securelyStored: true,
        ),
      );

      // Validate the new API key
      add(ValidateApiKey(apiKey: event.apiKey));
    } catch (e) {
      emit(ApiKeyError(message: e.toString(), apiKey: event.apiKey));
    }
  }

  Future<void> _onValidateApiKey(
    ValidateApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      emit(ApiKeyValidating(apiKey: event.apiKey));

      // Test the API key with a simple request
      final geminiService = GeminiService();
      final isValid = await geminiService.validateApiKey(event.apiKey);

      if (isValid) {
        await _apiKeyService.setApiKey(event.apiKey);

        emit(
          ApiKeyValid(
            apiKey: event.apiKey,
            validatedAt: DateTime.now(),
            validationDetails: {
              'method': 'gemini_test',
              'timestamp': DateTime.now().toIso8601String(),
            },
          ),
        );

        // Update to loaded state
        emit(
          ApiKeyLoaded(
            apiKey: event.apiKey,
            isValid: true,
            hasCompletedSetup: _apiKeyService.hasCompletedSetup,
            lastValidated: DateTime.now(),
          ),
        );

        // Log successful validation
        add(
          LogApiKeyUsage(
            operation: 'validation',
            success: true,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        emit(
          ApiKeyInvalid(
            apiKey: event.apiKey,
            reason: 'API key validation failed',
            invalidatedAt: DateTime.now(),
          ),
        );

        // Log failed validation
        add(
          LogApiKeyUsage(
            operation: 'validation',
            success: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      emit(
        ApiKeyError(
          message: 'Validation failed: ${e.toString()}',
          apiKey: event.apiKey,
        ),
      );

      // Log validation error
      add(
        LogApiKeyUsage(
          operation: 'validation',
          success: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onClearApiKey(
    ClearApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      await _apiKeyService.clearApiKey();

      emit(ApiKeyCleared(clearedAt: DateTime.now()));
      emit(const ApiKeyEmpty());
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onLoadApiKey(
    LoadApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    add(const InitializeApiKey());
  }

  Future<void> _onSaveApiKey(
    SaveApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    add(SetApiKey(apiKey: event.apiKey));
  }

  Future<void> _onTestApiKeyConnection(
    TestApiKeyConnection event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      emit(ApiKeyTesting(apiKey: event.apiKey));

      final geminiService = GeminiService();
      final testResult = await geminiService.testConnection(event.apiKey);

      if (testResult['success'] == true) {
        emit(
          ApiKeyTestSuccess(
            apiKey: event.apiKey,
            testedAt: DateTime.now(),
            testResults: testResult,
          ),
        );

        // Log successful test
        add(
          LogApiKeyUsage(
            operation: 'connection_test',
            success: true,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        emit(
          ApiKeyTestFailure(
            apiKey: event.apiKey,
            reason: testResult['error'] ?? 'Connection test failed',
            testedAt: DateTime.now(),
          ),
        );

        // Log failed test
        add(
          LogApiKeyUsage(
            operation: 'connection_test',
            success: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      emit(
        ApiKeyTestFailure(
          apiKey: event.apiKey,
          reason: e.toString(),
          testedAt: DateTime.now(),
        ),
      );

      // Log test error
      add(
        LogApiKeyUsage(
          operation: 'connection_test',
          success: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onCompleteSetup(
    CompleteSetup event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      await _apiKeyService.completeSetup();

      emit(
        ApiKeySetupCompleted(
          apiKey: _apiKeyService.apiKey ?? '',
          completedAt: DateTime.now(),
        ),
      );

      // Return to loaded state
      if (_apiKeyService.hasApiKey) {
        emit(
          ApiKeyLoaded(
            apiKey: _apiKeyService.apiKey!,
            isValid: _apiKeyService.isValid,
            hasCompletedSetup: true,
            lastValidated: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onResetSetup(
    ResetSetup event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      await _apiKeyService.resetSetup();

      emit(ApiKeySetupReset(resetAt: DateTime.now()));
      emit(const ApiKeyEmpty());
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onUpdateApiKeySettings(
    UpdateApiKeySettings event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      final settings = {
        'autoValidate': event.autoValidate,
        'saveSecurely': event.saveSecurely,
        'validationTimeout': event.validationTimeout.inSeconds,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, json.encode(settings));

      emit(
        ApiKeySettingsUpdated(
          autoValidate: event.autoValidate,
          saveSecurely: event.saveSecurely,
          validationTimeout: event.validationTimeout,
          updatedAt: DateTime.now(),
        ),
      );

      // Update current state if loaded
      if (state is ApiKeyLoaded) {
        final currentState = state as ApiKeyLoaded;
        emit(
          currentState.copyWith(
            autoValidate: event.autoValidate,
            saveSecurely: event.saveSecurely,
            validationTimeout: event.validationTimeout,
          ),
        );
      }
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onRefreshApiKeyStatus(
    RefreshApiKeyStatus event,
    Emitter<ApiKeyState> emit,
  ) async {
    if (state is ApiKeyLoaded) {
      final currentState = state as ApiKeyLoaded;
      if (currentState.needsValidation) {
        add(ValidateApiKey(apiKey: currentState.apiKey));
      }
    }
  }

  Future<void> _onHandleApiKeyError(
    HandleApiKeyError event,
    Emitter<ApiKeyState> emit,
  ) async {
    emit(ApiKeyError(message: event.error, errorCode: event.errorCode));

    // Log error
    add(
      LogApiKeyUsage(
        operation: 'error_handling',
        success: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _onBackupApiKey(
    BackupApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      if (state is ApiKeyLoaded) {
        final currentState = state as ApiKeyLoaded;
        final backupId = DateTime.now().millisecondsSinceEpoch.toString();

        final backupData = {
          'apiKey': currentState.apiKey,
          'isValid': currentState.isValid,
          'hasCompletedSetup': currentState.hasCompletedSetup,
          'lastValidated': currentState.lastValidated?.toIso8601String(),
          'backupId': backupId,
          'backupTime': DateTime.now().toIso8601String(),
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'api_key_backup_$backupId',
          json.encode(backupData),
        );

        emit(ApiKeyBackedUp(backupTime: DateTime.now(), backupId: backupId));
      }
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onRestoreApiKey(
    RestoreApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      final backupData = json.decode(event.backupData);
      final apiKey = backupData['apiKey'] as String;
      final backupId = backupData['backupId'] as String;

      await _apiKeyService.setApiKey(apiKey);

      emit(
        ApiKeyRestored(
          apiKey: apiKey,
          restoreTime: DateTime.now(),
          backupId: backupId,
        ),
      );

      // Validate restored API key
      add(ValidateApiKey(apiKey: apiKey));
    } catch (e) {
      emit(ApiKeyError(message: 'Failed to restore API key: ${e.toString()}'));
    }
  }

  Future<void> _onCheckApiKeyExpiry(
    CheckApiKeyExpiry event,
    Emitter<ApiKeyState> emit,
  ) async {
    if (state is ApiKeyLoaded) {
      final currentState = state as ApiKeyLoaded;

      // Check if API key needs validation (simple expiry check)
      if (currentState.needsValidation) {
        emit(
          ApiKeyExpired(
            apiKey: currentState.apiKey,
            expiredAt: DateTime.now(),
            reason: 'API key validation expired',
          ),
        );

        // Auto-validate if enabled
        if (currentState.autoValidate) {
          add(ValidateApiKey(apiKey: currentState.apiKey));
        }
      }
    }
  }

  Future<void> _onRenewApiKey(
    RenewApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      String? oldApiKey;
      if (state is ApiKeyLoaded) {
        oldApiKey = (state as ApiKeyLoaded).apiKey;
      }

      await _apiKeyService.setApiKey(event.newApiKey);

      emit(
        ApiKeyRenewed(
          oldApiKey: oldApiKey ?? '',
          newApiKey: event.newApiKey,
          renewedAt: DateTime.now(),
        ),
      );

      // Validate new API key
      add(ValidateApiKey(apiKey: event.newApiKey));
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onEnableApiKeyAutoRefresh(
    EnableApiKeyAutoRefresh event,
    Emitter<ApiKeyState> emit,
  ) async {
    // This would typically set up a timer for auto-refresh
    // For now, just update settings
    add(
      UpdateApiKeySettings(
        autoValidate: event.enabled,
        validationTimeout: event.refreshInterval,
      ),
    );
  }

  Future<void> _onLogApiKeyUsage(
    LogApiKeyUsage event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      _totalRequests++;
      if (event.success) {
        _successfulRequests++;
      } else {
        _failedRequests++;
      }

      _operationCounts[event.operation] =
          (_operationCounts[event.operation] ?? 0) + 1;

      _firstUsage ??= event.timestamp;
      _lastUsage = event.timestamp;

      await _saveUsageStats();

      emit(
        ApiKeyUsageLogged(
          operation: event.operation,
          success: event.success,
          timestamp: event.timestamp,
        ),
      );
    } catch (e) {
      // Handle error silently for usage logging
    }
  }

  Future<void> _onGetApiKeyUsageStats(
    GetApiKeyUsageStats event,
    Emitter<ApiKeyState> emit,
  ) async {
    await _loadUsageStats();

    emit(
      ApiKeyUsageStats(
        totalRequests: _totalRequests,
        successfulRequests: _successfulRequests,
        failedRequests: _failedRequests,
        firstUsage: _firstUsage ?? DateTime.now(),
        lastUsage: _lastUsage ?? DateTime.now(),
        operationCounts: Map.from(_operationCounts),
      ),
    );
  }

  Future<void> _onClearApiKeyUsageStats(
    ClearApiKeyUsageStats event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      _totalRequests = 0;
      _successfulRequests = 0;
      _failedRequests = 0;
      _operationCounts.clear();
      _firstUsage = null;
      _lastUsage = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usageStatsKey);

      emit(
        ApiKeyUsageStats(
          totalRequests: 0,
          successfulRequests: 0,
          failedRequests: 0,
          firstUsage: DateTime.now(),
          lastUsage: DateTime.now(),
          operationCounts: {},
        ),
      );
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onSetApiKeyFromQR(
    SetApiKeyFromQR event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      // Parse QR data (assuming it contains the API key)
      String apiKey;
      try {
        final qrData = json.decode(event.qrData);
        apiKey = qrData['apiKey'] ?? event.qrData;
      } catch (e) {
        // If not JSON, treat as plain API key
        apiKey = event.qrData;
      }

      emit(ApiKeyFromQRSet(apiKey: apiKey, setAt: DateTime.now()));

      add(SetApiKey(apiKey: apiKey));
    } catch (e) {
      emit(
        ApiKeyError(message: 'Failed to set API key from QR: ${e.toString()}'),
      );
    }
  }

  Future<void> _onGenerateApiKeyQR(
    GenerateApiKeyQR event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      if (state is ApiKeyLoaded) {
        final currentState = state as ApiKeyLoaded;

        final qrData = json.encode({
          'apiKey': currentState.apiKey,
          'timestamp': DateTime.now().toIso8601String(),
          'app': 'Aqar Zone',
        });

        emit(ApiKeyQRGenerated(qrData: qrData, generatedAt: DateTime.now()));
      }
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onExportApiKeySettings(
    ExportApiKeySettings event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      if (state is ApiKeyLoaded) {
        final currentState = state as ApiKeyLoaded;

        final exportedSettings = {
          'autoValidate': currentState.autoValidate,
          'saveSecurely': currentState.saveSecurely,
          'validationTimeout': currentState.validationTimeout.inSeconds,
          'hasCompletedSetup': currentState.hasCompletedSetup,
          'exportTime': DateTime.now().toIso8601String(),
          'version': '1.0',
        };

        emit(
          ApiKeySettingsExported(
            exportedSettings: exportedSettings,
            exportTime: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      emit(ApiKeyError(message: e.toString()));
    }
  }

  Future<void> _onImportApiKeySettings(
    ImportApiKeySettings event,
    Emitter<ApiKeyState> emit,
  ) async {
    try {
      emit(
        ApiKeySettingsImported(
          importedSettings: event.settings,
          importTime: DateTime.now(),
        ),
      );

      // Apply imported settings
      final autoValidate = event.settings['autoValidate'] ?? true;
      final saveSecurely = event.settings['saveSecurely'] ?? true;
      final timeoutSeconds = event.settings['validationTimeout'] ?? 10;

      add(
        UpdateApiKeySettings(
          autoValidate: autoValidate,
          saveSecurely: saveSecurely,
          validationTimeout: Duration(seconds: timeoutSeconds),
        ),
      );
    } catch (e) {
      emit(ApiKeyError(message: 'Failed to import settings: ${e.toString()}'));
    }
  }

  // Helper methods
  bool _isValidApiKeyFormat(String apiKey) {
    // Basic validation for Gemini API key format
    return apiKey.length >= 20 && apiKey.contains(RegExp(r'^[A-Za-z0-9_-]+$'));
  }

  Future<void> _saveUsageStats() async {
    try {
      final stats = {
        'totalRequests': _totalRequests,
        'successfulRequests': _successfulRequests,
        'failedRequests': _failedRequests,
        'operationCounts': _operationCounts,
        'firstUsage': _firstUsage?.toIso8601String(),
        'lastUsage': _lastUsage?.toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usageStatsKey, json.encode(stats));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_usageStatsKey);

      if (statsJson != null) {
        final stats = json.decode(statsJson);
        _totalRequests = stats['totalRequests'] ?? 0;
        _successfulRequests = stats['successfulRequests'] ?? 0;
        _failedRequests = stats['failedRequests'] ?? 0;
        _operationCounts = Map<String, int>.from(
          stats['operationCounts'] ?? {},
        );

        if (stats['firstUsage'] != null) {
          _firstUsage = DateTime.parse(stats['firstUsage']);
        }
        if (stats['lastUsage'] != null) {
          _lastUsage = DateTime.parse(stats['lastUsage']);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
