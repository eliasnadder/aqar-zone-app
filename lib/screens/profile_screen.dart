import 'package:flutter/material.dart';
import '../services/api_key_service.dart';
import '../services/AI/voice_settings_service.dart';
import 'api_key_setup_screen.dart';
import 'AI/voice_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const ProfileScreen({Key? key, required this.onThemeToggle})
    : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final ApiKeyService _apiKeyService = ApiKeyService.instance;
  final VoiceSettingsService _voiceSettingsService = VoiceSettingsService();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _fadeController.forward();
    _slideController.forward();

    // Initialize voice settings service
    _voiceSettingsService.initialize();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showApiKeySetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ApiKeySetupScreen(
              onSetupComplete: () {
                Navigator.pop(context);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
      ),
    );
  }

  void _navigateToVoiceSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                VoiceSettingsScreen(voiceSettings: _voiceSettingsService),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About Casa AI'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Casa AI - Your Intelligent Property Assistant'),
                SizedBox(height: 12),
                Text('Version: 1.0.0'),
                SizedBox(height: 8),
                Text('Built with Flutter & Gemini AI'),
                SizedBox(height: 12),
                Text(
                  'Casa AI helps you find, explore, and get insights about properties using advanced AI technology.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(theme, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProfileCard(theme),
                      const SizedBox(height: 24),
                      _buildSettingsSection(theme),
                      const SizedBox(height: 24),
                      _buildAboutSection(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // ignore: deprecated_member_use
                theme.colorScheme.primary.withOpacity(0.1),
                // ignore: deprecated_member_use
                theme.colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: 80,
              // ignore: deprecated_member_use
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // ignore: deprecated_member_use
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            // ignore: deprecated_member_use
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Casa AI User',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-Powered Property Explorer',
            style: theme.textTheme.bodyLarge?.copyWith(
              // ignore: deprecated_member_use
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Properties', '25+', theme),
              _buildStatItem('Searches', '150+', theme),
              _buildStatItem('Favorites', '12', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            // ignore: deprecated_member_use
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.key_rounded,
            title: 'API Key Management',
            subtitle:
                _apiKeyService.hasValidApiKey
                    ? 'API key configured'
                    : 'No API key set',
            onTap: _showApiKeySetup,
            theme: theme,
          ),
          _buildSettingsTile(
            icon: Icons.record_voice_over_rounded,
            title: 'AI Voice Settings',
            subtitle: 'Customize voice characteristics and speech controls',
            onTap: _navigateToVoiceSettings,
            theme: theme,
          ),
          _buildSettingsTile(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: 'Toggle dark/light mode',
            onTap: widget.onThemeToggle,
            theme: theme,
          ),
          _buildSettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon!'),
                ),
              );
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'About',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.info_rounded,
            title: 'About Casa AI',
            subtitle: 'Version, credits, and more',
            onTap: _showAboutDialog,
            theme: theme,
          ),
          _buildSettingsTile(
            icon: Icons.help_rounded,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
            theme: theme,
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            subtitle: 'Learn about data usage',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon!')),
              );
            },
            theme: theme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(
                    bottom: BorderSide(
                      // ignore: deprecated_member_use
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      // ignore: deprecated_member_use
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              // ignore: deprecated_member_use
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
