import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding_data.dart';
import 'screen_09_experience.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 8 — Desired Weight
/// Default value is the scientifically ideal weight (BMI 22).
class Screen08DesiredWeight extends StatefulWidget {
  final OnboardingData data;
  const Screen08DesiredWeight({super.key, required this.data});

  @override
  State<Screen08DesiredWeight> createState() => _Screen08DesiredWeightState();
}

class _Screen08DesiredWeightState extends State<Screen08DesiredWeight> {
  late TextEditingController _weightCtrl;
  String? _validationError;

  bool get _isMetric => widget.data.isMetric;

  double _displayToKg(double display) =>
      _isMetric ? display : display / 2.20462;
  double _kgToDisplay(double kg) => _isMetric ? kg : kg * 2.20462;

  double _computeSuitableWeightKg() {
    final heightM = widget.data.height / 100;
    final idealKg = 22.0 * heightM * heightM;
    final currentKg = widget.data.weight;
    switch (widget.data.primaryGoal) {
      case 'Weight Loss':
        return idealKg < currentKg ? idealKg : currentKg * 0.90;
      case 'Weight Gain':
        return idealKg > currentKg ? idealKg : currentKg * 1.10;
      default:
        return currentKg;
    }
  }

  @override
  void initState() {
    super.initState();
    final targetKg = widget.data.targetWeight > 0
        ? widget.data.targetWeight
        : _computeSuitableWeightKg();
    final displayVal = _kgToDisplay(targetKg);
    _weightCtrl = TextEditingController(text: displayVal.round().toString());
    _weightCtrl.addListener(() => setState(() => _validate()));
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  double get _selectedWeightKg {
    final val = double.tryParse(_weightCtrl.text) ?? 0;
    return val > 0 ? _displayToKg(val) : 0;
  }

  /// Returns null when target BMI is healthy (18.5–27.5).
  /// Returns a message + severity when outside healthy range.
  ({String message, bool isDanger})? _targetBmiWarning() {
    final targetKg = _selectedWeightKg;
    if (targetKg <= 0) return null;
    final heightM = widget.data.height / 100;
    if (heightM <= 0) return null;
    final targetBmi = targetKg / (heightM * heightM);
    if (targetBmi < 15.0) {
      return (
        message:
            'Target BMI ${targetBmi.toStringAsFixed(1)} is dangerously underweight. '
            'This could pose serious health risks.',
        isDanger: true,
      );
    }
    if (targetBmi < 18.5) {
      return (
        message:
            'Target BMI ${targetBmi.toStringAsFixed(1)} is in the underweight range. '
            'Consider setting a higher target.',
        isDanger: false,
      );
    }
    if (targetBmi >= 30.0) {
      return (
        message:
            'Target BMI ${targetBmi.toStringAsFixed(1)} is in the obese range. '
            'A lower target may be healthier.',
        isDanger: false,
      );
    }
    if (targetBmi >= 27.5) {
      return (
        message:
            'Target BMI ${targetBmi.toStringAsFixed(1)} is in the overweight range. '
            'You may want to consider a lower target.',
        isDanger: false,
      );
    }
    return null;
  }

  void _validate() {
    final current = widget.data.weight;
    final target = _selectedWeightKg;
    final goal = widget.data.primaryGoal;
    if (target <= 0) {
      _validationError = 'Please enter a valid weight';
      return;
    }
    if (goal == 'Weight Loss' && target >= current) {
      _validationError =
          'Target must be lower than current (${widget.data.displayWeight(current)})';
    } else if (goal == 'Weight Gain' && target <= current) {
      _validationError =
          'Target must be higher than current (${widget.data.displayWeight(current)})';
    } else {
      _validationError = null;
    }
  }

  bool get _isValid {
    _validate();
    return _validationError == null && _selectedWeightKg > 0;
  }

  void _next() {
    _validate();
    setState(() {});
    if (!_isValid) return;
    widget.data.targetWeight = _selectedWeightKg;
    Navigator.push(
      context,
      onboardingRoute(Screen09Experience(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _validate();
    final currentWeightKg = widget.data.weight;
    final targetKg = _selectedWeightKg;
    final unitLabel = _isMetric ? 'kg' : 'lbs';
    final isLoss = widget.data.primaryGoal == 'Weight Loss';
    final isGain = widget.data.primaryGoal == 'Weight Gain';
    final bmiWarning = _targetBmiWarning();

    final diffKg = targetKg > 0 ? (targetKg - currentWeightKg).abs() : 0.0;
    final diffDisplay = _isMetric
        ? '${diffKg.toStringAsFixed(1)} kg'
        : '${(diffKg * 2.20462).toStringAsFixed(1)} lbs';
    final directionLabel = targetKg < currentWeightKg ? 'to lose' : 'to gain';

    return OnboardingScaffold(
      currentStep: 8,
      totalSteps: widget.data.totalSteps,
      banners: [
        CalculationBanner(
          label: 'Calculating your BMI…',
          completeLabel: 'BMI calculated',
          durationSeconds: 30,
          startTime: widget.data.bmiCalculationStartTime,
          onComplete: () =>
              setState(() => widget.data.bmiCalculationComplete = true),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Your target weight',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLoss
                  ? 'How much would you like to weigh?'
                  : isGain
                  ? 'What weight are you building towards?'
                  : 'Confirm your ideal maintenance weight.',
              style: const TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: _WeightChip(
                    label: 'Current',
                    value: widget.data.displayWeight(currentWeightKg),
                    color: OColors.textSecondary,
                    bgColor: OColors.surface,
                    borderColor: OColors.borderMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: OColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLoss
                        ? Icons.arrow_downward_rounded
                        : isGain
                        ? Icons.arrow_upward_rounded
                        : Icons.remove_rounded,
                    size: 16,
                    color: OColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WeightChip(
                    label: 'Target',
                    value: targetKg > 0
                        ? '${_kgToDisplay(targetKg).round()} $unitLabel'
                        : '—',
                    color: _isValid ? OColors.primary : OColors.textSecondary,
                    bgColor:
                        _isValid ? OColors.primaryLight : OColors.background,
                    borderColor:
                        _isValid ? OColors.primary : OColors.borderMedium,
                  ),
                ),
              ],
            ),

            if (targetKg > 0 && diffKg > 0.1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Text(
                    '$diffDisplay $directionLabel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isValid ? OColors.primary : OColors.textTertiary,
                    ),
                  ),
                ),
              ),

            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: OColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _validationError!,
                    style: const TextStyle(
                      color: OColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // BMI health warning for target weight
            if (bmiWarning != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: bmiWarning.isDanger
                        ? OColors.errorBg
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bmiWarning.isDanger
                          ? OColors.error.withValues(alpha: 0.35)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        bmiWarning.isDanger
                            ? Icons.warning_rounded
                            : Icons.info_outline_rounded,
                        size: 17,
                        color: bmiWarning.isDanger
                            ? OColors.error
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          bmiWarning.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: bmiWarning.isDanger
                                ? OColors.error
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),
            const Text(
              'TARGET WEIGHT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: OColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: OColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_validationError != null ||
                          bmiWarning?.isDanger == true)
                      ? OColors.error.withValues(alpha: 0.4)
                      : bmiWarning != null
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                          : OColors.borderMedium,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: (bmiWarning?.isDanger == true)
                            ? OColors.error
                            : OColors.primary,
                        letterSpacing: -1.5,
                        height: 1.0,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '—',
                        hintStyle: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: OColors.textTertiary.withValues(alpha: 0.4),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      unitLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: OColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pre-filled with your ideal healthy weight',
              style: TextStyle(fontSize: 12, color: OColors.textTertiary),
            ),
            const SizedBox(height: 40),
            OnboardingContinueButton(onTap: _next, enabled: _isValid),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _WeightChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _WeightChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: OColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
