import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF8FAFC);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFEEF2F7);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF64748B);
const _kTextTertiary = Color(0xFFB0BAC6);
const _kDivider = Color(0xFFF1F5F9);
const _kHandle = Color(0xFFDDE3ED);
const _kGreen = Color(0xFF22C55E);

class MeasurementsSheet extends StatelessWidget {
  const MeasurementsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
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
            color: _kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 40,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _kHandle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title + close
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'Measurements',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kBorder, width: 1),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: _kTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metrics card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      _EditableMetricRow(
                        icon: Icons.cake_outlined,
                        label: 'Age',
                        value: '$age',
                        unit: 'yrs',
                        isFirst: true,
                        onTap: () => _editNumber(
                          context,
                          title: 'Age',
                          current: age.toDouble(),
                          unit: 'years',
                          min: 10,
                          max: 120,
                          isInt: true,
                          onSave: (v) => docRef.update({'age': v.toInt()}),
                        ),
                      ),
                      _divider(),
                      _EditableMetricRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Weight',
                        value: weight.toStringAsFixed(1),
                        unit: 'kg',
                        onTap: () => _editNumber(
                          context,
                          title: 'Weight',
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
                      _divider(),
                      _EditableMetricRow(
                        icon: Icons.straighten_outlined,
                        label: 'Height',
                        value: height.toStringAsFixed(1),
                        unit: 'cm',
                        onTap: () => _editNumber(
                          context,
                          title: 'Height',
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
                      _divider(),
                      _EditableMetricRow(
                        icon: Icons.person_outline,
                        label: 'Gender',
                        value: gender.isNotEmpty
                            ? gender[0].toUpperCase() + gender.substring(1)
                            : '—',
                        unit: '',
                        onTap: () => _editGender(context, gender, docRef),
                      ),
                      _divider(),
                      _EditableMetricRow(
                        icon: Icons.directions_run_outlined,
                        label: 'Activity',
                        value: activityLevel.isNotEmpty ? activityLevel : '—',
                        unit: '',
                        isLast: true,
                        onTap: () => _editActivity(context, activityLevel, docRef),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(height: 1, color: _kDivider),
  );

  // ─── Sub-sheets ────────────────────────────────────────────────────────

  Widget _subSheetContainer({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 40,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _subSheetHandle() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: _kHandle,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );

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
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _subSheetContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _subSheetHandle(),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: !isInt,
                        ),
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary,
                          letterSpacing: -2,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: _kTextPrimary.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),
                    if (unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _kTextTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final val = double.tryParse(ctrl.text);
                    if (val == null || val < min || val > max) return;
                    await onSave(val);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: _kTextPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editGender(
    BuildContext context,
    String current,
    DocumentReference docRef,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => _subSheetContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subSheetHandle(),
              const SizedBox(height: 20),
              const Text(
                'Gender',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder, width: 1),
                ),
                child: Column(
                  children: ['Male', 'Female', 'Other'].asMap().entries.map((entry) {
                    final g = entry.value;
                    final isSelected = current.toLowerCase() == g.toLowerCase();
                    final isLast = entry.key == 2;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await docRef.update({'gender': g.toLowerCase()});
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Text(
                                  g,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? _kTextPrimary
                                        : _kTextSecondary,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: _kGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(height: 1, color: _kDivider),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editActivity(
    BuildContext context,
    String current,
    DocumentReference docRef,
  ) {
    const levels = [
      'Sedentary',
      'Lightly Active',
      'Moderately Active',
      'Very Active',
    ];
    const descriptions = {
      'Sedentary': 'Little or no exercise',
      'Lightly Active': '1–3 days/week',
      'Moderately Active': '3–5 days/week',
      'Very Active': '6–7 days/week',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => _subSheetContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subSheetHandle(),
              const SizedBox(height: 20),
              const Text(
                'Activity Level',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder, width: 1),
                ),
                child: Column(
                  children: levels.asMap().entries.map((entry) {
                    final level = entry.value;
                    final isSelected = current == level;
                    final isLast = entry.key == levels.length - 1;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await docRef.update({'activity_level': level});
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? _kTextPrimary
                                              : _kTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        descriptions[level] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _kTextTertiary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: _kGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(height: 1, color: _kDivider),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Editable Metric Row ────────────────────────────────────────────────────────

class _EditableMetricRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _EditableMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_EditableMetricRow> createState() => _EditableMetricRowState();
}

class _EditableMetricRowState extends State<_EditableMetricRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? _kDivider : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.isFirst ? 20 : 0),
            topRight: Radius.circular(widget.isFirst ? 20 : 0),
            bottomLeft: Radius.circular(widget.isLast ? 20 : 0),
            bottomRight: Radius.circular(widget.isLast ? 20 : 0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder, width: 1),
              ),
              child: Icon(widget.icon, size: 17, color: _kTextSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Text(
              widget.unit.isNotEmpty
                  ? '${widget.value} ${widget.unit}'
                  : widget.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kTextTertiary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFD1D9E0),
            ),
          ],
        ),
      ),
    );
  }
}
