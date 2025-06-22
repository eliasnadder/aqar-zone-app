import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agent.dart';

class AgentContactWidget extends StatefulWidget {
  final Agent agent;

  const AgentContactWidget({Key? key, required this.agent}) : super(key: key);

  @override
  State<AgentContactWidget> createState() => _AgentContactWidgetState();
}

class _AgentContactWidgetState extends State<AgentContactWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _animatePress() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Agent',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAgentInfo(theme),
          const SizedBox(height: 16),
          _buildContactButtons(theme),
        ],
      ),
    );
  }

  Widget _buildAgentInfo(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              widget.agent.profileImage != null
                  ? ClipOval(
                    child: Image.network(
                      widget.agent.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildDefaultAvatar(theme),
                    ),
                  )
                  : _buildDefaultAvatar(theme),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.agent.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.agent.company != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.agent.company!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (widget.agent.rating != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      widget.agent.rating!.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.agent.reviewsCount != null) ...[
                      Text(
                        ' (${widget.agent.reviewsCount} reviews)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Icon(
      Icons.person_rounded,
      size: 30,
      color: theme.colorScheme.onPrimary,
    );
  }

  Widget _buildContactButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ElevatedButton.icon(
              onPressed: () {
                _animatePress();
                _makePhoneCall();
              },
              icon: const Icon(Icons.phone_rounded),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _sendEmail,
            icon: const Icon(Icons.email_rounded),
            label: const Text('Email'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall() async {
    try {
      final phoneUrl = Uri.parse('tel:${widget.agent.phone}');
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        _showErrorMessage('Could not launch phone dialer');
      }
    } catch (e) {
      _showErrorMessage('Error making phone call: $e');
    }
  }

  Future<void> _sendEmail() async {
    try {
      final emailUrl = Uri.parse('mailto:${widget.agent.email}');
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
      } else {
        _showErrorMessage('Could not launch email client');
      }
    } catch (e) {
      _showErrorMessage('Error sending email: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
