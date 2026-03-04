import 'package:flutter/material.dart';

class FoodListItem extends StatelessWidget {
  final String title;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final Color? dotColor;

  const FoodListItem({
    super.key,
    required this.title,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          Row(
            children: [
              if (dotColor != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: calories),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Text(
                    '$value cal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
