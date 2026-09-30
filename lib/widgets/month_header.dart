import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'page_title.dart';

class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.title,
    required this.strings,
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onToday,
    this.onNextMonth,
    this.trailing,
    this.subtitle,
    this.showMonthControls = true,
  });

  final String title;
  final AppStrings strings;
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback onToday;
  final Widget? trailing;
  final String? subtitle;

  /// When false, the ‹ month › stepper and "Heute" button are hidden and only
  /// [trailing] is shown alongside the title.
  final bool showMonthControls;

  @override
  Widget build(BuildContext context) {
    final titleBlock = PageTitle(title: title, subtitle: subtitle);

    if (isPhoneLayout(context)) {
      return _buildCompact(context, titleBlock);
    }

    final monthText = strings.monthAndYear(selectedMonth);

    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showMonthControls) ...[
          IconButton.outlined(
            visualDensity: VisualDensity.compact,
            tooltip: strings.previousMonth,
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          SizedBox(
            width: 128,
            child: Text(
              monthText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton.outlined(
            visualDensity: VisualDensity.compact,
            tooltip: strings.nextMonth,
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton.outlined(
            visualDensity: VisualDensity.compact,
            tooltip: strings.today,
            onPressed: onToday,
            icon: const Icon(Icons.today_outlined),
          ),
        ],
        ?trailing,
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [titleBlock, const SizedBox(height: 14), controls],
              );
            }

            return Row(
              children: [
                Expanded(child: titleBlock),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }

  /// Phone layout: small title, then one row with ‹ Month › (and Today) on
  /// the left and the page's actions on the right. If the actions don't fit
  /// next to the month they move onto their own row instead of overflowing.
  Widget _buildCompact(BuildContext context, Widget titleBlock) {
    // On the smallest phones the full month name would push the actions
    // onto a second row.
    final narrow = MediaQuery.sizeOf(context).width < 360;

    final monthGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: strings.previousMonth,
          onPressed: onPreviousMonth,
          icon: const Icon(Icons.chevron_left),
        ),
        // Shrinks with an ellipsis instead of overflowing, e.g. with a large
        // system text size.
        Flexible(
          child: Text(
            narrow
                ? strings.shortMonthAndYear(selectedMonth)
                : strings.monthAndYear(selectedMonth),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: strings.nextMonth,
          onPressed: onNextMonth,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: strings.today,
          onPressed: onToday,
          icon: const Icon(Icons.today_outlined),
        ),
      ],
    );

    final actions = trailing;

    // A phone held sideways has little height: one row — title, month and
    // actions — without the greeting. Anything that doesn't fit wraps.
    if (MediaQuery.sizeOf(context).height < 500) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 4),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              PageTitle(title: title),
              if (showMonthControls) monthGroup,
              ?actions,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            if (showMonthControls || actions != null) ...[
              const SizedBox(height: 8),
              // Full width, so spaceBetween can push the actions to the right.
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Pull the first chevron flush with the title's left edge.
                    if (showMonthControls)
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: monthGroup,
                      ),
                    ?actions,
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
