import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'activity_level_screen.dart';
import '../../widgets/layered_page_route.dart';

class HeightScreen extends StatefulWidget {
  final OnboardingData data;
  const HeightScreen({super.key, required this.data});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _rulerCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  double _heightCm = 170.0;

  static const double _minCm = 100;
  static const double _maxCm = 220;
  static const double _tickSpacing = 14.0;

  @override
  void initState() {
    super.initState();
    _heightCm = widget.data.height > 0 ? widget.data.height : 170.0;
    _rulerCtrl = ScrollController(
      initialScrollOffset: (_heightCm - _minCm) * _tickSpacing,
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
    final newH = _minCm + _rulerCtrl.offset / _tickSpacing;
    setState(() => _heightCm = newH.clamp(_minCm, _maxCm));
  }

  @override
  void dispose() {
    _rulerCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    widget.data.height = _heightCm;
    Navigator.push(
        context, layeredRoute(ActivityLevelScreen(data: widget.data)));
  }

  String get _feetDisplay {
    final totalInches = _heightCm / 2.54;
    final ft = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return "$ft'$inches\"";
  }

  @override
  Widget build(BuildContext context) {
    final rulerH = (_maxCm - _minCm) * _tickSpacing;
    final screenH = MediaQuery.of(context).size.height;

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
                    Expanded(child: _StepBar(current: 5, total: 8)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter Your Height',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Main: green bar ruler (left) + value (right)
              Expanded(
                child: Row(
                  children: [
                    // Left: Green ruler bar
                    SizedBox(
                      width: 80,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 44,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            controller: _rulerCtrl,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              height: rulerH + screenH * 0.5,
                              width: 80,
                              child: CustomPaint(
                                painter: _VRulerPainter(
                                  min: _minCm,
                                  max: _maxCm,
                                  spacing: _tickSpacing,
                                  offsetTop: screenH * 0.25,
                                ),
                              ),
                            ),
                          ),
                          // Orange indicator line
                          Positioned(
                            left: 0,
                            right: 0,
                            top: screenH * 0.25 - 1.5,
                            child: Container(
                              height: 3,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right: Display
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _heightCm.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -2,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8, left: 4),
                                child: Text(
                                  'cm',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _feetDisplay,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('cm',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B))),
                                SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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

// ─── Vertical Ruler Painter ──────────────────────────────────────────

class _VRulerPainter extends CustomPainter {
  final double min, max, spacing, offsetTop;
  _VRulerPainter(
      {required this.min,
      required this.max,
      required this.spacing,
      required this.offsetTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    for (int i = 0; i <= (max - min).toInt(); i++) {
      final y = offsetTop + i * spacing;
      final val = min + i;
      final isMajor = val % 5 == 0;
      if (isMajor) {
        paint
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.9);
        canvas.drawLine(Offset(20, y), Offset(44, y), paint);
      } else {
        paint
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.5);
        canvas.drawLine(Offset(30, y), Offset(44, y), paint);
      }
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${val.toInt()}',
            style: TextStyle(
              fontSize: val.toInt() % 10 == 0 ? 14 : 12,
              fontWeight: val.toInt() % 10 == 0
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(50, y - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
