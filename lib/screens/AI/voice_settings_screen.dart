import 'package:flutter/material.dart';
import '../../services/AI/voice_settings_service.dart';
import '../../core/theme/app_theme.dart';

class VoiceSettingsScreen extends StatefulWidget {
  final VoiceSettingsService voiceSettings;

  const VoiceSettingsScreen({super.key, required this.voiceSettings});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'AI Voice Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: ListenableBuilder(
        listenable: widget.voiceSettings,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Voice Characteristics'),
                _buildVoiceTypeSelector(),
                const SizedBox(height: 24),

                _buildSectionHeader('Speech Controls'),
                _buildSpeechRateSlider(),
                const SizedBox(height: 16),
                _buildPitchSlider(),
                const SizedBox(height: 16),
                _buildVolumeSlider(),
                const SizedBox(height: 24),

                _buildSectionHeader('Language & Accent'),
                _buildLanguageSelector(),
                const SizedBox(height: 24),

                _buildSectionHeader('Audio Features'),
                _buildAudioFeatureToggles(),
                const SizedBox(height: 24),

                _buildSectionHeader('Preview'),
                _buildVoicePreview(),
                const SizedBox(height: 24),

                _buildSectionHeader('Advanced'),
                _buildAdvancedSettings(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVoiceTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voice Personality',
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                VoiceType.values.map((type) {
                  final isSelected = widget.voiceSettings.voiceType == type;
                  return GestureDetector(
                    onTap: () => widget.voiceSettings.setVoiceType(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type.name,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            type.description,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppTheme.secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechRateSlider() {
    return _buildSliderCard(
      title: 'Speech Speed',
      value: widget.voiceSettings.speechRate,
      min: 0.1,
      max: 2.0,
      divisions: 19,
      onChanged: widget.voiceSettings.setSpeechRate,
      valueFormatter: (value) => '${(value * 100).round()}%',
      subtitle: 'Adjust how fast the AI speaks',
    );
  }

  Widget _buildPitchSlider() {
    return _buildSliderCard(
      title: 'Voice Pitch',
      value: widget.voiceSettings.pitch,
      min: 0.5,
      max: 2.0,
      divisions: 15,
      onChanged: widget.voiceSettings.setPitch,
      valueFormatter: (value) => '${(value * 100).round()}%',
      subtitle: 'Higher values make voice sound higher',
    );
  }

  Widget _buildVolumeSlider() {
    return _buildSliderCard(
      title: 'Volume',
      value: widget.voiceSettings.volume,
      min: 0.0,
      max: 1.0,
      divisions: 10,
      onChanged: widget.voiceSettings.setVolume,
      valueFormatter: (value) => '${(value * 100).round()}%',
      subtitle: 'Base volume level for voice output',
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required String Function(double) valueFormatter,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valueFormatter(value),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final languages = {
      'ar-SA': 'Arabic (Saudi)',
      'ar-EG': 'Arabic (Egyptian)',
      'ar-AE': 'Arabic (UAE)',
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Language & Accent',
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: widget.voiceSettings.language,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: AppTheme.primaryTextColor),
            items:
                languages.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                widget.voiceSettings.setLanguage(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioFeatureToggles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            'Auto Volume Adjustment',
            'Automatically adjust volume based on ambient noise',
            widget.voiceSettings.autoVolumeAdjustment,
            widget.voiceSettings.setAutoVolumeAdjustment,
          ),
          const Divider(color: AppTheme.primaryColor, height: 24),
          _buildToggleRow(
            'Echo Cancellation',
            'Reduce echo and feedback during voice interaction',
            widget.voiceSettings.echoCancellation,
            widget.voiceSettings.setEchoCancellation,
          ),
          const Divider(color: AppTheme.primaryColor, height: 24),
          _buildToggleRow(
            'Noise Suppression',
            'Filter out background noise for clearer speech',
            widget.voiceSettings.noiseSuppression,
            widget.voiceSettings.setNoiseSuppression,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
          activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildVoicePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Voice Settings',
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement voice preview
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice preview would play here'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Preview Voice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Audio Settings',
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ambient Noise Level',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(widget.voiceSettings.ambientNoiseLevel * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Optimal Volume',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(widget.voiceSettings.getOptimalVolume() * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
