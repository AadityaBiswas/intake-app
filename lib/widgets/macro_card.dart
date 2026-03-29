import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum MacroType { protein, carbs, fats, calories }

class _MacroMeta {
  final String label;
  final Color color;
  final String unit;

  const _MacroMeta(this.label, this.color, this.unit);
}

const Map<MacroType, _MacroMeta> _macroMeta = {
  MacroType.protein: _MacroMeta('Protein', Color(0xFF22C55E), 'g'),
  MacroType.carbs: _MacroMeta('Carbs', Color(0xFF3B82F6), 'g'),
  MacroType.fats: _MacroMeta('Fat', Color(0xFFF59E0B), 'g'),
  MacroType.calories: _MacroMeta('Calories', Color(0xFF94A3B8), 'kcal'),
};

const _kInactiveLabelColor = Color(0xFFB0BAC6);
const _kInactiveValueColor = Color(0xFF64748B);
const _kTrackColor = Color(0xFFF1F5F9);

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
  bool _userExpanded = false;
  bool _macroSelected = false;

  bool get _showExpanded => _userExpanded && !widget.isCollapsed;

  @override
  void didUpdateWidget(MacroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCollapsed && widget.isCollapsed) {
      setState(() => _userExpanded = false);
    }
    if (oldWidget.expansionResetKey != widget.expansionResetKey) {
      setState(() {
        _userExpanded = false;
        _macroSelected = false;
      });
    }
  }

  void _expand() {
    HapticFeedback.selectionClick();
    setState(() => _userExpanded = true);
  }

  void _collapse() {
    HapticFeedback.selectionClick();
    setState(() => _userExpanded = false);
  }

  void _onMacroTap(MacroType type) {
    HapticFeedback.selectionClick();
    setState(() => _macroSelected = true);
    widget.onActiveMacroChanged(type);
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

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: _showExpanded ? (_) => _collapse() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 16,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 340),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: _showExpanded ? _buildExpandedState() : _buildCollapsedState(),
        ),
      ),
    );
  }

  // ─── Collapsed ────────────────────────────────────────────────────

  Widget _buildCollapsedState() {
    final cal = _valueFor(MacroType.calories);
    final calGoal = _goalFor(MacroType.calories);
    final calOver = cal > calGoal;

    return GestureDetector(
      onTap: _expand,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Calories hero (left, dominant) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$cal',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'cal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB0BAC6),
                        letterSpacing: 0,
                      ),
                    ),
                    if (calOver) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '+${cal - calGoal}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'of $calGoal kcal',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFCBD5E0),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Thin rule ──
            Container(width: 1, height: 32, color: const Color(0xFFEEF2F7)),
            const SizedBox(width: 16),

            // ── Protein / Carbs / Fat compact cluster (right) ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactMacro(MacroType.protein),
                const SizedBox(width: 14),
                _buildCompactMacro(MacroType.carbs),
                const SizedBox(width: 14),
                _buildCompactMacro(MacroType.fats),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMacro(MacroType type) {
    final meta = _macroMeta[type]!;
    final value = _valueFor(type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$value',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
                height: 1,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              meta.unit,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB0BAC6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          meta.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD1D9E0),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  // ─── Expanded ─────────────────────────────────────────────────────

  Widget _buildExpandedState() {
    final calValue = _valueFor(MacroType.calories);
    final calGoal = _goalFor(MacroType.calories);
    final calProgress = _progressFor(MacroType.calories);
    final calIsOver = calValue > calGoal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Calories hero row (display only — not selectable) ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$calValue',
                      style: GoogleFonts.inter(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'cal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFB0BAC6),
                        ),
                      ),
                    ),
                    if (calIsOver) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${calValue - calGoal}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '/ $calGoal',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFCBD5E0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ProgressBar(
                  progress: calProgress,
                  color: const Color(0xFFDDE3EA),
                  height: 3,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 4),

          // ── Macro rows ──
          for (final type in [MacroType.protein, MacroType.carbs, MacroType.fats])
            _buildMacroRow(type),
        ],
      ),
    );
  }

  Widget _buildMacroRow(MacroType type) {
    final meta = _macroMeta[type]!;
    final value = _valueFor(type);
    final goal = _goalFor(type);
    final progress = _progressFor(type);
    final isActive = _macroSelected && widget.activeMacro == type;
    final isOver = value > goal;

    return GestureDetector(
      onTap: () => _onMacroTap(type),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? meta.color.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? meta.color : const Color(0xFFDDE3EA),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 58,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? meta.color.withValues(alpha: 0.85)
                      : _kInactiveLabelColor,
                  letterSpacing: -0.1,
                ),
                child: Text(meta.label),
              ),
            ),
            Expanded(
              child: _ProgressBar(
                progress: progress,
                color: isActive ? meta.color : const Color(0xFFE8EDF2),
                height: 3,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? meta.color : _kInactiveValueColor,
                    letterSpacing: -0.3,
                  ),
                  child: Text('$value'),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: (isActive ? meta.color : _kInactiveValueColor)
                        .withValues(alpha: 0.4),
                  ),
                  child: Text(meta.unit),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: (isOver && isActive)
                  ? Container(
                      key: const ValueKey('over'),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '+${value - goal}',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('none'), width: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress bar ──────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const _ProgressBar({
    required this.progress,
    required this.color,
    this.height = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: _kTrackColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              height: height,
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
  }
}
