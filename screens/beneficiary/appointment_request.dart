import 'package:flutter/material.dart';
import 'confirm_request.dart'; // Ensure this import is correct

class AppointmentRequestScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const AppointmentRequestScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF9EA4FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F2F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/twc.png', width: 40),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            "Appointments",
            style: TextStyle(
              fontSize: 32,
              fontFamily: 'Serif',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _buildOptionCard(
                    icon: Icons.local_hospital,
                    label: "Medical Clinic",
                    iconColor: Colors.blue,
                    onTap: () {
                      // Clone current data and add subService
                      Map<String, dynamic> updatedData = Map.from(data);
                      updatedData['subService'] = "Medical Clinic";

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
                  _buildOptionCard(
                    icon: Icons.account_balance,
                    label: "Gov Services",
                    iconColor: Colors.green,
                    onTap: () {
                      // Clone current data and add subService
                      Map<String, dynamic> updatedData = Map.from(data);
                      updatedData['subService'] = "Gov Services";

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
                  _buildOptionCard(
                    icon: Icons.warning_amber_rounded,
                    label: "Emergency",
                    iconColor: Colors.red,
                    onTap: () {
                      Map<String, dynamic> updatedData = Map.from(data);
                      updatedData['subService'] = "Emergency";
                      updatedData['isEmergency'] = true; // Emergency Flag

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

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
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
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'Serif',
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(Color color) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.all(12.0),
      child: const Center(
        child: Text(
          '@TWC2026',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
