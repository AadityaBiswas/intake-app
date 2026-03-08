import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadMonthData();
    _loadStreak();
  }

  bool get _isCurrentMonth =>
      _displayMonth.year == DateTime.now().year &&
      _displayMonth.month == DateTime.now().month;

  void _prev() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
    _loadMonthData();
  }

  void _next() {
    // Block navigating to future months
    if (_isCurrentMonth) return;
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1);
    final now = DateTime.now();
    if (next.year > now.year ||
        (next.year == now.year && next.month > now.month)) {
      return;
    }
    setState(() {
      _displayMonth = next;
    });
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

    final daysInMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month + 1,
      0,
    ).day;
    final monthStart =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}-01';
    final monthEnd =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}-${daysInMonth.toString().padLeft(2, '0')}';

    final snap = await logsRef
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: monthStart)
        .where(FieldPath.documentId, isLessThanOrEqualTo: monthEnd)
        .get();

    if (snap.docs.isEmpty) {
      if (mounted)
        setState(() {
          _dayFoodCounts = {};
          _totalDaysLogged = 0;
        });
      return;
    }

    // Concurrently fetch food counts for all existing day docs
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

    // Fetch up to the last 365 days in one query, then check concurrently
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final startDate = todayNorm.subtract(const Duration(days: 364));

    final snap = await logsRef
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: _dateKey(startDate),
        )
        .where(FieldPath.documentId, isLessThanOrEqualTo: _dateKey(todayNorm))
        .get();

    if (snap.docs.isEmpty) {
      if (mounted) setState(() => _currentStreak = 0);
      return;
    }

    // Concurrently check which docs have at least one food
    final daysWithFood = <String>{};
    await Future.wait(
      snap.docs.map((doc) async {
        final foodSnap = await doc.reference.collection('foods').limit(1).get();
        if (foodSnap.docs.isNotEmpty) daysWithFood.add(doc.id);
      }),
    );

    // Walk backwards from today to compute streak
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

  void _editGoal(String currentGoal) {
    final goals = ['Lose Weight', 'Maintain Weight', 'Gain Weight'];
    final goalIcons = {
      'Lose Weight': Icons.trending_down_rounded,
      'Maintain Weight': Icons.balance_rounded,
      'Gain Weight': Icons.trending_up_rounded,
    };
    final goalSubtitles = {
      'Lose Weight': 'Create a calorie deficit',
      'Maintain Weight': 'Stay fit and healthy',
      'Gain Weight': 'Build muscle and strength',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Your Goal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: goals.asMap().entries.map((entry) {
                  final goal = entry.value;
                  final isSelected = goal == currentGoal;
                  final isLast = entry.key == goals.length - 1;
                  return Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({'weight_goal': goal});
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  goalIcons[goal],
                                  size: 16,
                                  color: isSelected
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF64748B),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      goalSubtitles[goal]!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          indent: 52,
                          color: Color(0xFFF1F5F9),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final weightGoal =
            data['weightGoal'] as String? ??
            data['weight_goal'] as String? ??
            'Maintain Weight';

        final daysInMonth = DateTime(
          _displayMonth.year,
          _displayMonth.month + 1,
          0,
        ).day;
        final consistency = daysInMonth > 0
            ? ((_totalDaysLogged / daysInMonth) * 100).round()
            : 0;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 40,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title + close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0x99E2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // YOUR GOAL — tappable
              GestureDetector(
                onTap: () => _editGoal(weightGoal),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Color(0xFF22C55E),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weightGoal,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const Text(
                              'Tap to change goal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Month + nav
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _monthName(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _prev,
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isCurrentMonth ? null : _next,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: _isCurrentMonth
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Day headers
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DayLabel('M'),
                  _DayLabel('T'),
                  _DayLabel('W'),
                  _DayLabel('T'),
                  _DayLabel('F'),
                  _DayLabel('S'),
                  _DayLabel('S'),
                ],
              ),
              const SizedBox(height: 6),
              _buildGrid(),
              const SizedBox(height: 6),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _legendDot(const Color(0xFFE2E8F0)),
                  const SizedBox(width: 4),
                  const Text(
                    'None',
                    style: TextStyle(fontSize: 10, color: Color(0xFFB0B8C4)),
                  ),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF86EFAC)),
                  const SizedBox(width: 4),
                  const Text(
                    'Some',
                    style: TextStyle(fontSize: 10, color: Color(0xFFB0B8C4)),
                  ),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  const Text(
                    'Lots',
                    style: TextStyle(fontSize: 10, color: Color(0xFFB0B8C4)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Current Streak',
                      value:
                          '$_currentStreak ${_currentStreak == 1 ? 'Day' : 'Days'}',
                    ),
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: Color(0xFFF1F5F9),
                    ),
                    _StatRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Days Logged',
                      value: '$_totalDaysLogged this month',
                    ),
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: Color(0xFFF1F5F9),
                    ),
                    _StatRow(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Consistency',
                      value: '$consistency%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    final daysInMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _displayMonth.year,
      _displayMonth.month,
      1,
    ).weekday;
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
                return const SizedBox(width: 32, height: 32);
              }
              final date = DateTime(
                _displayMonth.year,
                _displayMonth.month,
                dayNum,
              );
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isPast = date.isBefore(today) || isToday;
              final count = _dayFoodCounts[dayNum] ?? 0;
              final intensity = isPast && count > 0
                  ? (count / maxCount).clamp(0.2, 1.0)
                  : 0.0;

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: intensity > 0
                      ? Color.lerp(
                          const Color(0xFFBBF7D0),
                          const Color(0xFF22C55E),
                          intensity,
                        )
                      : (isPast
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(color: const Color(0xFF22C55E), width: 2)
                      : null,
                ),
                child: isToday
                    ? Center(
                        child: Text(
                          '$dayNum',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
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
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  String _monthName() {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[_displayMonth.month]} ${_displayMonth.year}';
  }
}

class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel(this.label);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFFB0B8C4),
      ),
    ),
  );
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    ),
  );
}
