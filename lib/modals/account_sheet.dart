import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/onboarding/onboarding_login_screen.dart';
import 'measurements_sheet.dart';
import 'progress_sheet.dart';
import 'macro_goals_sheet.dart';

class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const AccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 40,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0x80CBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0x99E2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  (FirebaseAuth.instance.currentUser?.displayName ?? 'U').isNotEmpty
                      ? (FirebaseAuth.instance.currentUser?.displayName ?? 'U')[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildMenuRow(Icons.straighten, 'Measurements', onTap: () {
            Navigator.pop(context);
            MeasurementsSheet.show(context);
          }),
          const Divider(height: 1, color: Color(0x14000000)),
          _buildMenuRow(Icons.track_changes_rounded, 'Macro Goals', onTap: () {
            Navigator.pop(context);
            MacroGoalsSheet.show(context);
          }),
          const Divider(height: 1, color: Color(0x14000000)),
          _buildMenuRow(Icons.show_chart, 'Progress', onTap: () {
            Navigator.pop(context);
            ProgressSheet.show(context);
          }),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingLoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                border: Border.all(color: const Color(0x99FECDD3)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF43F5E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF0F172A)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
