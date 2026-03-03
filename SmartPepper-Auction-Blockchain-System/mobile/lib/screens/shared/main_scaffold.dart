import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';
import 'home_screen.dart';
import 'auctions_screen.dart';
import 'lots_screen.dart';
import 'account_screen.dart';
import '../farmer/farmer_dashboard.dart';
import '../exporter/exporter_dashboard.dart';
import '../exporter/browse_lots_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  List<Widget> _getScreensForRole(String? role) {
    // Return role-specific home screen
    Widget homeScreen;
    Widget lotsScreen;

    if (role?.toLowerCase() == 'farmer') {
      homeScreen = const FarmerDashboard();
      lotsScreen = const LotsScreen(); // Farmers can create/manage their lots
    } else if (role?.toLowerCase() == 'exporter') {
      homeScreen = const ExporterDashboard();
      lotsScreen =
          const BrowseLotsScreen(); // Exporters only browse approved lots
    } else {
      homeScreen = const HomeScreen();
      lotsScreen = const LotsScreen();
    }

    return [
      homeScreen,
      const AuctionsScreen(),
      lotsScreen,
      const AccountScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems(BuildContext context) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: context.tr('nav_home'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.gavel_outlined),
        activeIcon: const Icon(Icons.gavel),
        label: context.tr('nav_auctions'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.inventory_2_outlined),
        activeIcon: const Icon(Icons.inventory_2),
        label: context.tr('nav_lots'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: context.tr('nav_account'),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screens = _getScreensForRole(authProvider.user?.role);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppTheme.forestGreen,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: _getNavItems(context),
        ),
      ),
    );
  }
}
