import 'package:flutter/material.dart';

import '../../../shared/components/kmfri_navigation_drawer.dart';
import '../../authentication/model/mobile_user.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  final MobileUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62),
        foregroundColor: Colors.white,
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: KmfriNavigationDrawer(
        user: user,
        onSignOut: onSignOut,
        currentIndex: 2,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: Color(0xFF0A3D62),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _faqCard(
              question: 'How do I clock in when I am in the field or offline?',
              answer:
                  'You can record your attendance even without an internet connection. Tap "CLOCK IN" or "CLOCK OUT" as normal. Your record will be saved securely on your device with the exact event time and automatically synchronized when your internet connection returns.',
            ),
            _faqCard(
              question: 'Why does the app require location access?',
              answer:
                  'KMFRI Clocking verifies station geofences to ensure attendance is recorded at authorized research stations, centers, or field locations.',
            ),
            _faqCard(
              question: 'What should I do if device security/enrollment fails?',
              answer:
                  'Each account is bound to your authorized mobile device. If you replaced your phone, please contact KMFRI IT support or your station administrator to release your previous device registration.',
            ),
            _faqCard(
              question: 'How do I change my account type or password?',
              answer:
                  'Password and account management are handled centrally through your KMFRI portal credentials. Contact HR or IT support for account updates.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8EEF7)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Further Assistance?',
                    style: TextStyle(
                      color: Color(0xFF0A3D62),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reach out to the KMFRI ICT & Human Resources directorate for technical support or attendance inquiries.',
                    style: TextStyle(color: Color(0xFF667085), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqCard({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Color(0xFF0A3D62),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
