import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_04_gender_age.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 3 — Name Input
/// First Name (required), Middle Name (optional), Last Name (required).
class Screen03Name extends StatefulWidget {
  final OnboardingData data;
  const Screen03Name({super.key, required this.data});

  @override
  State<Screen03Name> createState() => _Screen03NameState();
}

class _Screen03NameState extends State<Screen03Name> {
  final _firstCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstCtrl.text = widget.data.firstName;
    _middleCtrl.text = widget.data.middleName;
    _lastCtrl.text = widget.data.lastName;
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _middleCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _firstCtrl.text.trim().isNotEmpty && _lastCtrl.text.trim().isNotEmpty;

  void _next() {
    if (!_isValid) return;
    widget.data.firstName = _firstCtrl.text.trim();
    widget.data.middleName = _middleCtrl.text.trim();
    widget.data.lastName = _lastCtrl.text.trim();
    Navigator.push(
      context,
      onboardingRoute(Screen04GenderAge(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 3,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              "What's your name?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll use this to personalize your experience.",
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            _NameField(
              controller: _firstCtrl,
              hint: 'First name *',
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _NameField(
              controller: _middleCtrl,
              hint: 'Middle name (optional)',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _NameField(
              controller: _lastCtrl,
              hint: 'Last name *',
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _next(),
            ),
            const Spacer(),
            OnboardingContinueButton(onTap: _next, enabled: _isValid),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _NameField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OColors.border),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: OColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: OColors.textTertiary,
            fontWeight: FontWeight.w400,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 17,
          ),
        ),
      ),
    );
  }
}
