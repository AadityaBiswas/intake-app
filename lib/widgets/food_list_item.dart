import 'package:flutter/material.dart';

class FoodListItem extends StatefulWidget {
  final String title;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final Color? dotColor;
  final String? foodSource;
  final List<String>? sources;
  final DateTime? createdAt;
  final bool isNew;

  const FoodListItem({
    super.key,
    required this.title,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.dotColor,
    this.foodSource,
    this.sources,
    this.createdAt,
    this.isNew = false,
  });

  @override
  State<FoodListItem> createState() => _FoodListItemState();
}

class _FoodListItemState extends State<FoodListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _showAnimation = false;

  static const _greenColor = Color(0xFF22C55E);
  static const _grayColor = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Scale: 1.0 → 1.18 (first 35%) → 1.0 (remaining 65%)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 65,
      ),
    ]).animate(_controller);

    // Color: stay green for 30%, then fade green → gray
    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(tween: ConstantTween<Color?>(_greenColor), weight: 30),
      TweenSequenceItem(
        tween: ColorTween(
          begin: _greenColor,
          end: _grayColor,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Determine if we should animate
    if (widget.isNew) {
      _showAnimation = true;
      _controller.addStatusListener(_onAnimComplete);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  void _onAnimComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _showAnimation = false);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimComplete);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          _showAnimation ? _buildAnimatedCalories() : _buildNormalCalories(),
        ],
      ),
    );
  }

  Widget _buildNormalCalories() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.dotColor != null)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: widget.dotColor,
              shape: BoxShape.circle,
            ),
          ),
        Text(
          '${widget.calories} cal',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _grayColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCalories() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.centerRight,
          child: Text(
            '${widget.calories} cal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _colorAnimation.value ?? _greenColor,
            ),
          ),
        );
      },
    );
  }
}
