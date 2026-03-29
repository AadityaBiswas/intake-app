import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Design tokens
// ──────────────────────────────────────────────────────────────────────────────

class OColors {
  OColors._();
  static const primary = Color(0xFF22C55E);
  static const primaryLight = Color(0xFFECFDF5);
  static const surface = Colors.white;
  static const background = Color(0xFFF6F7F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF94A3B8);
  static const textTertiary = Color(0xFFB0B8C4);
  static const border = Color(0xFFF1F5F9);
  static const borderMedium = Color(0xFFE2E8F0);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const caloriePrimary = Color(0xFF22C55E);
  static const proteinColor = Color(0xFF3B82F6);
  static const carbColor = Color(0xFFF59E0B);
  static const fatColor = Color(0xFFEF4444);
}

// ──────────────────────────────────────────────────────────────────────────────
// 1. Segmented Progress Bar
// ──────────────────────────────────────────────────────────────────────────────

class SegmentedProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SegmentedProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isActive = i < currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 4,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isActive ? OColors.primary : OColors.borderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 2. Selection Card
// ──────────────────────────────────────────────────────────────────────────────

class SelectionCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    required this.label,
    this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? OColors.primaryLight : OColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? OColors.primary : OColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? OColors.primary.withValues(alpha: 0.12)
                    : OColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? OColors.primary : OColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? OColors.textPrimary
                          : const Color(0xFF64748B),
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: OColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: OColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 3. Continue Button
// ──────────────────────────────────────────────────────────────────────────────

class OnboardingContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool isLoading;
  final bool enabled;

  const OnboardingContinueButton({
    super.key,
    required this.onTap,
    this.label = 'Continue',
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !isLoading;
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: isActive
              ? OColors.primary
              : OColors.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: OColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 4. Onboarding Scaffold
// ──────────────────────────────────────────────────────────────────────────────

class OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool showBackButton;
  final Widget body;
  final List<Widget>? banners;
  final Widget? bottomWidget;

  const OnboardingScaffold({
    super.key,
    required this.currentStep,
    this.totalSteps = 16,
    this.showBackButton = true,
    required this.body,
    this.banners,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 28, 0),
              child: Row(
                children: [
                  if (showBackButton)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 28,
                          color: OColors.textPrimary,
                        ),
                      ),
                    ),
                  Expanded(
                    child: SegmentedProgressBar(
                      currentStep: currentStep,
                      totalSteps: totalSteps,
                    ),
                  ),
                ],
              ),
            ),

            if (banners != null && banners!.isNotEmpty) ...banners!,

            Expanded(child: body),

            if (bottomWidget != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: bottomWidget!,
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 5. Calculation Banner
// Uses wall-clock startTime to resume progress across screen navigations.
// The banner picks up exactly where it left off regardless of which screen
// the user is on when rendering.
// ──────────────────────────────────────────────────────────────────────────────

class CalculationBanner extends StatefulWidget {
  final String label;
  final String completeLabel;
  final int durationSeconds;

  /// The wall-clock time when the calculation was triggered.
  /// When null the banner is not shown. When non-null the banner resumes
  /// from the correct elapsed position, even after screen navigation.
  final DateTime? startTime;

  final VoidCallback? onComplete;

  const CalculationBanner({
    super.key,
    required this.label,
    this.completeLabel = '',
    required this.durationSeconds,
    this.startTime,
    this.onComplete,
  });

  @override
  State<CalculationBanner> createState() => _CalculationBannerState();
}

class _CalculationBannerState extends State<CalculationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isDone) {
        if (mounted) setState(() => _isDone = true);
        widget.onComplete?.call();
      }
    });
    if (widget.startTime != null) {
      _resumeFromStartTime(widget.startTime!);
    }
  }

  @override
  void didUpdateWidget(CalculationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime == null && widget.startTime != null) {
      _resumeFromStartTime(widget.startTime!);
    }
  }

  void _resumeFromStartTime(DateTime startTime) {
    final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
    final totalMs = widget.durationSeconds * 1000;
    final progress = (elapsedMs / totalMs).clamp(0.0, 1.0);

    if (progress >= 1.0) {
      _ctrl.value = 1.0;
      if (mounted) setState(() => _isDone = true);
      // Notify via post-frame so it doesn't fire during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDone) {
          setState(() => _isDone = true);
        }
        widget.onComplete?.call();
      });
    } else {
      _ctrl.value = progress;
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startTime == null) return const SizedBox.shrink();

    final displayLabel = _isDone
        ? (widget.completeLabel.isNotEmpty ? widget.completeLabel : widget.label)
        : widget.label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: _isDone ? OColors.primaryLight : OColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isDone ? OColors.primary : OColors.borderMedium,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isDone
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('done'),
                          color: OColors.primary,
                          size: 18,
                        )
                      : const SizedBox(
                          key: ValueKey('loading'),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: OColors.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isDone ? '$displayLabel ✓' : displayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isDone ? OColors.primary : OColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isDone)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: LinearProgressIndicator(
                    value: _ctrl.value,
                    minHeight: 3,
                    backgroundColor: OColors.borderMedium,
                    color: OColors.primary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 6. Unit Toggle Chip
// ──────────────────────────────────────────────────────────────────────────────

class UnitToggle extends StatelessWidget {
  final bool isMetric;
  final ValueChanged<bool> onChanged;

  const UnitToggle({
    super.key,
    required this.isMetric,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: OColors.border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('Metric', isMetric, () => onChanged(true)),
          _chip('Imperial', !isMetric, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? OColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: OColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? OColors.textPrimary : OColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 7. Info Row
// ──────────────────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: OColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? OColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
