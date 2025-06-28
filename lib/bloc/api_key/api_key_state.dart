import 'package:equatable/equatable.dart';

abstract class ApiKeyState extends Equatable {
  const ApiKeyState();

  @override
  List<Object?> get props => [];
}

class ApiKeyInitial extends ApiKeyState {
  const ApiKeyInitial();
}

class ApiKeyLoading extends ApiKeyState {
  const ApiKeyLoading();
}

class ApiKeyLoaded extends ApiKeyState {
  final String apiKey;
  final bool isValid;
  final bool hasCompletedSetup;
  final DateTime? lastValidated;
  final bool autoValidate;
  final bool saveSecurely;
  final Duration validationTimeout;

  const ApiKeyLoaded({
    required this.apiKey,
    required this.isValid,
    required this.hasCompletedSetup,
    this.lastValidated,
    this.autoValidate = true,
    this.saveSecurely = true,
    this.validationTimeout = const Duration(seconds: 10),
  });

  ApiKeyLoaded copyWith({
    String? apiKey,
    bool? isValid,
    bool? hasCompletedSetup,
    DateTime? lastValidated,
    bool? autoValidate,
    bool? saveSecurely,
    Duration? validationTimeout,
  }) {
    return ApiKeyLoaded(
      apiKey: apiKey ?? this.apiKey,
      isValid: isValid ?? this.isValid,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      lastValidated: lastValidated ?? this.lastValidated,
      autoValidate: autoValidate ?? this.autoValidate,
      saveSecurely: saveSecurely ?? this.saveSecurely,
      validationTimeout: validationTimeout ?? this.validationTimeout,
    );
  }

  String get maskedApiKey {
    if (apiKey.length <= 8) return '*' * apiKey.length;
    return '${apiKey.substring(0, 4)}${'*' * (apiKey.length - 8)}${apiKey.substring(apiKey.length - 4)}';
  }

  bool get needsValidation {
    if (lastValidated == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastValidated!);
    return difference.inHours >= 24; // Validate every 24 hours
  }

  @override
  List<Object?> get props => [
    apiKey,
    isValid,
    hasCompletedSetup,
    lastValidated,
    autoValidate,
    saveSecurely,
    validationTimeout,
  ];
}

class ApiKeyEmpty extends ApiKeyState {
  final bool hasCompletedSetup;

  const ApiKeyEmpty({this.hasCompletedSetup = false});

  @override
  List<Object?> get props => [hasCompletedSetup];
}

class ApiKeyValidating extends ApiKeyState {
  final String apiKey;

  const ApiKeyValidating({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

class ApiKeyValid extends ApiKeyState {
  final String apiKey;
  final DateTime validatedAt;
  final Map<String, dynamic>? validationDetails;

  const ApiKeyValid({
    required this.apiKey,
    required this.validatedAt,
    this.validationDetails,
  });

  @override
  List<Object?> get props => [apiKey, validatedAt, validationDetails];
}

class ApiKeyInvalid extends ApiKeyState {
  final String apiKey;
  final String reason;
  final String? errorCode;
  final DateTime invalidatedAt;

  const ApiKeyInvalid({
    required this.apiKey,
    required this.reason,
    this.errorCode,
    required this.invalidatedAt,
  });

  @override
  List<Object?> get props => [apiKey, reason, errorCode, invalidatedAt];
}

class ApiKeyError extends ApiKeyState {
  final String message;
  final String? errorCode;
  final String? apiKey;

  const ApiKeyError({
    required this.message,
    this.errorCode,
    this.apiKey,
  });

  @override
  List<Object?> get props => [message, errorCode, apiKey];
}

class ApiKeySetupCompleted extends ApiKeyState {
  final String apiKey;
  final DateTime completedAt;

  const ApiKeySetupCompleted({
    required this.apiKey,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [apiKey, completedAt];
}

class ApiKeySetupReset extends ApiKeyState {
  final DateTime resetAt;

  const ApiKeySetupReset({required this.resetAt});

  @override
  List<Object?> get props => [resetAt];
}

class ApiKeyTesting extends ApiKeyState {
  final String apiKey;

  const ApiKeyTesting({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

class ApiKeyTestSuccess extends ApiKeyState {
  final String apiKey;
  final DateTime testedAt;
  final Map<String, dynamic>? testResults;

  const ApiKeyTestSuccess({
    required this.apiKey,
    required this.testedAt,
    this.testResults,
  });

  @override
  List<Object?> get props => [apiKey, testedAt, testResults];
}

class ApiKeyTestFailure extends ApiKeyState {
  final String apiKey;
  final String reason;
  final DateTime testedAt;

  const ApiKeyTestFailure({
    required this.apiKey,
    required this.reason,
    required this.testedAt,
  });

  @override
  List<Object?> get props => [apiKey, reason, testedAt];
}

class ApiKeySaved extends ApiKeyState {
  final String apiKey;
  final DateTime savedAt;
  final bool securelyStored;

  const ApiKeySaved({
    required this.apiKey,
    required this.savedAt,
    required this.securelyStored,
  });

  @override
  List<Object?> get props => [apiKey, savedAt, securelyStored];
}

class ApiKeyCleared extends ApiKeyState {
  final DateTime clearedAt;

  const ApiKeyCleared({required this.clearedAt});

  @override
  List<Object?> get props => [clearedAt];
}

class ApiKeySettingsUpdated extends ApiKeyState {
  final bool autoValidate;
  final bool saveSecurely;
  final Duration validationTimeout;
  final DateTime updatedAt;

  const ApiKeySettingsUpdated({
    required this.autoValidate,
    required this.saveSecurely,
    required this.validationTimeout,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [autoValidate, saveSecurely, validationTimeout, updatedAt];
}

class ApiKeyBackedUp extends ApiKeyState {
  final DateTime backupTime;
  final String backupId;

  const ApiKeyBackedUp({
    required this.backupTime,
    required this.backupId,
  });

  @override
  List<Object?> get props => [backupTime, backupId];
}

class ApiKeyRestored extends ApiKeyState {
  final String apiKey;
  final DateTime restoreTime;
  final String backupId;

  const ApiKeyRestored({
    required this.apiKey,
    required this.restoreTime,
    required this.backupId,
  });

  @override
  List<Object?> get props => [apiKey, restoreTime, backupId];
}

class ApiKeyExpired extends ApiKeyState {
  final String apiKey;
  final DateTime expiredAt;
  final String reason;

  const ApiKeyExpired({
    required this.apiKey,
    required this.expiredAt,
    required this.reason,
  });

  @override
  List<Object?> get props => [apiKey, expiredAt, reason];
}

class ApiKeyRenewed extends ApiKeyState {
  final String oldApiKey;
  final String newApiKey;
  final DateTime renewedAt;

  const ApiKeyRenewed({
    required this.oldApiKey,
    required this.newApiKey,
    required this.renewedAt,
  });

  @override
  List<Object?> get props => [oldApiKey, newApiKey, renewedAt];
}

class ApiKeyUsageLogged extends ApiKeyState {
  final String operation;
  final bool success;
  final DateTime timestamp;

  const ApiKeyUsageLogged({
    required this.operation,
    required this.success,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [operation, success, timestamp];
}

class ApiKeyUsageStats extends ApiKeyState {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final DateTime firstUsage;
  final DateTime lastUsage;
  final Map<String, int> operationCounts;

  const ApiKeyUsageStats({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.firstUsage,
    required this.lastUsage,
    required this.operationCounts,
  });

  double get successRate {
    if (totalRequests == 0) return 0.0;
    return successfulRequests / totalRequests;
  }

  @override
  List<Object?> get props => [
    totalRequests,
    successfulRequests,
    failedRequests,
    firstUsage,
    lastUsage,
    operationCounts,
  ];
}

class ApiKeyQRGenerated extends ApiKeyState {
  final String qrData;
  final DateTime generatedAt;

  const ApiKeyQRGenerated({
    required this.qrData,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [qrData, generatedAt];
}

class ApiKeyFromQRSet extends ApiKeyState {
  final String apiKey;
  final DateTime setAt;

  const ApiKeyFromQRSet({
    required this.apiKey,
    required this.setAt,
  });

  @override
  List<Object?> get props => [apiKey, setAt];
}

class ApiKeySettingsExported extends ApiKeyState {
  final Map<String, dynamic> exportedSettings;
  final DateTime exportTime;

  const ApiKeySettingsExported({
    required this.exportedSettings,
    required this.exportTime,
  });

  @override
  List<Object?> get props => [exportedSettings, exportTime];
}

class ApiKeySettingsImported extends ApiKeyState {
  final Map<String, dynamic> importedSettings;
  final DateTime importTime;

  const ApiKeySettingsImported({
    required this.importedSettings,
    required this.importTime,
  });

  @override
  List<Object?> get props => [importedSettings, importTime];
}
