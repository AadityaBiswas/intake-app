import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFEEF2F7);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF64748B);
const _kTextTertiary = Color(0xFFB0BAC6);
const _kDivider = Color(0xFFF1F5F9);
const _kHandle = Color(0xFFDDE3ED);
const _kGreen = Color(0xFF22C55E);

class ProgressSheet extends StatefulWidget {
  const ProgressSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const ProgressSheet(),
    );
  }

  @override
  State<ProgressSheet> createState() => _ProgressSheetState();
}

class _ProgressSheetState extends State<ProgressSheet> {
  late DateTime _displayMonth;
  Map<int, int> _dayFoodCounts = {};
  int _currentStreak = 0;
  int _totalDaysLogged = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadMonthData(), _loadStreak()]);
    if (mounted) setState(() => _loading = false);
  }

  bool get _isCurrentMonth =>
      _displayMonth.year == DateTime.now().year &&
      _displayMonth.month == DateTime.now().month;

  void _prev() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
    _loadMonthData();
  }

  void _next() {
    if (_isCurrentMonth) return;
    HapticFeedback.selectionClick();
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1);
    final now = DateTime.now();
    if (next.year > now.year ||
        (next.year == now.year && next.month > now.month)) {
      return;
    }
    setState(() => _displayMonth = next);
    _loadMonthData();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadMonthData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final logsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_logs');

    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final monthStart =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}-01';
    final monthEnd =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}-${daysInMonth.toString().padLeft(2, '0')}';

    final snap = await logsRef
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: monthStart)
        .where(FieldPath.documentId, isLessThanOrEqualTo: monthEnd)
        .get();

    if (snap.docs.isEmpty) {
      if (mounted) setState(() { _dayFoodCounts = {}; _totalDaysLogged = 0; });
      return;
    }

    final counts = <int, int>{};
    await Future.wait(
      snap.docs.map((doc) async {
        final parts = doc.id.split('-');
        if (parts.length != 3) return;
        final day = int.tryParse(parts[2]);
        if (day == null) return;
        final foodSnap = await doc.reference.collection('foods').count().get();
        final c = foodSnap.count ?? 0;
        if (c > 0) counts[day] = c;
      }),
    );

    if (mounted) {
      setState(() {
        _dayFoodCounts = counts;
        _totalDaysLogged = counts.length;
      });
    }
  }

  Future<void> _loadStreak() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final logsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_logs');

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final startDate = todayNorm.subtract(const Duration(days: 364));

    final snap = await logsRef
        .where(FieldPath.documentId,
            isGreaterThanOrEqualTo: _dateKey(startDate))
        .where(FieldPath.documentId, isLessThanOrEqualTo: _dateKey(todayNorm))
        .get();

    if (snap.docs.isEmpty) {
      if (mounted) setState(() => _currentStreak = 0);
      return;
    }

    final daysWithFood = <String>{};
    await Future.wait(
      snap.docs.map((doc) async {
        final foodSnap =
            await doc.reference.collection('foods').limit(1).get();
        if (foodSnap.docs.isNotEmpty) daysWithFood.add(doc.id);
      }),
    );

    int streak = 0;
    DateTime checkDate = todayNorm;
    for (int i = 0; i < 365; i++) {
      if (daysWithFood.contains(_dateKey(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    if (mounted) setState(() => _currentStreak = streak);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final consistency =
        daysInMonth > 0 ? ((_totalDaysLogged / daysInMonth) * 100).round() : 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  'Progress',
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

          // Stats strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _StatChip(
                  value: '$_currentStreak',
                  label: 'Day streak',
                  icon: Icons.local_fire_department_rounded,
                  highlight: _currentStreak > 0,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  value: '$_totalDaysLogged',
                  label: 'Days logged',
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  value: '$consistency%',
                  label: 'Consistency',
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Calendar section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorder, width: 1),
              ),
              child: Column(
                children: [
                  // Month header + nav
                  Row(
                    children: [
                      Text(
                        _monthName(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _NavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: _prev,
                            enabled: true,
                          ),
                          const SizedBox(width: 6),
                          _NavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: _next,
                            enabled: !_isCurrentMonth,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Day-of-week header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DayLabel('M'), _DayLabel('T'), _DayLabel('W'),
                      _DayLabel('T'), _DayLabel('F'), _DayLabel('S'),
                      _DayLabel('S'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Grid
                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _kGreen,
                              ),
                            ),
                          ),
                        )
                      : _buildGrid(),
                  const SizedBox(height: 10),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(const Color(0xFFE2E8F0)),
                      const SizedBox(width: 5),
                      const Text('None',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _kTextTertiary)),
                      const SizedBox(width: 14),
                      _legendDot(const Color(0xFFBBF7D0)),
                      const SizedBox(width: 5),
                      const Text('Some',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _kTextTertiary)),
                      const SizedBox(width: 14),
                      _legendDot(_kGreen),
                      const SizedBox(width: 5),
                      const Text('Lots',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _kTextTertiary)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;
    final today = DateTime.now();

    int maxCount = 1;
    for (final c in _dayFoodCounts.values) {
      if (c > maxCount) maxCount = c;
    }

    return Column(
      children: List.generate(6, (week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (dow) {
              final dayNum = week * 7 + dow + 1 - (firstWeekday - 1);
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox(width: 34, height: 34);
              }
              final date = DateTime(
                  _displayMonth.year, _displayMonth.month, dayNum);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isPast = date.isBefore(today) || isToday;
              final count = _dayFoodCounts[dayNum] ?? 0;
              final intensity = isPast && count > 0
                  ? (count / maxCount).clamp(0.2, 1.0)
                  : 0.0;

              Color bgColor;
              if (intensity > 0) {
                bgColor = Color.lerp(
                  const Color(0xFFDCFCE7),
                  _kGreen,
                  intensity,
                )!;
              } else if (isPast) {
                bgColor = const Color(0xFFE2E8F0);
              } else {
                bgColor = _kDivider;
              }

              return Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday
                      ? Border.all(color: _kGreen, width: 2)
                      : null,
                ),
                child: isToday
                    ? Center(
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: intensity > 0.5
                                ? Colors.white
                                : _kGreen,
                          ),
                        ),
                      )
                    : null,
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
  );

  String _monthName() {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[_displayMonth.month]} ${_displayMonth.year}';
  }
}

// ── Stat Chip ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool highlight;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFECFDF5) : _kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? const Color(0xFFBBF7D0)
                : _kBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: highlight ? _kGreen : _kTextTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: highlight ? _kGreen : _kTextPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kTextTertiary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Button ─────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _kTextSecondary : const Color(0xFFD1D9E0),
        ),
      ),
    );
  }
}

// ── Day Label ──────────────────────────────────────────────────────────────────

class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _kTextTertiary,
        letterSpacing: 0.3,
      ),
    ),
  );
}
