import 'package:flutter/material.dart';

class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.title,
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onToday,
    this.onNextMonth,
    this.trailing,
    this.subtitle,
    this.showMonthControls = true,
  });

  final String title;
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback onToday;
  final Widget? trailing;
  final String? subtitle;

  /// When false, the ‹ month › stepper and "Heute" button are hidden and only
  /// [trailing] is shown alongside the title.
  final bool showMonthControls;

  static const List<String> _monthNames = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  @override
  Widget build(BuildContext context) {
    final monthText =
        '${_monthNames[selectedMonth.month - 1]} '
        '${selectedMonth.year}';

    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showMonthControls) ...[
          IconButton.outlined(
            tooltip: 'Vorheriger Monat',
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          SizedBox(
            width: 150,
            child: Text(
              monthText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Nächster Monat',
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
          OutlinedButton(onPressed: onToday, child: const Text('Heute')),
        ],
        ?trailing,
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleBlock, const SizedBox(height: 16), controls],
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
    );
  }
}
