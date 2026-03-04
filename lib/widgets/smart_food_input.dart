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

  const SmartFoodInput({
    super.key,
    required this.onFoodResolved,
    required this.onCustomFood,
    required this.service,
  });

  @override
  State<SmartFoodInput> createState() => _SmartFoodInputState();
}

class _SmartFoodInputState extends State<SmartFoodInput>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  int _searchVersion = 0;

  bool _isSearching = false;
  bool _isResolving = false;
  Food? _topSuggestion;
  String _statusMessage = '';
  String _resolveStage = '';

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
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
      _resolveStage = 'Searching database...';
      _statusMessage = '';
      _topSuggestion = null;
    });

    // Create service with progress callback for stage updates
    final service = FoodService(
      onProgressUpdate: (stage) {
        if (mounted) setState(() => _resolveStage = stage);
      },
    );

    try {
      final resolved = await service.resolveFood(text);

      if (!mounted) return;

      // Clear input AFTER resolution
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
            decoration: const InputDecoration(
              hintText: 'Type food...',
              hintStyle: TextStyle(
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

  /// The resolving row: food name on left, animated search status on right
  Widget _buildResolvingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Food name (preserved)
          Expanded(
            child: Text(
              _controller.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Search animation on the right
          _SearchStatusBadge(stage: _resolveStage),
        ],
      ),
    );
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

/// Animated search status badge on the right side of the food row.
/// Shows spinner + stage label with source icons.
class _SearchStatusBadge extends StatefulWidget {
  final String stage;
  const _SearchStatusBadge({required this.stage});

  @override
  State<_SearchStatusBadge> createState() => _SearchStatusBadgeState();
}

class _SearchStatusBadgeState extends State<_SearchStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _isWeb =>
      widget.stage.toLowerCase().contains('ai') ||
      widget.stage.toLowerCase().contains('web');

  String get _label {
    if (_isWeb) return 'Searching the web...';
    return 'Searching database...';
  }

  IconData? get _icon {
    if (_isWeb) return Icons.travel_explore_rounded;
    return null;
  }

  Color get _color {
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final opacity = 0.5 + (_pulseCtrl.value * 0.5);
        return Opacity(
          opacity: opacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_icon != null) ...[
                Icon(_icon!, size: 14, color: _color),
                const SizedBox(width: 6),
              ],
              Text(
                _label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
