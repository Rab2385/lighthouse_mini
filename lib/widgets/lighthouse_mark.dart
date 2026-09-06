import 'package:flutter/material.dart';

/// The Lighthouse mark, tinted to the current theme.
///
/// The source asset is a single-colour line drawing on a transparent
/// background, tightly cropped, so a plain [BoxFit.contain] fills the box and
/// [BlendMode.srcIn] recolours it to match the wordmark.
class LighthouseMark extends StatelessWidget {
  const LighthouseMark({
    super.key,
    required this.height,
    this.color,
  });

  /// Rendered height in logical pixels. Width follows the mark's aspect ratio.
  final double height;

  /// Tint for the mark. Defaults to the theme's primary colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: height,
      child: Image.asset(
        'assets/images/lighthouse_mark.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        color: tint,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.light_mode_outlined,
            size: height,
            color: tint,
          );
        },
      ),
    );
  }
}
