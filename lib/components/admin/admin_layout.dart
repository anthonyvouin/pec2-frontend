import 'package:flutter/material.dart';

class AdminDashboardLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        SideMenu(
          selectedIndex: selectedIndex,
          onMenuItemSelected: onMenuItemSelected,
        ),

        Expanded(child: content),
      ],
    );
  }
}

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuItemSelected;

  const SideMenu({
    Key? key,
    required this.selectedIndex,
    required this.onMenuItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
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
            _buildMenuItem(0, "Kpi Dashboard", Icons.dashboard),
            _buildMenuItem(1, "Statistiques", Icons.insert_chart),
            _buildMenuItem(2, "Utilisateurs", Icons.group),
            _buildMenuItem(3, "Contacts", Icons.contact_mail),
            _buildMenuItem(4, "Créateurs ", Icons.group),
            _buildMenuItem(5, "Catégories", Icons.category),
            _buildMenuItem(6, "Revenus", Icons.attach_money),
            _buildMenuItem(7, "Posts", Icons.post_add),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
            const SizedBox(height: 20),
          ],
        ),
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
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF6C3FFE) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
