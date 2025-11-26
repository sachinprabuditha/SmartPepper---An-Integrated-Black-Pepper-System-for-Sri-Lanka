import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../seasons/pages/seasons_list_page.dart';
import '../../agronomy/pages/agronomy_guide_page.dart';
import '../../plantation/pages/farms_list_page.dart';
import '../../predictions/pages/prediction_page.dart';
import '../controllers/auth_controller.dart';
import '../pages/login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:developer' as developer;

import '../../chat/pages/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = const FlutterSecureStorage();

  // Action cards configuration - moved to static to prevent recreation
  static final List<ActionCard> _actionCards = [
    ActionCard(
      title: 'Agronomy Guide',
      icon: Icons.eco,
      color: Colors.teal,
      route: (context) => const AgronomyGuidePage(),
    ),    
    ActionCard(
      title: 'Plantation',
      icon: Icons.agriculture,
      color: Colors.green,
      route: (context) => const FarmsListPage(),
    ),
    ActionCard(
      title: 'Seasons',
      icon: Icons.calendar_today,
      color: Colors.orange,
      route: (context) => const SeasonsListPage(),
    ),
    ActionCard(
      title: 'Price Prediction',
      icon: Icons.trending_up,
      color: Colors.purple,
      route: (context) => const PredictionPage(),
    ),
    ActionCard(
      title: 'AI Chat Assistant',
      icon: Icons.chat_bubble_outline,
      color: Colors.indigo,
      route: (context) => const ChatPage(),
    ),
    ActionCard(
      title: 'Profile',
      icon: Icons.person,
      color: Colors.blue,
      route: (context) => const ProfilePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Harvest Tracker'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          actions: [
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  onPressed: () async {
                    try {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      developer.log('Error signing out: $e');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _actionCards.isEmpty
              ? const Center(
                  child: Text('No action cards available'),
                )
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _actionCards.length,
                    itemBuilder: (context, index) {
                      if (index >= _actionCards.length) {
                        return const SizedBox.shrink();
                      }
                      final card = _actionCards[index];
                      return _buildActionCard(context, card);
                    },
                  ),
                ),
        ),
      );
  }

  Widget _buildActionCard(BuildContext context, ActionCard card) {
    return Material(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: card.route),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                card.icon,
                size: 48,
                color: card.color,
              ),
              const SizedBox(height: 12),
              Text(
                card.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionCard {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext) route;

  ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = const FlutterSecureStorage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: Future.wait([
          storage.read(key: AppConstants.userEmailKey),
          storage.read(key: AppConstants.userFullNameKey),
        ]).then((values) => {
          'email': values[0],
          'fullName': values[1],
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final email = snapshot.data?['email'] ?? 'N/A';
          final fullName = snapshot.data?['fullName'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(context, 'Full Name', fullName),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, 'Email', email),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
