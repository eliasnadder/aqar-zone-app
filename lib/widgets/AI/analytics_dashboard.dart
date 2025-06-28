import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/AI/conversation_analytics_service.dart';
import '../../services/AI/property_recommendation_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  final ConversationAnalyticsService analyticsService;
  final PropertyRecommendationService? recommendationService;

  const AnalyticsDashboard({
    super.key,
    required this.analyticsService,
    this.recommendationService,
  });

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('تحليلات المحادثة'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'الأداء'),
            Tab(text: 'التوصيات'),
            Tab(text: 'النصائح'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildRecommendationsTab(),
          _buildTipsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = widget.analyticsService.getSessionSummary();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('إحصائيات عامة'),
          const SizedBox(height: 16),
          _buildStatsGrid([
            _StatCard(
              title: 'إجمالي الجلسات',
              value: '${summary['totalSessions']}',
              icon: Icons.chat,
              color: AppTheme.primaryColor,
            ),
            _StatCard(
              title: 'متوسط مدة الجلسة',
              value: '${summary['averageSessionDuration']?.toStringAsFixed(1)} دقيقة',
              icon: Icons.timer,
              color: AppTheme.secondaryColor,
            ),
            _StatCard(
              title: 'إجمالي وقت المحادثة',
              value: _formatDuration(summary['totalConversationTime']),
              icon: Icons.schedule,
              color: AppTheme.accentTextColor,
            ),
            _StatCard(
              title: 'متوسط الرسائل',
              value: '${summary['averageMessagesPerSession']?.toStringAsFixed(1)}',
              icon: Icons.message,
              color: AppTheme.successColor,
            ),
          ]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('مستوى الرضا'),
          const SizedBox(height: 16),
          _buildSatisfactionChart(summary['userSatisfactionAverage'] ?? 0.0),
          
          const SizedBox(height: 24),
          _buildSectionHeader('المواضيع الأكثر نقاشاً'),
          const SizedBox(height: 16),
          _buildTopicsChart(summary['mostDiscussedTopics'] ?? []),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('أداء المحادثة'),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('تحليل الصوت'),
          const SizedBox(height: 16),
          _buildVoiceAnalytics(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('مستوى التفاعل'),
          const SizedBox(height: 16),
          _buildEngagementChart(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (widget.recommendationService == null) {
      return const Center(
        child: Text('خدمة التوصيات غير متاحة'),
      );
    }

    final insights = widget.recommendationService!.getRecommendationInsights();
    final recommendations = widget.recommendationService!.currentRecommendations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('رؤى التوصيات'),
          const SizedBox(height: 16),
          _buildRecommendationInsights(insights),
          
          const SizedBox(height: 24),
          _buildSectionHeader('أفضل التوصيات'),
          const SizedBox(height: 16),
          _buildTopRecommendations(recommendations.take(5).toList()),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    final tips = widget.analyticsService.getVoiceTrainingTips();
    final personalizedTips = widget.analyticsService.getPersonalizedRecommendations();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('نصائح تحسين الصوت'),
          const SizedBox(height: 16),
          _buildVoiceTrainingTips(tips),
          
          const SizedBox(height: 24),
          _buildSectionHeader('توصيات شخصية'),
          const SizedBox(height: 16),
          _buildPersonalizedTips(personalizedTips),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatCard> stats) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: stat.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                stat.icon,
                color: stat.color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                stat.value,
                style: TextStyle(
                  color: stat.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                stat.title,
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSatisfactionChart(double satisfaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'متوسط الرضا',
                style: TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(satisfaction * 20).toStringAsFixed(1)}/5',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: satisfaction,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              satisfaction > 0.7 ? AppTheme.successColor : 
              satisfaction > 0.4 ? AppTheme.warningColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsChart(List<MapEntry<String, int>> topics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: topics.map((topic) {
          final maxCount = topics.isNotEmpty ? topics.first.value : 1;
          final percentage = topic.value / maxCount;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      topic.key,
                      style: const TextStyle(
                        color: AppTheme.primaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${topic.value}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMetricRow('متوسط وقت الاستجابة', '${widget.analyticsService.averageResponseTime.toStringAsFixed(1)} ثانية'),
          const Divider(),
          _buildMetricRow('معدل إكمال المحادثة', '${(widget.analyticsService.conversationCompletionRate * 100).round()}%'),
          const Divider(),
          _buildMetricRow('مستوى التفاعل', '${(widget.analyticsService.engagementScore).round()}/100'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMetricRow('إجمالي وقت الكلام', '${(widget.analyticsService.totalTalkTime / 60).toStringAsFixed(1)} دقيقة'),
          const Divider(),
          _buildMetricRow('وقت كلام المستخدم', '${(widget.analyticsService.userTalkTime / 60).toStringAsFixed(1)} دقيقة'),
          const Divider(),
          _buildMetricRow('وقت كلام الذكي الاصطناعي', '${(widget.analyticsService.aiTalkTime / 60).toStringAsFixed(1)} دقيقة'),
        ],
      ),
    );
  }

  Widget _buildEngagementChart() {
    final engagement = widget.analyticsService.engagementScore;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'مستوى التفاعل',
                style: TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${engagement.round()}/100',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: engagement / 100,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              engagement > 70 ? AppTheme.successColor : 
              engagement > 40 ? AppTheme.warningColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationInsights(Map<String, dynamic> insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMetricRow('إجمالي التوصيات', '${insights['totalRecommendations']}'),
          const Divider(),
          _buildMetricRow('متوسط النقاط', '${(insights['averageScore'] * 100).round()}%'),
          const Divider(),
          _buildMetricRow('الموقع المفضل', insights['topLocation'] ?? 'غير محدد'),
          const Divider(),
          _buildMetricRow('ثقة التوصيات', '${(insights['recommendationConfidence'] * 100).round()}%'),
        ],
      ),
    );
  }

  Widget _buildTopRecommendations(List<dynamic> recommendations) {
    return Column(
      children: recommendations.map((rec) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rec.property.title,
                    style: const TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    rec.scorePercentage,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rec.reasons.join(' • '),
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVoiceTrainingTips(Map<String, dynamic> tips) {
    return Column(
      children: tips.entries.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppTheme.warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip.value,
                  style: const TextStyle(
                    color: AppTheme.primaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonalizedTips(List<String> tips) {
    return Column(
      children: tips.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: AppTheme.primaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0 دقيقة';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours ساعة $minutes دقيقة';
    } else {
      return '$minutes دقيقة';
    }
  }
}

class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
