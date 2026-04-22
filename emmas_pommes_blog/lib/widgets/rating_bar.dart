import 'package:flutter/material.dart';
import '../config/theme.dart';

class RatingBar extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final bool readOnly;

  const RatingBar({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            return GestureDetector(
              onTap: readOnly ? null : () => onChanged?.call(starValue),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  starValue <= value ? Icons.star : Icons.star_border,
                  color: PommesTheme.pommesYellow,
                  size: readOnly ? 20 : 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final double? rating;
  final double size;

  const RatingDisplay({super.key, this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    if (rating == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: PommesTheme.pommesYellow, size: size),
        const SizedBox(width: 4),
        Text(
          rating!.toStringAsFixed(1),
          style: TextStyle(
            color: PommesTheme.pommesYellow,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.9,
          ),
        ),
      ],
    );
  }
}
