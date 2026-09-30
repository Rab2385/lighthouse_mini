import 'package:flutter/material.dart';

import 'lighthouse_mark.dart';

/// Whether the phone layout applies: compact headers, no AppBar. Based on the
/// shortest side so a phone stays a phone when held sideways.
bool isPhoneLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).shortestSide < 600;
}

/// The title block at the top of every tab.
///
/// On a phone the app has no AppBar, so the title carries the small lighthouse
/// mark and uses a smaller type size to leave the screen to the content.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = isPhoneLayout(context);

    final titleStyle =
        (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineMedium)
            ?.copyWith(fontWeight: FontWeight.w700);

    final subtitleText = subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact)
          // Only as wide as its content, so it can share a row with the
          // month controls when a phone is held sideways.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LighthouseMark(height: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: titleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        else
          Text(title, style: titleStyle),
        if (subtitleText != null) ...[
          SizedBox(height: compact ? 2 : 4),
          Text(
            subtitleText,
            style: TextStyle(
              fontSize: compact ? 13 : null,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
