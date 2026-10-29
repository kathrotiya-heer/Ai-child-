import 'package:flutter/material.dart';

class ChildProfilePage extends StatelessWidget {
  const ChildProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      // ==================================================
      // APP BAR
      // ==================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Child Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ==================================================
      // BODY
      // ==================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // PROFILE CARD
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.child_care,
                      size: 55,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Emma',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Age: 10 years',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  // SAFE STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '● Safe',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // DEVICE
            // ==================================================
            _infoTile(Icons.phone_android, 'Device', 'Connected', Colors.blue),

            // ==================================================
            // LAST ACTIVE
            // ==================================================
            _infoTile(
              Icons.access_time,
              'Last Active',
              '5 minutes ago',
              Colors.purple,
            ),

            // ==================================================
            // LOCATION
            // ==================================================
            _infoTile(
              Icons.location_on,
              'Location',
              'Inside Safe Zone',
              Colors.green,
            ),

            const SizedBox(height: 8),

            // ==================================================
            // PARENT CONTROLS
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parent Controls',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  _controlTile(
                    icon: Icons.location_on,
                    title: 'Location Tracking',
                    subtitle: 'Track child location',
                    value: true,
                  ),

                  const Divider(),

                  _controlTile(
                    icon: Icons.notifications,
                    title: 'Safety Alerts',
                    subtitle: 'Receive safety notifications',
                    value: true,
                  ),

                  const Divider(),

                  _controlTile(
                    icon: Icons.warning_amber,
                    title: 'SOS Alerts',
                    subtitle: 'Receive emergency alerts',
                    value: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // EDIT PROFILE BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Edit Child Profile',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO TILE
  // ============================================================

  static Widget _infoTile(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PARENT CONTROL TILE
  // ============================================================

  static Widget _controlTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 28),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),

        Switch(
          value: value,
          onChanged: (newValue) {
            // Real functionality Step 3+ માં add કરીશું.
          },
        ),
      ],
    );
  }
}
