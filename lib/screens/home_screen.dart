import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import '../services/location_service.dart';
import '../services/food_cache_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FoodService _foodService = FoodService();
  final LogService _logService = LogService();
  final LocationService _locationService = LocationService();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _newFoodIds = {};
  final Set<String> _recalculatingIds = {};
  final GlobalKey _smartInputKey = GlobalKey();

  String? _cachedLocation;

  late DateTime _today;
  StreamSubscription<DocumentSnapshot>? _goalsSubscription;

  MacroType _activeMacro = MacroType.protein;
  bool _macroSelectedByUser = false;
  bool _cardCollapsed = false;
  ScrollDirection _scrollUserDirection = ScrollDirection.idle;
  int _cardResetKey = 0;

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
    _inputFocusNode.addListener(_onInputFocus);
    _initLocation();
    FoodCacheService().preWarm();
  }

  Future<void> _initLocation() async {
    await _locationService.requestPermissionAndFetchLocation();
    final location = await _locationService.getEffectiveLocation();
    if (mounted) {
      setState(() {
        _cachedLocation = location;
      });
    }
  }

  void _onInputFocus() {
    if (!_inputFocusNode.hasFocus) return;
    // Always collapse and reset the macro card when food input is focused
    setState(() {
      _cardResetKey++;
      _macroSelectedByUser = false;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 10) {
        _cardCollapsed = true;
      }
    });
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is UserScrollNotification) {
      _scrollUserDirection = n.direction;

      if (n.direction == ScrollDirection.reverse) {
        final maxExtent = _scrollController.hasClients
            ? _scrollController.position.maxScrollExtent
            : 0.0;
        if (maxExtent > 40) {
          if (!_cardCollapsed) {
            setState(() {
              _cardCollapsed = true;
              _cardResetKey++;
            });
          } else {
            setState(() => _cardResetKey++);
          }
        }
      }
    } else if (n is ScrollUpdateNotification && n.dragDetails != null) {
      if (_cardCollapsed &&
          _scrollUserDirection == ScrollDirection.forward &&
          _scrollController.hasClients &&
          _scrollController.offset < 30) {
        setState(() => _cardCollapsed = false);
      }
    } else if (n is ScrollEndNotification) {
      _scrollUserDirection = ScrollDirection.idle;
    }
    return false;
  }

  void _listenToGoals() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _goalsSubscription = FirebaseFirestore.instance
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
    _scrollController.dispose();
    _goalsSubscription?.cancel();
    _inputFocusNode.removeListener(_onInputFocus);
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ─── Date helpers ────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ─── Food helpers ─────────────────────────────────────────────────

  Future<void> _onFoodAddedForDate(
    Food food,
    ScaledNutrition nutrition,
    String userTypedName,
    DateTime date, {
    String? thoughtProcess,
    List<String>? sources,
  }) async {
    final namedFood = food.copyWith(name: userTypedName);
    final entry = LoggedFoodEntry(
      food: namedFood,
      nutrition: nutrition,
      thoughtProcess: thoughtProcess,
      sources: sources,
    );
    final docId = await _logService.logFood(date, entry);
    _newFoodIds.add(docId);
    if (mounted) setState(() {});
    Future.delayed(const Duration(seconds: 5), () {
      _newFoodIds.remove(docId);
      if (mounted) setState(() {});
    });
  }

  Future<void> _onCustomFoodForDate(String name, DateTime date) async {
    final placeholder = Food(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      nameLowercase: name.toLowerCase(),
      searchKeywords: name.toLowerCase().split(' '),
      nutritionPer100g: const NutritionPer100g(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      ),
    );
    final zeroNutrition = const ScaledNutrition(
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      gramsUsed: 100,
    );
    final entry = LoggedFoodEntry(food: placeholder, nutrition: zeroNutrition);
    final docId = await _logService.logFood(date, entry);
    _newFoodIds.add(docId);
    if (mounted) setState(() {});
    Future.delayed(const Duration(seconds: 5), () {
      _newFoodIds.remove(docId);
      if (mounted) setState(() {});
    });
  }

  int _macroVal(LoggedFoodEntry e, MacroType t) {
    switch (t) {
      case MacroType.protein:
        return e.nutrition.protein.round();
      case MacroType.carbs:
        return e.nutrition.carbs.round();
      case MacroType.fats:
        return e.nutrition.fat.round();
      case MacroType.calories:
        return e.nutrition.calories.round();
    }
  }

  Set<int> _getDominantFoodIndices(List<LoggedFoodEntry> foods) {
    if (foods.isEmpty || _cardCollapsed || !_macroSelectedByUser) return {};
    final dom = <int>{};
    final maxDots = foods.length <= 3 ? 1 : (foods.length / 3).ceil();

    // Ratio-based dominance
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
        case MacroType.protein:
          active = pp;
          maxOther = cp > fp ? cp : fp;
        case MacroType.carbs:
          active = cp;
          maxOther = pp > fp ? pp : fp;
        case MacroType.fats:
          active = fp;
          maxOther = pp > cp ? pp : cp;
        case MacroType.calories:
          break;
      }
      if (active >= 0.45 && (active - maxOther) >= 0.10) dom.add(i);
    }

    // Always include the top-value food(s) up to maxDots
    final e = <MapEntry<int, int>>[];
    for (int i = 0; i < foods.length; i++) {
      final v = _macroVal(foods[i], _activeMacro);
      if (v > 0) e.add(MapEntry(i, v));
    }
    e.sort((a, b) => b.value.compareTo(a.value));
    dom.addAll(e.take(maxDots).map((x) => x.key));

    // Cap total dots to maxDots
    if (dom.length > maxDots) {
      final sorted = e.map((x) => x.key).toList();
      return sorted.take(maxDots).toSet();
    }
    return dom;
  }

  Color get _dotColor {
    const c = {
      MacroType.protein: Color(0xFF22C55E),
      MacroType.carbs: Color(0xFF3B82F6),
      MacroType.fats: Color(0xFFF59E0B),
      MacroType.calories: Color(0xFF94A3B8),
    };
    return c[_activeMacro]!;
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(bottom: false, child: _buildFullDayPage(_today)),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _todayLabel() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildFullDayPage(DateTime pageDate) {
    final isPageToday = _isSameDay(pageDate, _today);
    final user = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName ?? '').split(' ').first;

    return Container(
      color: const Color(0xFFF6F7F9),
      child: Column(
        children: [
          // ─ Header ─
          if (!isPageToday)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${pageDate.day} ${const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][pageDate.month - 1]}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _todayLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB0BAC6),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            AccountSheet.show(context);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            firstName.isNotEmpty
                                ? '${_greeting()}, $firstName'
                                : _greeting(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D1117),
                              letterSpacing: -0.7,
                              height: 1.15,
                            ),
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
                  0,
                  (s, e) => s + e.nutrition.calories.round(),
                );
                final totalPro = loggedFoods.fold<int>(
                  0,
                  (s, e) => s + e.nutrition.protein.round(),
                );
                final totalCarb = loggedFoods.fold<int>(
                  0,
                  (s, e) => s + e.nutrition.carbs.round(),
                );
                final totalFat = loggedFoods.fold<int>(
                  0,
                  (s, e) => s + e.nutrition.fat.round(),
                );

                final topIdx = _getDominantFoodIndices(loggedFoods);
                final dot = _dotColor;

                return Column(
                  children: [
                    MacroCard(
                      protein: totalPro,
                      carbs: totalCarb,
                      fat: totalFat,
                      calories: totalCal,
                      goalProtein: _goalProtein,
                      goalCarbs: _goalCarbs,
                      goalFat: _goalFat,
                      goalCalories: _goalCalories,
                      activeMacro: _activeMacro,
                      onActiveMacroChanged: (m) => setState(() {
                        _activeMacro = m;
                        _macroSelectedByUser = true;
                      }),
                      isCollapsed: _cardCollapsed,
                      expansionResetKey: _cardResetKey,
                    ),
                    // ─ Food list ─
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: GestureDetector(
                          onTap: () {
                            if (isPageToday) {
                              if (_inputFocusNode.hasFocus) {
                                // If already focused and blinking, second tap opens keyboard
                                SystemChannels.textInput.invokeMethod(
                                  'TextInput.show',
                                );
                              } else {
                                // First tap: focus (blinking cursor) but hide keyboard
                                _inputFocusNode.requestFocus();
                                Future.delayed(
                                  const Duration(milliseconds: 50),
                                  () {
                                    SystemChannels.textInput.invokeMethod(
                                      'TextInput.hide',
                                    );
                                  },
                                );
                              }
                            }
                          },
                          behavior: HitTestBehavior.translucent,
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 120),
                            children: [
                              for (int i = 0; i < loggedFoods.length; i++)
                                GestureDetector(
                                  onTap: () async {
                                    final entry = loggedFoods[i];
                                    // Block opening sheet while recalculating
                                    if (entry.id != null &&
                                        _recalculatingIds.contains(entry.id)) {
                                      return;
                                    }
                                    final result = await FoodDetailSheet.show(
                                      context,
                                      food: entry.food,
                                      nutrition: entry.nutrition,
                                      createdAt: entry.createdAt,
                                      thoughtProcess: entry.thoughtProcess,
                                      location: _cachedLocation,
                                    );
                                    if (result != null && entry.id != null) {
                                      if (result.deleted) {
                                        await _logService.deleteLoggedFood(
                                          pageDate,
                                          entry.id!,
                                        );
                                      } else {
                                        await _logService.updateLoggedFood(
                                          pageDate,
                                          entry.copyWithNutrition(
                                            result.nutrition,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  onLongPress: () {
                                    HapticFeedback.mediumImpact();
                                    final entry = loggedFoods[i];
                                    _showDeleteConfirmation(
                                      context,
                                      entry,
                                      pageDate,
                                    );
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    child: FoodListItem(
                                      key: ValueKey(
                                        loggedFoods[i].id ?? 'food_$i',
                                      ),
                                      title: loggedFoods[i].food.name,
                                      calories: loggedFoods[i]
                                          .nutrition
                                          .calories
                                          .round(),
                                      protein: loggedFoods[i].nutrition.protein
                                          .round(),
                                      carbs: loggedFoods[i].nutrition.carbs
                                          .round(),
                                      fat: loggedFoods[i].nutrition.fat.round(),
                                      dotColor: topIdx.contains(i) ? dot : null,
                                      foodSource: loggedFoods[i].food.source,
                                      sources: loggedFoods[i].sources,
                                      createdAt: loggedFoods[i].createdAt,
                                      isNew:
                                          loggedFoods[i].id != null &&
                                          _newFoodIds.contains(
                                            loggedFoods[i].id,
                                          ),
                                      isRecalculating:
                                          loggedFoods[i].id != null &&
                                          _recalculatingIds.contains(
                                            loggedFoods[i].id,
                                          ),
                                    ),
                                  ),
                                ),
                              if (isPageToday)
                                SmartFoodInput(
                                  key: _smartInputKey,
                                  service: _foodService,
                                  foodCount: loggedFoods.length,
                                  externalFocusNode: _inputFocusNode,
                                  onFoodResolved:
                                      (
                                        f,
                                        n,
                                        name, {
                                        String? thoughtProcess,
                                        List<String>? sources,
                                      }) => _onFoodAddedForDate(
                                        f,
                                        n,
                                        name,
                                        pageDate,
                                        thoughtProcess: thoughtProcess,
                                        sources: sources,
                                      ),
                                  onCustomFood: (n) =>
                                      _onCustomFoodForDate(n, pageDate),
                                  location: _cachedLocation,
                                ),
                            ],
                          ),
                        ),
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

  void _showDeleteConfirmation(
    BuildContext context,
    LoggedFoodEntry entry,
    DateTime date,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 40,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0x80CBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Red icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Remove Food?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Remove ${entry.food.name} from your log?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFEEF2F7),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Keep',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                            if (entry.id != null) {
                              await _logService.deleteLoggedFood(
                                date,
                                entry.id!,
                              );
                            }
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
