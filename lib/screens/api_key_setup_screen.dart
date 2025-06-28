import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_key_service.dart';
import '../services/AI/gemini_service.dart';

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
    _apiKeyController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _testApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (!ApiKeyService.isValidApiKeyFormat(apiKey)) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Invalid API key format. Gemini API keys should start with "AIza".';
        });
      }
      return;
    }

    if (mounted) {
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
          hasReceivedResponse = true;
          testResponse += chunk;
        },
      );

      if (hasReceivedResponse && testResponse.isNotEmpty) {
        // API key works, save it and complete setup
        await _saveAndComplete(apiKey);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No response received. Please check your API key.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
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
      if (mounted) {
        setState(() {
          _isTestingKey = false;
        });
      }
    }
  }

  Future<void> _saveAndComplete(String apiKey) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final success = await _apiKeyService.saveApiKey(apiKey);

    if (success) {
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

      if (mounted && widget.onSetupComplete != null) {
        widget.onSetupComplete!();
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save API key. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _skipSetup() {
    _apiKeyService.markSetupCompleted();
    if (widget.onSetupComplete != null) {
      widget.onSetupComplete!();
    }
  }

  Future<void> _scanQRCode() async {
    try {
      // Show QR scanner screen
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (result != null && result.isNotEmpty) {
        // Validate if the scanned result looks like an API key
        if (ApiKeyService.isValidApiKeyFormat(result)) {
          if (mounted) {
            setState(() {
              _apiKeyController.text = result;
              _errorMessage = null;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ API key scanned successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Scanned QR code does not contain a valid API key format.';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to scan QR code. Please try again.';
        });
      }
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
                                            if (mounted) {
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
                                        if (_errorMessage != null && mounted) {
                                          setState(() {
                                            _errorMessage = null;
                                          });
                                        }
                                      },
                                      onSubmitted: (_) => _testApiKey(),
                                    ),

                                    const SizedBox(height: 16),

                                    // QR Code Scanner Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed:
                                            _isLoading || _isTestingKey
                                                ? null
                                                : _scanQRCode,
                                        icon: Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: theme.colorScheme.primary,
                                        ),
                                        label: Text(
                                          'Scan QR Code',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.5),
                                          ),
                                          backgroundColor: theme
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.05),
                                        ),
                                      ),
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

// QR Scanner Screen with real camera functionality
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final TextEditingController _manualInputController = TextEditingController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }

        // Vibrate to indicate successful scan
        HapticFeedback.mediumImpact();

        // Return the scanned code
        if (mounted) {
          Navigator.of(context).pop(code);
        }
      }
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter API Key Manually'),
            content: TextField(
              controller: _manualInputController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Paste your API key here',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final apiKey = _manualInputController.text.trim();
                  if (apiKey.isNotEmpty) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(apiKey);
                  }
                },
                child: const Text('Use This Key'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded),
            onPressed: _showManualInputDialog,
            tooltip: 'Enter manually',
          ),
          IconButton(
            icon: Icon(
              _isScanning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _isScanning = !_isScanning;
                });
                if (_isScanning) {
                  cameraController.start();
                } else {
                  cameraController.stop();
                }
              }
            },
            tooltip: _isScanning ? 'Pause scanning' : 'Resume scanning',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mobile Scanner Camera View
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // Scanning overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scanning frame with corner indicators
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      children: [
                        // Transparent center for camera view
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        // Corner indicators
                        ...List.generate(4, (index) {
                          return Positioned(
                            top: index < 2 ? 0 : null,
                            bottom: index >= 2 ? 0 : null,
                            left: index % 2 == 0 ? 0 : null,
                            right: index % 2 == 1 ? 0 : null,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  top:
                                      index < 2
                                          ? BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 4,
                                          )
                                          : BorderSide.none,
                                  bottom:
                                      index >= 2
                                          ? BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 4,
                                          )
                                          : BorderSide.none,
                                  left:
                                      index % 2 == 0
                                          ? BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 4,
                                          )
                                          : BorderSide.none,
                                  right:
                                      index % 2 == 1
                                          ? BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 4,
                                          )
                                          : BorderSide.none,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Instructions
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isScanning
                              ? 'Scanning for QR Code...'
                              : 'Scanning Paused',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Position the QR code within the frame. The API key will be detected automatically.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showManualInputDialog,
                icon: const Icon(Icons.keyboard_rounded),
                label: const Text('Enter API Key Manually'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Position the QR code within the frame to scan',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
