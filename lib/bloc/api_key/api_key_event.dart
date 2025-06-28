import 'package:equatable/equatable.dart';

abstract class ApiKeyEvent extends Equatable {
  const ApiKeyEvent();

  @override
  List<Object?> get props => [];
}

class InitializeApiKey extends ApiKeyEvent {
  const InitializeApiKey();
}

class SetApiKey extends ApiKeyEvent {
  final String apiKey;

  const SetApiKey({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

class ValidateApiKey extends ApiKeyEvent {
  final String apiKey;

  const ValidateApiKey({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

class ClearApiKey extends ApiKeyEvent {
  const ClearApiKey();
}

class LoadApiKey extends ApiKeyEvent {
  const LoadApiKey();
}

class SaveApiKey extends ApiKeyEvent {
  final String apiKey;

  const SaveApiKey({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

class TestApiKeyConnection extends ApiKeyEvent {
  final String apiKey;

  const TestApiKeyConnection({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

class CompleteSetup extends ApiKeyEvent {
  const CompleteSetup();
}

class ResetSetup extends ApiKeyEvent {
  const ResetSetup();
}

class UpdateApiKeySettings extends ApiKeyEvent {
  final bool autoValidate;
  final bool saveSecurely;
  final Duration validationTimeout;

  const UpdateApiKeySettings({
    this.autoValidate = true,
    this.saveSecurely = true,
    this.validationTimeout = const Duration(seconds: 10),
  });

  @override
  List<Object?> get props => [autoValidate, saveSecurely, validationTimeout];
}

class RefreshApiKeyStatus extends ApiKeyEvent {
  const RefreshApiKeyStatus();
}

class HandleApiKeyError extends ApiKeyEvent {
  final String error;
  final String? errorCode;

  const HandleApiKeyError({
    required this.error,
    this.errorCode,
  });

  @override
  List<Object?> get props => [error, errorCode];
}

class BackupApiKey extends ApiKeyEvent {
  const BackupApiKey();
}

class RestoreApiKey extends ApiKeyEvent {
  final String backupData;

  const RestoreApiKey({required this.backupData});

  @override
  List<Object?> get props => [backupData];
}

class CheckApiKeyExpiry extends ApiKeyEvent {
  const CheckApiKeyExpiry();
}

class RenewApiKey extends ApiKeyEvent {
  final String newApiKey;

  const RenewApiKey({required this.newApiKey});

  @override
  List<Object?> get props => [newApiKey];
}

class EnableApiKeyAutoRefresh extends ApiKeyEvent {
  final bool enabled;
  final Duration refreshInterval;

  const EnableApiKeyAutoRefresh({
    required this.enabled,
    this.refreshInterval = const Duration(days: 30),
  });

  @override
  List<Object?> get props => [enabled, refreshInterval];
}

class LogApiKeyUsage extends ApiKeyEvent {
  final String operation;
  final bool success;
  final DateTime timestamp;

  const LogApiKeyUsage({
    required this.operation,
    required this.success,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [operation, success, timestamp];
}

class GetApiKeyUsageStats extends ApiKeyEvent {
  const GetApiKeyUsageStats();
}

class ClearApiKeyUsageStats extends ApiKeyEvent {
  const ClearApiKeyUsageStats();
}

class SetApiKeyFromQR extends ApiKeyEvent {
  final String qrData;

  const SetApiKeyFromQR({required this.qrData});

  @override
  List<Object?> get props => [qrData];
}

class GenerateApiKeyQR extends ApiKeyEvent {
  const GenerateApiKeyQR();
}

class ExportApiKeySettings extends ApiKeyEvent {
  const ExportApiKeySettings();
}

class ImportApiKeySettings extends ApiKeyEvent {
  final Map<String, dynamic> settings;

  const ImportApiKeySettings({required this.settings});

  @override
  List<Object?> get props => [settings];
}
