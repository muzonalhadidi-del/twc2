import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twc/screens/beneficiary/helpandsupport.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onThemeChanged;

  const DashboardScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    const Color sidebarColor = Color(0xFF9EA4FF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // Implementing the Sidebar from your Vol dashbord (1).png
      drawer: Drawer(
        child: Container(
          color: sidebarColor,
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Home Option
              _drawerItem(
                icon: Icons.home_rounded,
                text: "Home",
                onTap: () => Navigator.pop(context), // Closes the drawer
              ),
              // Support & Help Option
              _drawerItem(
                icon: Icons.headset_mic_outlined,
                text: "Support & helps",
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportChatScreen(),
                    ),
                  );
                },
              ),
              // Settings Option
              _drawerItem(
                icon: Icons.settings_outlined,
                text: "Setting",
                onTap: () {}, // Add settings logic here
              ),
              const Spacer(),
              // Change Mode (Dark Mode) Option
              Container(
                color: Colors.white.withOpacity(0.2),
                child: _drawerItem(
                  icon: Icons.dark_mode_outlined,
                  text: "Change Mode",
                  onTap: () {
                    onThemeChanged(); // Toggles Dark Mode
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: const Center(child: Text("Welcome to Dashboard")),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 30),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
