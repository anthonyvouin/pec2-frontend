import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../components/admin/admin_layout.dart';

class AdminDashboardPage extends StatefulWidget {
  final Widget child;

  const AdminDashboardPage({Key? key, required this.child}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = false;
  int _selectedIndex = 0;

  final List<String> _routes = [
    adminKpiDashboard,
    adminUsersChart,
    adminUsersManagement,
    adminContacts,
    adminContentCreator,
    adminCategoriesManagement,
    adminRevenueChart,
  ];

  Future<void> _logout() async {
    final userNotifier = context.read<UserNotifier>();
    userNotifier.logout();

    if (context.mounted) {
      context.go(loginRoute);
    }
  }

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin OnlyFlick"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Déconnexion",
          ),
        ],
      ),
      body: AdminDashboardLayout(
        selectedIndex: _selectedIndex,
        onMenuItemSelected: _onMenuItemSelected,
        content: widget.child,
      ),
    );
  }
}
