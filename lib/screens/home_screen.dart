import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/macro_card.dart';
import '../widgets/food_list_item.dart';
import '../widgets/smart_food_input.dart';
import '../modals/account_sheet.dart';
import '../modals/food_detail_sheet.dart';
import '../services/food_service.dart';
import '../services/log_service.dart';
import '../models/food.dart';
import '../models/scaled_nutrition.dart';
import '../models/logged_food_entry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FoodService _foodService = FoodService();
  final LogService _logService = LogService();

  late DateTime _today;

  MacroType _activeMacro = MacroType.protein;

  // Macro goals from Firestore
  int _goalProtein = 160;
  int _goalCarbs = 250;
  int _goalFat = 65;
  int _goalCalories = 2100;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _listenToGoals();
  }

  void _listenToGoals() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data == null || !mounted) return;
      setState(() {
        _goalProtein = (data['goal_protein'] as num?)?.toInt() ?? 160;
        _goalCarbs = (data['goal_carbs'] as num?)?.toInt() ?? 250;
        _goalFat = (data['goal_fat'] as num?)?.toInt() ?? 65;
        _goalCalories = (data['goal_calories'] as num?)?.toInt() ?? 2100;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ─── Date helpers ───────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ─── Food helpers ──────────────────────────────────────────────────

  Future<void> _onFoodAddedForDate(
      Food food, ScaledNutrition nutrition, String userTypedName, DateTime date,
      {String? thoughtProcess, List<String>? sources}) async {
    final namedFood = food.copyWith(name: userTypedName);
    final entry = LoggedFoodEntry(
      food: namedFood,
      nutrition: nutrition,
      thoughtProcess: thoughtProcess,
      sources: sources,
    );
    await _logService.logFood(date, entry);
  }

  Future<void> _onCustomFoodForDate(String name, DateTime date) async {
    final placeholder = Food(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      nameLowercase: name.toLowerCase(),
      searchKeywords: name.toLowerCase().split(' '),
      nutritionPer100g: const NutritionPer100g(
        calories: 0, protein: 0, carbs: 0, fat: 0,
      ),
    );
    final zeroNutrition = const ScaledNutrition(
      calories: 0, protein: 0, carbs: 0, fat: 0, gramsUsed: 100,
    );
    final entry = LoggedFoodEntry(food: placeholder, nutrition: zeroNutrition);
    await _logService.logFood(date, entry);
  }

  int _macroVal(LoggedFoodEntry e, MacroType t) {
    switch (t) {
      case MacroType.protein: return e.nutrition.protein.round();
      case MacroType.carbs:   return e.nutrition.carbs.round();
      case MacroType.fats:    return e.nutrition.fat.round();
      case MacroType.calories: return e.nutrition.calories.round();
    }
  }

  Set<int> _getDominantFoodIndices(List<LoggedFoodEntry> foods) {
    if (foods.isEmpty) return {};
    final dom = <int>{};

    if (_activeMacro == MacroType.calories) {
      final n = (foods.length * 0.40).ceil();
      if (n > 0) {
        final e = <MapEntry<int, int>>[];
        for (int i = 0; i < foods.length; i++) {
          final c = foods[i].nutrition.calories.round();
          if (c > 0) e.add(MapEntry(i, c));
        }
        e.sort((a, b) => b.value.compareTo(a.value));
        dom.addAll(e.take(n).map((x) => x.key));
      }
      return dom;
    }

    for (int i = 0; i < foods.length; i++) {
      final f = foods[i];
      final pc = f.nutrition.protein * 4;
      final cc = f.nutrition.carbs * 4;
      final fc = f.nutrition.fat * 9;
      final tot = pc + cc + fc;
      if (tot < 50) continue;
      final pp = pc / tot, cp = cc / tot, fp = fc / tot;
      double active = 0, maxOther = 0;
      switch (_activeMacro) {
        case MacroType.protein: active = pp; maxOther = cp > fp ? cp : fp;
        case MacroType.carbs:   active = cp; maxOther = pp > fp ? pp : fp;
        case MacroType.fats:    active = fp; maxOther = pp > cp ? pp : cp;
        case MacroType.calories: break;
      }
      if (active >= 0.45 && (active - maxOther) >= 0.10) dom.add(i);
    }

    final e = <MapEntry<int, int>>[];
    for (int i = 0; i < foods.length; i++) {
      final v = _macroVal(foods[i], _activeMacro);
      if (v > 0) e.add(MapEntry(i, v));
    }
    e.sort((a, b) => b.value.compareTo(a.value));
    dom.addAll(e.take(2).map((x) => x.key));
    return dom;
  }

  Color get _dotColor {
    const c = {
      MacroType.protein: Color(0xFF22C55E),
      MacroType.carbs: Color(0xFFF59E0B),
      MacroType.fats: Color(0xFFEF4444),
      MacroType.calories: Color(0xFF94A3B8),
    };
    return c[_activeMacro]!;
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        bottom: false,
        child: _buildFullDayPage(_today),
      ),
    );
  }

  /// Full day page including header + macro card + food list
  Widget _buildFullDayPage(DateTime pageDate) {
    final isPageToday = _isSameDay(pageDate, _today);
    final isPageYesterday =
        _isSameDay(pageDate, _today.subtract(const Duration(days: 1)));

    String dateLabel;
    if (isPageToday) {
      dateLabel = 'TODAY';
    } else if (isPageYesterday) {
      dateLabel = 'YESTERDAY';
    } else {
      const m = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      dateLabel = '${pageDate.day} ${m[pageDate.month - 1]}';
    }

    return Container(
      color: const Color(0xFFF6F7F9),
      child: Column(
        children: [
          // ─ Header ─
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => AccountSheet.show(context),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateLabel,
                            style: TextStyle(
                              color: isPageToday
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hi ${FirebaseAuth.instance.currentUser?.displayName ?? 'User'}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ─ Content ─
          Expanded(
            child: StreamBuilder<List<LoggedFoodEntry>>(
              stream: _logService.streamDailyLogs(pageDate),
              builder: (context, snapshot) {
                final loggedFoods = snapshot.data ?? [];

                final totalCal = loggedFoods.fold<int>(
                    0, (s, e) => s + e.nutrition.calories.round());
                final totalPro = loggedFoods.fold<int>(
                    0, (s, e) => s + e.nutrition.protein.round());
                final totalCarb = loggedFoods.fold<int>(
                    0, (s, e) => s + e.nutrition.carbs.round());
                final totalFat = loggedFoods.fold<int>(
                    0, (s, e) => s + e.nutrition.fat.round());

                final topIdx = _getDominantFoodIndices(loggedFoods);
                final dot = _dotColor;

                return Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.only(top: 200, bottom: 120),
                      children: [
                        for (int i = 0; i < loggedFoods.length; i++)
                          GestureDetector(
                            onTap: () async {
                              final entry = loggedFoods[i];
                              final result = await FoodDetailSheet.show(
                                context,
                                food: entry.food,
                                nutrition: entry.nutrition,
                                createdAt: entry.createdAt,
                                thoughtProcess: entry.thoughtProcess,
                                sources: entry.sources,
                              );
                              if (result != null && entry.id != null) {
                                if (result.deleted) {
                                  await _logService.deleteLoggedFood(
                                      pageDate, entry.id!);
                                } else {
                                  await _logService.updateLoggedFood(
                                      pageDate,
                                      entry.copyWithNutrition(result.nutrition));
                                }
                              }
                            },
                            onLongPress: () {
                              final entry = loggedFoods[i];
                              _showDeleteConfirmation(context, entry, pageDate);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: FoodListItem(
                                title: loggedFoods[i].food.name,
                                calories: loggedFoods[i].nutrition.calories.round(),
                                protein: loggedFoods[i].nutrition.protein.round(),
                                carbs: loggedFoods[i].nutrition.carbs.round(),
                                fat: loggedFoods[i].nutrition.fat.round(),
                                dotColor: topIdx.contains(i) ? dot : null,
                              ),
                            ),
                          ),
                        if (isPageToday)
                          SmartFoodInput(
                            service: _foodService,
                            onFoodResolved: (f, n, name,
                                    {String? thoughtProcess,
                                    List<String>? sources}) =>
                                _onFoodAddedForDate(f, n, name, pageDate,
                                    thoughtProcess: thoughtProcess,
                                    sources: sources),
                            onCustomFood: (n) => _onCustomFoodForDate(n, pageDate),
                          ),
                      ],
                    ),
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: MacroCard(
                        protein: totalPro,
                        carbs: totalCarb,
                        fat: totalFat,
                        calories: totalCal,
                        goalProtein: _goalProtein,
                        goalCarbs: _goalCarbs,
                        goalFat: _goalFat,
                        goalCalories: _goalCalories,
                        activeMacro: _activeMacro,
                        onActiveMacroChanged: (m) =>
                            setState(() => _activeMacro = m),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, LoggedFoodEntry entry, DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Remove Food?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to remove ${entry.food.name} from your log?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Keep',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (entry.id != null) {
                            await _logService.deleteLoggedFood(date, entry.id!);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
