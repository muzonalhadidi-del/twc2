import 'package:flutter/material.dart';
import 'confirm_request.dart';

class TransportRequestScreen extends StatelessWidget {
  final Map<String, dynamic> data; // Received data
  const TransportRequestScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF9EA4FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F2F8),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            "Transportation",
            style: TextStyle(fontSize: 32, fontFamily: 'Serif'),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _buildTransportOption(
                    icon: Icons.directions_car,
                    label: "Book a Ride",
                    iconColor: themePurple,
                    onTap: () {
                      Map<String, dynamic> updatedData = Map.from(data);
                      updatedData['subService'] = "Book a Ride";
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ConfirmRequestScreen(data: updatedData),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  _buildTransportOption(
                    icon: Icons.add,
                    label: "Emergency\nTransport",
                    iconColor: Colors.red,
                    onTap: () {
                      Map<String, dynamic> updatedData = Map.from(data);
                      updatedData['subService'] = "Emergency Transport";
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ConfirmRequestScreen(data: updatedData),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildFooter(themePurple),
        ],
      ),
    );
  }

  Widget _buildFooter(Color color) => Container(
    width: double.infinity,
    color: color,
    padding: const EdgeInsets.all(12.0),
    child: const Center(
      child: Text('@TWC2026', style: TextStyle(color: Colors.white)),
    ),
  );

  Widget _buildTransportOption({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF9EA4FF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const SizedBox(width: 25),
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(width: 25),
            Text(
              label,
              style: const TextStyle(fontSize: 24, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
