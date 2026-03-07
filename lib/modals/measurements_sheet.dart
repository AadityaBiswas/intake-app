import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeasurementsSheet extends StatelessWidget {
  const MeasurementsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const MeasurementsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final age = data['age'] as int? ?? 0;
        final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
        final height = (data['height'] as num?)?.toDouble() ?? 0.0;
        final gender = data['gender'] as String? ?? '';
        final activityLevel = data['activity_level'] as String? ?? '';

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
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
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
              // Title + close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Measurements',
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
                      child: const Icon(Icons.close,
                          size: 20, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'PERSONAL METRICS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _EditableMetricRow(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: '$age',
                unit: 'Years',
                onTap: () => _editNumber(
                  context,
                  title: 'Update Age',
                  current: age.toDouble(),
                  unit: 'years',
                  min: 10,
                  max: 120,
                  isInt: true,
                  onSave: (v) => docRef.update({'age': v.toInt()}),
                ),
              ),
              const Divider(height: 1, color: Color(0x14000000)),
              _EditableMetricRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: weight.toStringAsFixed(1),
                unit: 'kg',
                onTap: () => _editNumber(
                  context,
                  title: 'Update Weight',
                  current: weight,
                  unit: 'kg',
                  min: 20,
                  max: 300,
                  isInt: false,
                  onSave: (v) async {
                    final h = height / 100;
                    final bmi = h > 0 ? v / (h * h) : 0.0;
                    await docRef.update({'weight': v, 'bmi': bmi});
                  },
                ),
              ),
              const Divider(height: 1, color: Color(0x14000000)),
              _EditableMetricRow(
                icon: Icons.straighten_outlined,
                label: 'Height',
                value: height.toStringAsFixed(1),
                unit: 'cm',
                onTap: () => _editNumber(
                  context,
                  title: 'Update Height',
                  current: height,
                  unit: 'cm',
                  min: 100,
                  max: 250,
                  isInt: false,
                  onSave: (v) async {
                    final h = v / 100;
                    final bmi = h > 0 ? weight / (h * h) : 0.0;
                    await docRef.update({'height': v, 'bmi': bmi});
                  },
                ),
              ),
              const Divider(height: 1, color: Color(0x14000000)),
              _EditableMetricRow(
                icon: Icons.person_outline,
                label: 'Gender',
                value: gender.isNotEmpty
                    ? gender[0].toUpperCase() + gender.substring(1)
                    : '—',
                unit: '',
                onTap: () => _editGender(context, gender, docRef),
              ),
              const Divider(height: 1, color: Color(0x14000000)),
              _EditableMetricRow(
                icon: Icons.directions_run_outlined,
                label: 'Activity',
                value: activityLevel.isNotEmpty ? activityLevel : '—',
                unit: '',
                onTap: () => _editActivity(context, activityLevel, docRef),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _editNumber(
    BuildContext context, {
    required String title,
    required double current,
    required String unit,
    required double min,
    required double max,
    required bool isInt,
    required Future<void> Function(double) onSave,
  }) {
    final ctrl = TextEditingController(
      text: isInt ? current.toInt().toString() : current.toStringAsFixed(1),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: !isInt,
                      ),
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final val = double.tryParse(ctrl.text);
                  if (val == null || val < min || val > max) return;
                  await onSave(val);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editGender(
      BuildContext context, String current, DocumentReference docRef) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text('Select Gender',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            for (final g in ['Male', 'Female', 'Other'])
              GestureDetector(
                onTap: () async {
                  await docRef.update({'gender': g.toLowerCase()});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        current.toLowerCase() == g.toLowerCase()
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: current.toLowerCase() == g.toLowerCase()
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Text(g,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _editActivity(
      BuildContext context, String current, DocumentReference docRef) {
    final levels = [
      'Sedentary',
      'Lightly Active',
      'Moderately Active',
      'Very Active',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text('Activity Level',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            for (final level in levels)
              GestureDetector(
                onTap: () async {
                  await docRef.update({'activity_level': level});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        current == level
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: current == level
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Text(level,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditableMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final VoidCallback onTap;
  const _EditableMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF475569)),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
            const Spacer(),
            Text(
              unit.isNotEmpty ? '$value $unit' : value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
