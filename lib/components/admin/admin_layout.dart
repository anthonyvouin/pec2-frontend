import 'package:flutter/material.dart';

class AdminDashboardLayout extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onMenuItemSelected;
  final Widget content;

  const AdminDashboardLayout({
    Key? key,
    required this.selectedIndex,
    required this.onMenuItemSelected,
    required this.content,
  }) : super(key: key);

  @override
  _AdminDashboardLayoutState createState() => _AdminDashboardLayoutState();
}

class _AdminDashboardLayoutState extends State<AdminDashboardLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isSmallScreen
          ? Drawer(
              child: SideMenu(
                selectedIndex: widget.selectedIndex,
                onMenuItemSelected: (index) {
                  widget.onMenuItemSelected(index);
                  Navigator.pop(context); // Ferme le drawer après sélection
                },
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          // Menu latéral pour les grands écrans
          if (!isSmallScreen)
            SideMenu(
              selectedIndex: widget.selectedIndex,
              onMenuItemSelected: widget.onMenuItemSelected,
              isDrawer: false,
            ),

          Expanded(
            child: Column(
              children: [
                if (isSmallScreen)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Admin OnlyFlick",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),

                // Contenu
                Expanded(child: widget.content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuItemSelected;
  final bool isDrawer;

  const SideMenu({
    Key? key,
    required this.selectedIndex,
    required this.onMenuItemSelected,
    this.isDrawer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDrawer ? null : 220,
      decoration: isDrawer
          ? null
          : BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF6C3FFE),
            child: Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Admin Panel",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItem(0, "Kpi Dashboard", Icons.dashboard),
                  _buildMenuItem(1, "Statistiques", Icons.insert_chart),
                  _buildMenuItem(2, "Utilisateurs", Icons.group),
                  _buildMenuItem(3, "Contacts", Icons.contact_mail),
                  _buildMenuItem(4, "Créateurs", Icons.group),
                  _buildMenuItem(5, "Catégories", Icons.category),
                  _buildMenuItem(6, "Revenus", Icons.attach_money),
                  _buildMenuItem(7, "Posts", Icons.post_add),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Statut: Connecté",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Admin",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onMenuItemSelected(index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6C3FFE) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF6C3FFE) : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
