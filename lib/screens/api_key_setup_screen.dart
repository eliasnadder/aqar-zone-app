import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_key_service.dart';
import '../services/gemini_service.dart';

class ApiKeySetupScreen extends StatefulWidget {
  final VoidCallback? onSetupComplete;

  const ApiKeySetupScreen({Key? key, this.onSetupComplete}) : super(key: key);

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _apiKeyController = TextEditingController();
  final ApiKeyService _apiKeyService = ApiKeyService.instance;

  bool _obscureApiKey = true;
  bool _isLoading = false;
  bool _isTestingKey = false;
  String? _errorMessage;
  bool _disposed = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _apiKeyController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _testApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (!ApiKeyService.isValidApiKeyFormat(apiKey)) {
      if (!_disposed && mounted) {
        setState(() {
          _errorMessage =
              'Invalid API key format. Gemini API keys should start with "AIza".';
        });
      }
      return;
    }

    if (!_disposed && mounted) {
      setState(() {
        _isTestingKey = true;
        _errorMessage = null;
      });
    }

    try {
      String testResponse = '';
      bool hasReceivedResponse = false;

      await GeminiService.testApiKey(
        apiKey: apiKey,
        onChunk: (chunk) {
          if (!_disposed && mounted) {
            hasReceivedResponse = true;
            testResponse += chunk;
          }
        },
      );

      if (!_disposed && hasReceivedResponse && testResponse.isNotEmpty) {
        // API key works, save it and complete setup
        await _saveAndComplete(apiKey);
      } else if (!_disposed && mounted) {
        setState(() {
          _errorMessage = 'No response received. Please check your API key.';
        });
      }
    } catch (error) {
      if (!_disposed && mounted) {
        setState(() {
          if (error.toString().contains('Invalid API Key format')) {
            _errorMessage = 'API key format is invalid.';
          } else if (error.toString().contains('HTTP 400')) {
            _errorMessage = 'Invalid API key. Please check your key.';
          } else if (error.toString().contains('HTTP 403')) {
            _errorMessage = 'API key access denied. Check permissions.';
          } else {
            _errorMessage =
                'Failed to validate API key. Check your internet connection.';
          }
        });
      }
    } finally {
      if (!_disposed && mounted) {
        setState(() {
          _isTestingKey = false;
        });
      }
    }
  }

  Future<void> _saveAndComplete(String apiKey) async {
    if (!_disposed && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final success = await _apiKeyService.saveApiKey(apiKey);

    if (!_disposed && success) {
      // Show success message briefly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API key saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Wait a moment then complete setup
      await Future.delayed(const Duration(milliseconds: 500));

      if (!_disposed && mounted && widget.onSetupComplete != null) {
        widget.onSetupComplete!();
      }
    } else if (!_disposed && mounted) {
      setState(() {
        _errorMessage = 'Failed to save API key. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _skipSetup() {
    _apiKeyService.markSetupCompleted();
    if (!_disposed && mounted && widget.onSetupComplete != null) {
      widget.onSetupComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Logo/Icon
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.smart_toy_rounded,
                                  size: 64,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Welcome Text
                              Text(
                                'Welcome to Casa AI',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'To get started, please enter your Gemini API key.\nThis will enable AI-powered property assistance.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 48),

                              // API Key Input
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _apiKeyController,
                                      decoration: InputDecoration(
                                        labelText: 'Gemini API Key',
                                        hintText:
                                            'Enter your API key (AIza...)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: theme.colorScheme.surface,
                                        prefixIcon: Icon(
                                          Icons.key_rounded,
                                          color: theme.colorScheme.primary,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureApiKey
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                          ),
                                          onPressed: () {
                                            if (!_disposed && mounted) {
                                              setState(() {
                                                _obscureApiKey =
                                                    !_obscureApiKey;
                                              });
                                            }
                                          },
                                          tooltip:
                                              _obscureApiKey
                                                  ? 'Show API key'
                                                  : 'Hide API key',
                                        ),
                                        errorText: _errorMessage,
                                      ),
                                      obscureText: _obscureApiKey,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                      ),
                                      onChanged: (value) {
                                        if (_errorMessage != null &&
                                            !_disposed &&
                                            mounted) {
                                          setState(() {
                                            _errorMessage = null;
                                          });
                                        }
                                      },
                                      onSubmitted: (_) => _testApiKey(),
                                    ),

                                    const SizedBox(height: 24),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                _isLoading || _isTestingKey
                                                    ? null
                                                    : _skipSetup,
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Skip for now'),
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                _isLoading ||
                                                        _isTestingKey ||
                                                        _apiKeyController.text
                                                            .trim()
                                                            .isEmpty
                                                    ? null
                                                    : _testApiKey,
                                            icon:
                                                _isTestingKey || _isLoading
                                                    ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : const Icon(
                                                      Icons
                                                          .check_circle_outline_rounded,
                                                    ),
                                            label: Text(
                                              _isTestingKey
                                                  ? 'Testing...'
                                                  : _isLoading
                                                  ? 'Saving...'
                                                  : 'Save & Continue',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Help Text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Get your free API key from Google AI Studio (ai.google.dev)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
