import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food.dart';
import '../models/scaled_nutrition.dart';
import '../services/food_service.dart';

/// Smart food input widget with:
/// - Debounced suggestions while typing (Firestore-only, read-only)
/// - Full resolution pipeline on Enter (Firestore → USDA → AI)
/// - Search animation on the RIGHT side (where calories appear)
/// - Dynamic status: "Searching database..." or "Searching the web..."
/// - Text preserved during resolution
class SmartFoodInput extends StatefulWidget {
  final Function(Food food, ScaledNutrition nutrition, String userTypedName,
      {String? thoughtProcess, List<String>? sources}) onFoodResolved;

  final Function(String customName) onCustomFood;
  final FoodService service;
  final int foodCount;
  final FocusNode? externalFocusNode;

  const SmartFoodInput({
    super.key,
    required this.onFoodResolved,
    required this.onCustomFood,
    required this.service,
    this.foodCount = 0,
    this.externalFocusNode,
  });

  @override
  State<SmartFoodInput> createState() => _SmartFoodInputState();
}

class _SmartFoodInputState extends State<SmartFoodInput>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  late final FoodService _resolveService;

  Timer? _debounceTimer;
  int _searchVersion = 0;

  bool _isSearching = false;
  bool _isResolving = false;
  bool _showingSources = false;
  Food? _topSuggestion;
  String _statusMessage = '';
  String _resolveStage = '';
  List<String> _resolvedSources = [];
  String _resolvedFoodName = '';
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = widget.externalFocusNode ?? FocusNode();
    _resolveService = FoodService(
      onProgressUpdate: (stage) {
        if (mounted) setState(() => _resolveStage = stage);
      },
    );
    _controller.addListener(_onTextChanged);
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          if (_topSuggestion != null) {
            _acceptSuggestion();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void didChangeMetrics() {
    // Detect keyboard show/hide
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final isNowVisible = bottomInset > 0;
    if (_keyboardVisible && !isNowVisible) {
      // Keyboard just closed — unfocus if text is empty
      if (_controller.text.trim().isEmpty && _focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
    _keyboardVisible = isNowVisible;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    // Only dispose if we created it ourselves
    if (widget.externalFocusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    _searchVersion++;

    setState(() {
      _topSuggestion = null;
      _statusMessage = '';
    });

    _debounceTimer?.cancel();

    if (text.trim().isEmpty) {
      if (_isSearching) setState(() => _isSearching = false);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSuggestionSearch(text);
    });
  }

  Future<void> _performSuggestionSearch(String query) async {
    final version = _searchVersion;
    setState(() => _isSearching = true);

    try {
      final results = await widget.service.suggestFoods(query);
      if (!mounted || _searchVersion != version) return;
      setState(() {
        _topSuggestion = results.isNotEmpty ? results.first : null;
        _isSearching = false;
      });
    } catch (e) {
      if (mounted && _searchVersion == version) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _acceptSuggestion() {
    if (_topSuggestion != null) {
      final newText = _topSuggestion!.name;
      _controller.removeListener(_onTextChanged);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      setState(() => _topSuggestion = null);
      _controller.addListener(_onTextChanged);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isResolving = true;
      _showingSources = false;
      _resolveStage = 'Searching database...';
      _statusMessage = '';
      _topSuggestion = null;
      _resolvedFoodName = text;
    });

    try {
      final resolved = await _resolveService.resolveFood(text);

      if (!mounted) return;

      // If AI resolved with sources, show them for 1.5s before adding
      if (resolved != null &&
          resolved.sources != null &&
          resolved.sources!.isNotEmpty) {
        setState(() {
          _showingSources = true;
          _resolvedSources = resolved.sources!;
        });
        await Future.delayed(const Duration(milliseconds: 2500));
        if (!mounted) return;
      }

      // Clear input AFTER displaying sources
      _controller.removeListener(_onTextChanged);
      _controller.clear();
      _controller.addListener(_onTextChanged);

      if (resolved != null) {
        widget.onFoodResolved(
          resolved.food,
          resolved.nutrition,
          resolved.userTypedName,
          thoughtProcess: resolved.thoughtProcess,
          sources: resolved.sources,
        );
      } else {
        widget.onCustomFood(text);
      }
    } catch (e) {
      if (mounted) {
        _controller.removeListener(_onTextChanged);
        _controller.clear();
        _controller.addListener(_onTextChanged);
        widget.onCustomFood(text);
      }
    }

    if (!mounted) return;
    setState(() {
      _topSuggestion = null;
      _statusMessage = '';
      _isResolving = false;
      _showingSources = false;
      _resolvedSources = [];
      _resolvedFoodName = '';
      _resolveStage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // When resolving, show the food name on left + search animation on right
    if (_isResolving) {
      return _buildResolvingRow();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.foodCount >= 2 ? null : 'Type food...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: const Color(0xFF22C55E),
          ),

          // Search/suggestion status below text field
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildBelowStatus(),
          ),
        ],
      ),
    );
  }

  /// The resolving row: food name on left, animated status on right
  Widget _buildResolvingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Food name (preserved — same style as input field)
          Expanded(
            child: Text(
              _resolvedFoodName.isNotEmpty ? _resolvedFoodName : _controller.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Right side: single AnimatedSwitcher for all 3 states
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _buildRightStatus(),
          ),
        ],
      ),
    );
  }

  /// Returns the correct right-side widget with a unique key for AnimatedSwitcher
  Widget _buildRightStatus() {
    // State 3: showing sources (after search completes)
    if (_showingSources && _resolvedSources.isNotEmpty) {
      return _buildSourcesBadge();
    }

    // State 1 & 2: searching
    final isWeb = _resolveStage.toLowerCase().contains('ai') ||
        _resolveStage.toLowerCase().contains('web');
    final label = isWeb ? 'Searching the web' : 'Searching';

    return _PulsingText(
      key: ValueKey(label),
      text: label,
    );
  }

  /// Stacked source favicon icons + "N+ sources" text
  Widget _buildSourcesBadge() {
    final count = _resolvedSources.length;
    final favicons = _resolvedSources.take(3).map(_getFaviconUrl).toList();
    return Row(
      key: const ValueKey('sources_badge'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stacked favicon icons
        SizedBox(
          width: 22.0 + ((favicons.length - 1).clamp(0, 2) * 12.0),
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < favicons.length; i++)
                Positioned(
                  left: i * 12.0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: ClipOval(
                        child: Image.network(
                          favicons[i],
                          width: 14,
                          height: 14,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, st) => const Icon(
                            Icons.language_rounded,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count+ sources',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  String _getFaviconUrl(String source) {
    String domain = source.toLowerCase();
    if (domain.contains('usda') || domain.contains('fooddata')) {
      domain = 'fdc.nal.usda.gov';
    } else if (domain.contains('calorieking')) {
      domain = 'calorieking.com';
    } else if (domain.contains('myfitnesspal')) {
      domain = 'myfitnesspal.com';
    } else if (domain.contains('fatsecret')) {
      domain = 'fatsecret.com';
    } else if (domain.contains('nin') || domain.contains('indian food composition')) {
      domain = 'nin.res.in';
    } else {
      final match = RegExp(r'[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').firstMatch(domain);
      domain = match != null ? match.group(0)! : 'example.com';
    }
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
  }

  Widget _buildBelowStatus() {
    // Searching indicator
    if (_isSearching) {
      return const Padding(
        key: ValueKey('searching'),
        padding: EdgeInsets.only(top: 4),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF94A3B8),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Searching...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Top suggestion hint
    if (_topSuggestion != null) {
      return _buildHintRow();
    }

    // Status message
    if (_statusMessage.isNotEmpty) {
      return Padding(
        key: ValueKey(_statusMessage),
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          _statusMessage,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _buildHintRow() {
    return GestureDetector(
      key: ValueKey('hint_${_topSuggestion!.name}'),
      onTap: _acceptSuggestion,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right,
                size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _topSuggestion!.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TAB',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple pulsing text widget — fades between 0.4 and 1.0 opacity.
class _PulsingText extends StatefulWidget {
  final String text;
  const _PulsingText({super.key, required this.text});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
