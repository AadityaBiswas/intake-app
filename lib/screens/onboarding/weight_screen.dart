import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'height_screen.dart';
import '../../widgets/layered_page_route.dart';

class WeightScreen extends StatefulWidget {
  final OnboardingData data;
  const WeightScreen({super.key, required this.data});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _rulerCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  double _weight = 70.0;
  bool _isKg = true;

  static const double _minKg = 30;
  static const double _maxKg = 200;
  static const double _tickSpacing = 8.0;

  @override
  void initState() {
    super.initState();
    _weight = widget.data.weight > 0 ? widget.data.weight : 70.0;
    _rulerCtrl = ScrollController(
      initialScrollOffset: (_weight - _minKg) * _tickSpacing,
    );
    _rulerCtrl.addListener(_onScroll);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  void _onScroll() {
    final newWeight = _minKg + _rulerCtrl.offset / _tickSpacing;
    setState(() => _weight = newWeight.clamp(_minKg, _maxKg));
  }

  @override
  void dispose() {
    _rulerCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    widget.data.weight = _isKg ? _weight : _weight * 0.453592;
    Navigator.push(context, layeredRoute(HeightScreen(data: widget.data)));
  }

  String get _displayWeight {
    if (_isKg) return _weight.toStringAsFixed(1);
    return (_weight * 2.20462).toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final rulerW = (_maxKg - _minKg) * _tickSpacing;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left_rounded,
                          size: 28, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _StepBar(current: 4, total: 8)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Enter Your Weight',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps us calculate your daily protein needs.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),

              const Spacer(flex: 2),

              // ─── Weight display (BIG) ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _displayWeight,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 4),
                    child: Text(
                      _isKg ? 'kg' : 'lb',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Ruler ───
              SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Center indicator
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Scrollable ruler
                    SingleChildScrollView(
                      controller: _rulerCtrl,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: rulerW + screenW,
                        height: 80,
                        child: CustomPaint(
                          painter: _RulerPainter(
                            min: _minKg,
                            max: _maxKg,
                            spacing: _tickSpacing,
                            offsetLeft: screenW / 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── KG / LB toggle (compact) ───
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UnitPill(label: 'KG', active: _isKg,
                        onTap: () => setState(() => _isKg = true)),
                    _UnitPill(label: 'LB', active: !_isKg,
                        onTap: () => setState(() => _isKg = false)),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Continue
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: _ContinueBtn(onTap: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ruler Painter ──────────────────────────────────────────────────────

class _RulerPainter extends CustomPainter {
  final double min, max, spacing, offsetLeft;
  _RulerPainter(
      {required this.min,
      required this.max,
      required this.spacing,
      required this.offsetLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    for (int i = 0; i <= (max - min).toInt(); i++) {
      final x = offsetLeft + i * spacing;
      final val = min + i;
      final isMajor = val % 10 == 0;
      final isMid = val % 5 == 0 && !isMajor;
      if (isMajor) {
        paint
          ..strokeWidth = 1.5
          ..color = const Color(0xFF64748B);
        canvas.drawLine(Offset(x, 44), Offset(x, 72), paint);
        final tp = TextPainter(
          text: TextSpan(
              text: '${val.toInt()}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 74));
      } else if (isMid) {
        paint
          ..strokeWidth = 1.0
          ..color = const Color(0xFF94A3B8);
        canvas.drawLine(Offset(x, 48), Offset(x, 68), paint);
      } else {
        paint
          ..strokeWidth = 0.7
          ..color = const Color(0xFFCBD5E1);
        canvas.drawLine(Offset(x, 52), Offset(x, 64), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Unit toggle pill ───────────────────────────────────────────────────

class _UnitPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _UnitPill(
      {required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : [],
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8))),
        ),
      );
}

// ─── Shared ──────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current, total;
  const _StepBar({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < current
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      );
}

class _ContinueBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Continue',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      );
}
