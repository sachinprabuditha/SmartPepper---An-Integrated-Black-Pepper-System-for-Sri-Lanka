import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';
import 'agronomy/agronomy_guide_screen.dart';

class PlantationManagementDashboard extends StatelessWidget {
  const PlantationManagementDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.user?.role.toLowerCase();
    // Plantation Management is for farmers only; redirect others
    if (role != null && role != 'farmer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.tr('plantation_management_farmer_only'))),
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final userName = authProvider.user?.name ?? 'Farmer';

    final features = [
      _FeatureCard(
        label: context.tr('plantation_agronomy_guide'),
        icon: Icons.eco,
        color: AppTheme.sriLankanLeaf,
        route: '/plantation/agronomy-guide',
      ),
      _FeatureCard(
        label: context.tr('plantation_plantations'),
        icon: Icons.agriculture,
        color: AppTheme.pepperGold,
        route: '/plantation/farms',
      ),
      _FeatureCard(
        label: context.tr('plantation_seasons'),
        icon: Icons.calendar_month,
        color: const Color(0xFFF57C00),
        route: '/plantation/seasons',
      ),
      _FeatureCard(
        label: context.tr('plantation_price_prediction'),
        icon: Icons.trending_up,
        color: const Color(0xFF7B1FA2),
        route: '/plantation/price-prediction',
      ),
      _FeatureCard(
        label: context.tr('plantation_price_analytics'),
        icon: Icons.auto_graph,
        color: const Color(0xFFC2185B),
        route: '/plantation/price-analytics',
      ),
      _FeatureCard(
        label: context.tr('plantation_yield_analytics'),
        icon: Icons.analytics_outlined,
        color: const Color(0xFF00897B),
        route: '/plantation/yield-analytics',
      ),
      _FeatureCard(
        label: context.tr('plantation_ai_chat'),
        icon: Icons.chat_bubble_outline,
        color: const Color(0xFF1565C0),
        route: '/plantation/ai-chat',
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('plantation_management'),
          style: const TextStyle(
            color: AppTheme.pepperGold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            color: AppTheme.forestGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .tr('plantation_welcome')
                      .replaceAll('{name}', userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('plantation_subtitle'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Grid of feature cards
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    return _buildFeatureCard(context, features[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureCard feature) {
    return GestureDetector(
      onTap: () => context.push(feature.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: feature.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                feature.icon,
                color: feature.color,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              feature.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _FeatureCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}
