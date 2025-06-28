import 'package:flutter/foundation.dart';

class VoiceShortcutsService extends ChangeNotifier {
  final Map<String, VoiceCommand> _commands = {};
  final List<String> _commandHistory = [];
  bool _isListeningForCommands = false;
  
  // Callbacks for different actions
  VoidCallback? _onShowProperties;
  VoidCallback? _onCallAgent;
  VoidCallback? _onSaveConversation;
  VoidCallback? _onStartOver;
  VoidCallback? _onShowFavorites;
  VoidCallback? _onOpenSettings;
  Function(String)? _onSearchProperties;
  Function(String)? _onFilterByLocation;
  Function(String)? _onFilterByPrice;
  Function(String)? _onBookmarkText;
  Function()? _onRepeatLast;
  
  // Getters
  bool get isListeningForCommands => _isListeningForCommands;
  List<String> get availableCommands => _commands.keys.toList();
  List<String> get commandHistory => List.unmodifiable(_commandHistory);
  
  void initialize({
    VoidCallback? onShowProperties,
    VoidCallback? onCallAgent,
    VoidCallback? onSaveConversation,
    VoidCallback? onStartOver,
    VoidCallback? onShowFavorites,
    VoidCallback? onOpenSettings,
    Function(String)? onSearchProperties,
    Function(String)? onFilterByLocation,
    Function(String)? onFilterByPrice,
    Function(String)? onBookmarkText,
    Function()? onRepeatLast,
  }) {
    _onShowProperties = onShowProperties;
    _onCallAgent = onCallAgent;
    _onSaveConversation = onSaveConversation;
    _onStartOver = onStartOver;
    _onShowFavorites = onShowFavorites;
    _onOpenSettings = onOpenSettings;
    _onSearchProperties = onSearchProperties;
    _onFilterByLocation = onFilterByLocation;
    _onFilterByPrice = onFilterByPrice;
    _onBookmarkText = onBookmarkText;
    _onRepeatLast = onRepeatLast;
    
    _setupCommands();
  }
  
  void _setupCommands() {
    // Navigation commands
    _commands['اعرض العقارات'] = VoiceCommand(
      trigger: ['اعرض العقارات', 'أظهر العقارات', 'شوف العقارات'],
      action: () => _onShowProperties?.call(),
      description: 'عرض قائمة العقارات',
      category: CommandCategory.navigation,
    );
    
    _commands['اتصل بالوكيل'] = VoiceCommand(
      trigger: ['اتصل بالوكيل', 'تواصل مع الوكيل', 'رقم الوكيل'],
      action: () => _onCallAgent?.call(),
      description: 'الاتصال بوكيل العقارات',
      category: CommandCategory.action,
    );
    
    _commands['احفظ المحادثة'] = VoiceCommand(
      trigger: ['احفظ المحادثة', 'احفظ الكلام', 'سجل المحادثة'],
      action: () => _onSaveConversation?.call(),
      description: 'حفظ المحادثة الحالية',
      category: CommandCategory.action,
    );
    
    _commands['ابدأ من جديد'] = VoiceCommand(
      trigger: ['ابدأ من جديد', 'محادثة جديدة', 'امسح الكلام'],
      action: () => _onStartOver?.call(),
      description: 'بدء محادثة جديدة',
      category: CommandCategory.navigation,
    );
    
    _commands['اعرض المفضلة'] = VoiceCommand(
      trigger: ['اعرض المفضلة', 'شوف المحفوظات', 'العقارات المحفوظة'],
      action: () => _onShowFavorites?.call(),
      description: 'عرض العقارات المفضلة',
      category: CommandCategory.navigation,
    );
    
    _commands['افتح الإعدادات'] = VoiceCommand(
      trigger: ['افتح الإعدادات', 'الإعدادات', 'خيارات الصوت'],
      action: () => _onOpenSettings?.call(),
      description: 'فتح إعدادات التطبيق',
      category: CommandCategory.navigation,
    );
    
    // Search commands with parameters
    _commands['ابحث عن'] = VoiceCommand(
      trigger: ['ابحث عن', 'أريد', 'أبحث عن'],
      parameterizedAction: (param) => _onSearchProperties?.call(param),
      description: 'البحث عن عقارات محددة',
      category: CommandCategory.search,
      requiresParameter: true,
    );
    
    _commands['في منطقة'] = VoiceCommand(
      trigger: ['في منطقة', 'في', 'بمنطقة'],
      parameterizedAction: (param) => _onFilterByLocation?.call(param),
      description: 'تصفية حسب المنطقة',
      category: CommandCategory.filter,
      requiresParameter: true,
    );
    
    _commands['بسعر'] = VoiceCommand(
      trigger: ['بسعر', 'سعره', 'تكلفته'],
      parameterizedAction: (param) => _onFilterByPrice?.call(param),
      description: 'تصفية حسب السعر',
      category: CommandCategory.filter,
      requiresParameter: true,
    );
    
    // Utility commands
    _commands['احفظ هذا'] = VoiceCommand(
      trigger: ['احفظ هذا', 'تذكر هذا', 'مهم'],
      parameterizedAction: (param) => _onBookmarkText?.call(param),
      description: 'حفظ نص مهم',
      category: CommandCategory.utility,
    );
    
    _commands['كرر'] = VoiceCommand(
      trigger: ['كرر', 'أعد', 'مرة ثانية'],
      action: () => _onRepeatLast?.call(),
      description: 'تكرار آخر رد',
      category: CommandCategory.utility,
    );
  }
  
  // Process voice input for commands
  bool processVoiceInput(String input) {
    if (!_isListeningForCommands) return false;
    
    final lowerInput = input.toLowerCase().trim();
    
    // Check for exact matches first
    for (final command in _commands.values) {
      for (final trigger in command.trigger) {
        if (lowerInput == trigger.toLowerCase()) {
          _executeCommand(command, input);
          return true;
        }
      }
    }
    
    // Check for parameterized commands
    for (final command in _commands.values) {
      if (command.requiresParameter) {
        for (final trigger in command.trigger) {
          if (lowerInput.startsWith(trigger.toLowerCase())) {
            final parameter = input.substring(trigger.length).trim();
            if (parameter.isNotEmpty) {
              _executeParameterizedCommand(command, parameter, input);
              return true;
            }
          }
        }
      }
    }
    
    // Check for partial matches
    for (final command in _commands.values) {
      for (final trigger in command.trigger) {
        if (lowerInput.contains(trigger.toLowerCase())) {
          if (command.requiresParameter) {
            // Extract parameter from the input
            final parameter = _extractParameter(input, trigger);
            if (parameter.isNotEmpty) {
              _executeParameterizedCommand(command, parameter, input);
              return true;
            }
          } else {
            _executeCommand(command, input);
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  String _extractParameter(String input, String trigger) {
    final lowerInput = input.toLowerCase();
    final lowerTrigger = trigger.toLowerCase();
    
    final triggerIndex = lowerInput.indexOf(lowerTrigger);
    if (triggerIndex == -1) return '';
    
    final afterTrigger = input.substring(triggerIndex + trigger.length).trim();
    
    // Remove common connecting words
    final connectingWords = ['في', 'من', 'إلى', 'عن', 'مع', 'على'];
    String parameter = afterTrigger;
    
    for (final word in connectingWords) {
      if (parameter.startsWith(word + ' ')) {
        parameter = parameter.substring(word.length + 1).trim();
        break;
      }
    }
    
    return parameter;
  }
  
  void _executeCommand(VoiceCommand command, String originalInput) {
    if (kDebugMode) {
      print('Executing command: ${command.description}');
    }
    
    _commandHistory.add(originalInput);
    command.action?.call();
    notifyListeners();
  }
  
  void _executeParameterizedCommand(VoiceCommand command, String parameter, String originalInput) {
    if (kDebugMode) {
      print('Executing parameterized command: ${command.description} with parameter: $parameter');
    }
    
    _commandHistory.add(originalInput);
    command.parameterizedAction?.call(parameter);
    notifyListeners();
  }
  
  // Enable/disable command listening
  void enableCommandListening() {
    _isListeningForCommands = true;
    notifyListeners();
  }
  
  void disableCommandListening() {
    _isListeningForCommands = false;
    notifyListeners();
  }
  
  void toggleCommandListening() {
    _isListeningForCommands = !_isListeningForCommands;
    notifyListeners();
  }
  
  // Get available commands by category
  List<VoiceCommand> getCommandsByCategory(CommandCategory category) {
    return _commands.values.where((cmd) => cmd.category == category).toList();
  }
  
  // Get command suggestions based on current context
  List<String> getCommandSuggestions({String? currentContext}) {
    final suggestions = <String>[];
    
    // Add most common commands
    suggestions.addAll([
      'اعرض العقارات',
      'ابحث عن شقة',
      'اتصل بالوكيل',
      'احفظ هذا',
    ]);
    
    // Add context-specific suggestions
    if (currentContext != null) {
      final lowerContext = currentContext.toLowerCase();
      
      if (lowerContext.contains('سعر')) {
        suggestions.add('بسعر أقل من 500 ألف');
      }
      
      if (lowerContext.contains('منطقة') || lowerContext.contains('مكان')) {
        suggestions.add('في منطقة الرياض');
      }
      
      if (lowerContext.contains('شقة')) {
        suggestions.add('ابحث عن شقة أخرى');
      }
    }
    
    return suggestions.take(6).toList();
  }
  
  // Get help text for commands
  String getCommandHelp() {
    final help = StringBuffer();
    help.writeln('الأوامر الصوتية المتاحة:');
    help.writeln();
    
    final categories = CommandCategory.values;
    for (final category in categories) {
      final commands = getCommandsByCategory(category);
      if (commands.isNotEmpty) {
        help.writeln('${_getCategoryName(category)}:');
        for (final command in commands) {
          help.writeln('• ${command.trigger.first} - ${command.description}');
        }
        help.writeln();
      }
    }
    
    return help.toString();
  }
  
  String _getCategoryName(CommandCategory category) {
    switch (category) {
      case CommandCategory.navigation:
        return 'التنقل';
      case CommandCategory.action:
        return 'الإجراءات';
      case CommandCategory.search:
        return 'البحث';
      case CommandCategory.filter:
        return 'التصفية';
      case CommandCategory.utility:
        return 'أدوات مساعدة';
    }
  }
  
  // Clear command history
  void clearHistory() {
    _commandHistory.clear();
    notifyListeners();
  }
  
  // Get command statistics
  Map<String, int> getCommandStatistics() {
    final stats = <String, int>{};
    
    for (final command in _commandHistory) {
      stats[command] = (stats[command] ?? 0) + 1;
    }
    
    return stats;
  }
}

class VoiceCommand {
  final List<String> trigger;
  final VoidCallback? action;
  final Function(String)? parameterizedAction;
  final String description;
  final CommandCategory category;
  final bool requiresParameter;
  
  VoiceCommand({
    required this.trigger,
    this.action,
    this.parameterizedAction,
    required this.description,
    required this.category,
    this.requiresParameter = false,
  });
}

enum CommandCategory {
  navigation,
  action,
  search,
  filter,
  utility,
}
