import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding_data.dart';
import 'screen_06_activity.dart';
import '../../../services/macro_calculator.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 5 — Height & Weight
/// Independent unit toggle per field: height can be cm or ft/in,
/// weight can be kg or lbs — independently of each other.
class Screen05HeightWeight extends StatefulWidget {
  final OnboardingData data;
  const Screen05HeightWeight({super.key, required this.data});

  @override
  State<Screen05HeightWeight> createState() => _Screen05HeightWeightState();
}

class _Screen05HeightWeightState extends State<Screen05HeightWeight> {
  // Height controllers
  late TextEditingController _heightCmCtrl;
  late TextEditingController _heightFtCtrl;
  late TextEditingController _heightInCtrl;
  bool _heightMetric = true; // independent from weight unit

  // Weight controllers
  late TextEditingController _weightKgCtrl;
  late TextEditingController _weightLbsCtrl;
  bool _weightMetric = true; // independent from height unit

  @override
  void initState() {
    super.initState();
    _heightMetric = widget.data.isMetric;
    _weightMetric = widget.data.isMetric;

    // Initialise height controllers from stored cm value
    final heightCm = widget.data.height;
    _heightCmCtrl = TextEditingController(
      text: heightCm > 0 ? heightCm.round().toString() : '',
    );
    final totalIn = heightCm / 2.54;
    final feet = (totalIn / 12).floor();
    final inches = (totalIn % 12).round();
    _heightFtCtrl = TextEditingController(text: feet > 0 ? feet.toString() : '');
    _heightInCtrl = TextEditingController(text: feet > 0 ? inches.toString() : '');

    // Initialise weight controllers from stored kg value
    final weightKg = widget.data.weight;
    _weightKgCtrl = TextEditingController(
      text: weightKg > 0 ? weightKg.round().toString() : '',
    );
    _weightLbsCtrl = TextEditingController(
      text: weightKg > 0 ? (weightKg * 2.20462).round().toString() : '',
    );

  }

  @override
  void dispose() {
    _heightCmCtrl.dispose();
    _heightFtCtrl.dispose();
    _heightInCtrl.dispose();
    _weightKgCtrl.dispose();
    _weightLbsCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double _getHeightCm() {
    if (_heightMetric) {
      return (int.tryParse(_heightCmCtrl.text) ?? 0).toDouble();
    } else {
      final ft = int.tryParse(_heightFtCtrl.text) ?? 0;
      final inch = int.tryParse(_heightInCtrl.text) ?? 0;
      return (ft * 12 + inch) * 2.54;
    }
  }

  double _getWeightKg() {
    if (_weightMetric) {
      return (int.tryParse(_weightKgCtrl.text) ?? 0).toDouble();
    } else {
      final lbs = int.tryParse(_weightLbsCtrl.text) ?? 0;
      return lbs / 2.20462;
    }
  }

  void _syncHeightControllers(double cm) {
    final totalIn = cm / 2.54;
    final ft = (totalIn / 12).floor();
    final inch = (totalIn % 12).round();
    _heightCmCtrl.text = cm > 0 ? cm.round().toString() : '';
    _heightFtCtrl.text = ft > 0 ? ft.toString() : '';
    _heightInCtrl.text = ft > 0 ? inch.toString() : '';
  }

  void _syncWeightControllers(double kg) {
    _weightKgCtrl.text = kg > 0 ? kg.round().toString() : '';
    _weightLbsCtrl.text = kg > 0 ? (kg * 2.20462).round().toString() : '';
  }

  void _toggleHeightUnit(bool toMetric) {
    final cm = _getHeightCm();
    if (cm > 0) _syncHeightControllers(cm);
    setState(() => _heightMetric = toMetric);
  }

  void _toggleWeightUnit(bool toMetric) {
    final kg = _getWeightKg();
    if (kg > 0) _syncWeightControllers(kg);
    setState(() => _weightMetric = toMetric);
  }

  void _next() {
    final cm = _getHeightCm();
    final kg = _getWeightKg();
    if (cm > 0) widget.data.height = cm;
    if (kg > 0) widget.data.weight = kg;
    // Store the unit preference driven by weight unit
    widget.data.isMetric = _weightMetric;

    if (widget.data.weight > 0 && widget.data.height > 0) {
      widget.data.bmi = MacroCalculator.calculateBMI(
        widget.data.weight,
        widget.data.height,
      );
      widget.data.bmiCalculationComplete = true;
    }
    Navigator.push(
      context,
      onboardingRoute(Screen06Activity(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 5,
      totalSteps: widget.data.totalSteps,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Your measurements',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose the unit that feels natural for each.',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // ── Height card ──
            _MeasurementCard(
              fieldLabel: 'HEIGHT',
              icon: Icons.height_rounded,
              isMetric: _heightMetric,
              metricLabel: 'cm',
              imperialLabel: 'ft / in',
              onToggle: _toggleHeightUnit,
              child: _heightMetric
                  ? _BigNumField(
                      controller: _heightCmCtrl,
                      unit: 'cm',
                      hint: '170',
                      maxLength: 3,
                    )
                  : _FtInRow(
                      feetCtrl: _heightFtCtrl,
                      inchCtrl: _heightInCtrl,
                    ),
            ),

            const SizedBox(height: 16),

            // ── Weight card ──
            _MeasurementCard(
              fieldLabel: 'WEIGHT',
              icon: Icons.monitor_weight_outlined,
              isMetric: _weightMetric,
              metricLabel: 'kg',
              imperialLabel: 'lbs',
              onToggle: _toggleWeightUnit,
              child: _weightMetric
                  ? _BigNumField(
                      controller: _weightKgCtrl,
                      unit: 'kg',
                      hint: '70',
                      maxLength: 3,
                    )
                  : _BigNumField(
                      controller: _weightLbsCtrl,
                      unit: 'lbs',
                      hint: '154',
                      maxLength: 4,
                    ),
            ),

            const SizedBox(height: 40),
            OnboardingContinueButton(onTap: _next),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ── Measurement card shell ────────────────────────────────────────────────────

class _MeasurementCard extends StatelessWidget {
  final String fieldLabel;
  final IconData icon;
  final bool isMetric;
  final String metricLabel;
  final String imperialLabel;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _MeasurementCard({
    required this.fieldLabel,
    required this.icon,
    required this.isMetric,
    required this.metricLabel,
    required this.imperialLabel,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: OColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OColors.borderMedium, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: label + inline unit toggle
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: OColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: OColors.primary, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                fieldLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: OColors.textTertiary,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _UnitPill(
                leftLabel: metricLabel,
                rightLabel: imperialLabel,
                leftActive: isMetric,
                onTap: () => onToggle(!isMetric),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Inline unit pill toggle ───────────────────────────────────────────────────

class _UnitPill extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool leftActive;
  final VoidCallback onTap;

  const _UnitPill({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: OColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OColors.borderMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill(leftLabel, leftActive),
            _pill(rightLabel, !leftActive),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? OColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active
            ? [
                BoxShadow(
                  color: OColors.primary.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Colors.white : OColors.textTertiary,
        ),
      ),
    );
  }
}

// ── Big number input field ────────────────────────────────────────────────────

class _BigNumField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String hint;
  final int maxLength;

  const _BigNumField({
    required this.controller,
    required this.unit,
    required this.hint,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ],
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: OColors.primary,
              letterSpacing: -2,
              height: 1.0,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: OColors.textTertiary.withValues(alpha: 0.35),
                letterSpacing: -2,
                height: 1.0,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(
            unit,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: OColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Feet + inches row ─────────────────────────────────────────────────────────

class _FtInRow extends StatelessWidget {
  final TextEditingController feetCtrl;
  final TextEditingController inchCtrl;

  const _FtInRow({required this.feetCtrl, required this.inchCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 72,
          child: TextField(
            controller: feetCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: OColors.primary,
              letterSpacing: -2,
              height: 1.0,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '5',
              hintStyle: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: OColors.textTertiary.withValues(alpha: 0.35),
                letterSpacing: -2,
                height: 1.0,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 7, right: 20),
          child: Text(
            'ft',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: OColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: TextField(
            controller: inchCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: OColors.primary,
              letterSpacing: -2,
              height: 1.0,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '9',
              hintStyle: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: OColors.textTertiary.withValues(alpha: 0.35),
                letterSpacing: -2,
                height: 1.0,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 7),
          child: Text(
            'in',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: OColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
