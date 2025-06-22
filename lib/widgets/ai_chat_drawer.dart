import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../services/ai_suggestions_service.dart';
import '../services/api_key_service.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/enhanced_chat_input.dart';
import '../widgets/enhanced_empty_state.dart';

class AIChatDrawer extends StatefulWidget {
  final Property property;

  const AIChatDrawer({Key? key, required this.property}) : super(key: key);

  @override
  State<AIChatDrawer> createState() => _AIChatDrawerState();
}

class _AIChatDrawerState extends State<AIChatDrawer> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiKeyService _apiKeyService = ApiKeyService.instance;
  bool _isLoading = false;
  List<String> _aiSuggestions = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loadingSuggestions = true;
    });

    try {
      final suggestions =
          await AISuggestionsService.getCachedSuggestionsWithGlobalKey(
            property: widget.property,
          );

      setState(() {
        _aiSuggestions = suggestions;
        _loadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _aiSuggestions = AISuggestionsService.getFallbackSuggestions(
          widget.property,
        );
        _loadingSuggestions = false;
      });
    }
  }

  Future<void> _refreshSuggestions() async {
    if (!_apiKeyService.isApiKeyAvailable()) return;

    setState(() {
      _loadingSuggestions = true;
    });

    try {
      final suggestions =
          await AISuggestionsService.refreshSuggestionsWithGlobalKey(
            property: widget.property,
          );

      setState(() {
        _aiSuggestions = suggestions;
        _loadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _loadingSuggestions = false;
      });
    }
  }

  void _onSuggestionTap(String suggestion) {
    if (!_apiKeyService.isApiKeyAvailable()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up your API key first to use suggestions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Set the suggestion in the text field and send it
    _messageController.text = suggestion;
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || !_apiKeyService.isApiKeyAvailable() || _isLoading) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(sender: MessageSender.user, text: message));
      _messages.add(
        ChatMessage(sender: MessageSender.ai, text: '', isLoading: true),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String aiResponse = '';
      bool hasReceivedResponse = false;

      await GeminiService.runChatWithGlobalKey(
        property: widget.property,
        question: message,
        onChunk: (chunk) {
          hasReceivedResponse = true;
          setState(() {
            aiResponse += chunk;
            _messages[_messages.length - 1] = ChatMessage(
              sender: MessageSender.ai,
              text: aiResponse,
            );
          });
          _scrollToBottom();
        },
      );

      // If no response was received, show a helpful message
      if (!hasReceivedResponse) {
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            sender: MessageSender.ai,
            text:
                'I didn\'t receive a response. Please check your API key and internet connection, then try again.',
          );
        });
      }
    } catch (error) {
      String errorMessage = 'Sorry, I encountered an error. ';

      final errorString = error.toString();

      if (errorString.contains('Invalid API Key format')) {
        errorMessage +=
            'Your API key should start with "AIza". Please check your API key format.';
      } else if (errorString.contains('HTTP 400') ||
          errorString.contains('API_KEY_INVALID')) {
        errorMessage +=
            'Your API key appears to be invalid. Please check your API key.';
      } else if (errorString.contains('HTTP 403') ||
          errorString.contains('insufficient permissions')) {
        errorMessage +=
            'Access denied. Your API key may not have the required permissions for Gemini API.';
      } else if (errorString.contains('HTTP 429') ||
          errorString.contains('Rate limit')) {
        errorMessage +=
            'Too many requests. Please wait a moment and try again.';
      } else if (errorString.contains('safety filters') ||
          errorString.contains('SAFETY')) {
        errorMessage +=
            'Your message was blocked by safety filters. Please try rephrasing your question.';
      } else if (errorString.contains('BLOCKED')) {
        errorMessage += 'Content was blocked. Please try a different question.';
      } else if (errorString.contains('No valid response')) {
        errorMessage +=
            'The AI didn\'t provide a response. This might be due to content restrictions or API issues.';
      } else if (errorString.contains('Failed to generate content')) {
        errorMessage +=
            'Unable to generate a response. Please check your API key and internet connection.';
      } else {
        errorMessage +=
            'Please check your internet connection and API key, then try again.';
      }

      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          sender: MessageSender.ai,
          text: errorMessage,
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCompactHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Casa AI Avatar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Title and Property Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Casa AI',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ask me about: ${widget.property.title}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${widget.property.price} ${widget.property.currency}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Refresh Suggestions Button
          if (_apiKeyService.isApiKeyAvailable()) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: !_loadingSuggestions ? _refreshSuggestions : null,
              icon: Icon(
                _loadingSuggestions
                    ? Icons.hourglass_empty_rounded
                    : Icons.refresh_rounded,
                size: 20,
              ),
              tooltip: 'Refresh suggestions',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer
                    .withValues(alpha: 0.5),
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],

          // Close Button
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _buildCompactHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child:
                          _messages.isEmpty
                              ? EnhancedEmptyState(
                                title: 'Welcome to Casa AI',
                                subtitle: 'Ask me about: ',
                                subtitle2: widget.property.title,
                                icon: Icons.home_rounded,
                                suggestions: _aiSuggestions,
                                onSuggestionTap: _onSuggestionTap,
                                isLoading: _loadingSuggestions,
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                itemCount: _messages.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemBuilder: (context, index) {
                                  return ChatMessageWidget(
                                    message: _messages[index],
                                    index: index,
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: EnhancedChatInput(
                  messageController: _messageController,
                  onSendMessage: _sendMessage,
                  isLoading: _isLoading,
                  isEnabled: !_isLoading && _apiKeyService.isApiKeyAvailable(),
                  hintText: 'Ask about this property...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
