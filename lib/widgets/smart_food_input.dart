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
/// - Queued search: user can enter multiple foods while previous ones resolve
class SmartFoodInput extends StatefulWidget {
  final Function(
    Food food,
    ScaledNutrition nutrition,
    String userTypedName, {
    String? thoughtProcess,
    List<String>? sources,
  })
  onFoodResolved;

  final Function(String customName) onCustomFood;
  final FoodService service;
  final int foodCount;
  final FocusNode? externalFocusNode;
  final String? location;

  const SmartFoodInput({
    super.key,
    required this.onFoodResolved,
    required this.onCustomFood,
    required this.service,
    this.foodCount = 0,
    this.externalFocusNode,
    this.location,
  });

  @override
  State<SmartFoodInput> createState() => _SmartFoodInputState();
}

/// Represents a single food query in the search queue.
class _PendingSearch {
  final String query;
  String status = 'Queued...';

  _PendingSearch({required this.query});
}

class _SmartFoodInputState extends State<SmartFoodInput>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  late final FoodService _resolveService;

  bool _keyboardVisible = false;

  // ── Queue state ──
  final List<_PendingSearch> _searchQueue = [];
  bool _isQueueProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = widget.externalFocusNode ?? FocusNode();
    _resolveService = FoodService(
      onProgressUpdate: (stage) {
        if (mounted && _searchQueue.isNotEmpty) {
          setState(() => _searchQueue.first.status = stage);
        }
      },
    );
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    final isNowVisible = bottomInset > 0;
    if (_keyboardVisible && !isNowVisible) {
      if (_controller.text.trim().isEmpty && _focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
    _keyboardVisible = isNowVisible;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    if (widget.externalFocusNode == null) _focusNode.dispose();
    super.dispose();
  }

  // ─── Queue-based submit & processing ───────────────────────────────

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Clear the input immediately so user can type the next food
    _controller.clear();

    setState(() {
      _searchQueue.add(_PendingSearch(query: text));
    });

    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isQueueProcessing) return;
    _isQueueProcessing = true;

    while (_searchQueue.isNotEmpty) {
      final item = _searchQueue.first;

      if (mounted) {
        setState(() => item.status = 'Searching database...');
      }

      try {
        final resolved = await _resolveService.resolveFood(
          item.query,
          location: widget.location,
        );

        if (!mounted) return;

        if (resolved != null) {
          HapticFeedback.mediumImpact();

          widget.onFoodResolved(
            resolved.food,
            resolved.nutrition,
            resolved.userTypedName,
            thoughtProcess: resolved.thoughtProcess,
            sources: resolved.sources,
          );
        } else {
          widget.onCustomFood(item.query);
        }
      } catch (e) {
        debugPrint('Food resolution error: $e');
        if (mounted) {
          widget.onCustomFood(item.query);
        }
      }

      if (!mounted) return;
      setState(() {
        _searchQueue.remove(item);
      });
    }

    _isQueueProcessing = false;
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Actively resolving / queued items rendered ABOVE the text field
          for (final item in _searchQueue)
            _buildQueueRow(item),

          // The always-visible text input
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.foodCount == 0 && _searchQueue.isEmpty
                  ? 'Type food...'
                  : null,
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
        ],
      ),
    );
  }

  /// A single row for a queued or actively-resolving item.
  Widget _buildQueueRow(_PendingSearch item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Food name (same style as input)
          Expanded(
            child: Text(
              item.query,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Right side: animated status
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildItemRightStatus(item),
          ),
        ],
      ),
    );
  }

  /// Returns the correct right-side widget for a queue item.
  Widget _buildItemRightStatus(_PendingSearch item) {
    // Queued (not yet started)
    if (item.status == 'Queued...') {
      return const _PulsingText(
        key: ValueKey('queued'),
        text: 'Queued...',
      );
    }

    // Actively searching
    final isWeb =
        item.status.toLowerCase().contains('ai') ||
        item.status.toLowerCase().contains('web');
    final label = isWeb ? 'Searching the web' : 'Searching';

    return _PulsingText(key: ValueKey(label), text: label);
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
      opacity: Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
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
