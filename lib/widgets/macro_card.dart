import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MacroType { protein, carbs, fats, calories }

class _MacroMeta {
  final String label;
  final Color color;
  final String unit;

  const _MacroMeta(this.label, this.color, this.unit);
}

const Map<MacroType, _MacroMeta> _macroMeta = {
  MacroType.protein: _MacroMeta('PROTEIN', Color(0xFF22C55E), 'g'),
  MacroType.carbs: _MacroMeta('CARBS', Color(0xFFF59E0B), 'g'),
  MacroType.fats: _MacroMeta('FATS', Color(0xFFEF4444), 'g'),
  MacroType.calories: _MacroMeta('CALS', Color(0xFF94A3B8), ''),
};

class MacroCard extends StatefulWidget {
  final int protein;
  final int carbs;
  final int fat;
  final int calories;
  final int goalProtein;
  final int goalCarbs;
  final int goalFat;
  final int goalCalories;
  final MacroType activeMacro;
  final ValueChanged<MacroType> onActiveMacroChanged;
  final bool isCollapsed;
  final int expansionResetKey;

  const MacroCard({
    super.key,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.calories = 0,
    this.goalProtein = 160,
    this.goalCarbs = 250,
    this.goalFat = 65,
    this.goalCalories = 2100,
    this.activeMacro = MacroType.protein,
    required this.onActiveMacroChanged,
    this.isCollapsed = false,
    this.expansionResetKey = 0,
  });

  @override
  State<MacroCard> createState() => _MacroCardState();
}

class _MacroCardState extends State<MacroCard> {
  bool _tapExpanded = false;
  Timer? _interactionTimer;

  bool get _isEffectivelyCollapsed => widget.isCollapsed && !_tapExpanded;

  @override
  void didUpdateWidget(MacroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCollapsed && widget.isCollapsed) {
      // Collapsed via scroll — drop tap override.
      _tapExpanded = false;
      _interactionTimer?.cancel();
    }
    if (oldWidget.expansionResetKey != widget.expansionResetKey) {
      // External force-collapse (e.g. food input focused) — drop tap override
      // even if isCollapsed was already true.
      _tapExpanded = false;
      _interactionTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    super.dispose();
  }

  void _onInteract() {
    if (widget.isCollapsed) {
      setState(() => _tapExpanded = true);
    }
    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _tapExpanded) {
        setState(() => _tapExpanded = false);
      }
    });
  }

  void _onMiniTap(MacroType type) {
    widget.onActiveMacroChanged(type);
    _onInteract();
  }

  int _valueFor(MacroType type) {
    switch (type) {
      case MacroType.protein:
        return widget.protein;
      case MacroType.carbs:
        return widget.carbs;
      case MacroType.fats:
        return widget.fat;
      case MacroType.calories:
        return widget.calories;
    }
  }

  int _goalFor(MacroType type) {
    switch (type) {
      case MacroType.protein:
        return widget.goalProtein;
      case MacroType.carbs:
        return widget.goalCarbs;
      case MacroType.fats:
        return widget.goalFat;
      case MacroType.calories:
        return widget.goalCalories;
    }
  }

  double _progressFor(MacroType type) {
    final goal = _goalFor(type);
    return goal > 0 ? (_valueFor(type) / goal).clamp(0.0, 1.0) : 0.0;
  }

  List<MacroType> get _inactiveMacros =>
      MacroType.values.where((m) => m != widget.activeMacro).toList();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isEffectivelyCollapsed ? _onInteract : null,
      onPanDown: (_) {
        if (!_isEffectivelyCollapsed) _onInteract();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        margin: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: _isEffectivelyCollapsed ? 12 : 8,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          _isEffectivelyCollapsed ? 12 : 10,
          20,
          10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFB),
          borderRadius: BorderRadius.circular(
            _isEffectivelyCollapsed ? 20 : 24,
          ),
          border: Border.all(color: const Color(0xFFF0F0F2), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 20,
              offset: Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: AnimatedCrossFade(
            firstChild: _buildCollapsedState(),
            secondChild: _buildExpandedState(),
            crossFadeState: _isEffectivelyCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            sizeCurve: Curves.fastOutSlowIn,
          ),
        ),
      ),
    );
  }

  // ─── Collapsed State ─────────────────────────────────────────────

  Widget _buildCollapsedState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildMiniStat(MacroType.calories)),
        Container(width: 1, height: 24, color: const Color(0xFFE8E8EC)),
        Expanded(child: _buildMiniStat(MacroType.protein)),
        Container(width: 1, height: 24, color: const Color(0xFFE8E8EC)),
        Expanded(child: _buildMiniStat(MacroType.carbs)),
        Container(width: 1, height: 24, color: const Color(0xFFE8E8EC)),
        Expanded(child: _buildMiniStat(MacroType.fats)),
      ],
    );
  }

  Widget _buildMiniStat(MacroType type) {
    final meta = _macroMeta[type]!;
    final value = _valueFor(type);

    return GestureDetector(
      onTap: () => _onMiniTap(type),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3038),
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              if (meta.unit.isNotEmpty)
                Text(
                  meta.unit,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            meta.label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB0B4BC),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Expanded State ──────────────────────────────────────────────

  Widget _buildExpandedState() {
    final active = widget.activeMacro;
    final meta = _macroMeta[active]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroSection(active, meta),
        const SizedBox(height: 8),
        Container(height: 0.5, color: const Color(0xFFE8E8EC)),
        const SizedBox(height: 4),
        _buildStatsRow(),
      ],
    );
  }

  Widget _buildHeroSection(MacroType active, _MacroMeta meta) {
    final value = _valueFor(active);
    final goal = _goalFor(active);
    final progress = _progressFor(active);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Column(
        key: ValueKey(active),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                builder: (context, animatedValue, _) {
                  return Text(
                    '$animatedValue',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: meta.color,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                meta.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB0B4BC),
                  letterSpacing: 1.8,
                ),
              ),
              const Spacer(),
              Text(
                '/ $goal',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFCBCDD3),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Progress bar
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEFF2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: double.infinity,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: meta.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final inactive = _inactiveMacros;

    return IntrinsicHeight(
      child: Row(
        children: [
          for (int i = 0; i < inactive.length; i++) ...[
            if (i > 0)
              Container(
                width: 0.5,
                margin: const EdgeInsets.symmetric(vertical: 3),
                color: const Color(0xFFE8E8EC),
              ),
            Expanded(child: _buildStatItem(inactive[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(MacroType type) {
    final meta = _macroMeta[type]!;
    final value = _valueFor(type);
    final suffix = meta.unit;

    return GestureDetector(
      onTap: () {
        widget.onActiveMacroChanged(type);
        _onInteract();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              meta.label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB0B4BC),
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  builder: (context, animatedValue, _) {
                    return Text(
                      '$animatedValue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3038),
                      ),
                    );
                  },
                ),
                if (suffix.isNotEmpty)
                  Text(
                    suffix,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB0B4BC),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
