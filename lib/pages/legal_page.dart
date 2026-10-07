import 'package:flutter/material.dart';

import '../legal/legal_texts.dart';

/// Shows the privacy policy or the legal notice. Reachable offline from
/// Settings, as Apple asks for the policy to be available inside the app.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.document});

  final LegalDocument document;

  static Future<void> open(BuildContext context, LegalDocument document) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LegalPage(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.lastUpdated,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (document.summary.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document.summaryTitle ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final line in document.summary)
                              _Bullet(text: line),
                          ],
                        ),
                      ),
                    ],
                    for (final section in document.sections) ...[
                      const SizedBox(height: 24),
                      Text(
                        section.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (var i = 0; i < section.paragraphs.length; i++) ...[
                        _Paragraph(text: section.paragraphs[i]),
                        if (i == 0)
                          for (final bullet in section.bullets)
                            _Bullet(text: bullet),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(children: _withPlaceholders(context, text)),
        style: const TextStyle(height: 1.5),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('·  ', style: TextStyle(height: 1.5)),
          Expanded(child: _Paragraph(text: text)),
        ],
      ),
    );
  }
}

/// Splits [text] so "[Platzhalter]" stand out until they are filled in.
List<InlineSpan> _withPlaceholders(BuildContext context, String text) {
  final highlight = Theme.of(context).colorScheme.tertiaryContainer;
  final spans = <InlineSpan>[];
  var start = 0;

  for (final match in RegExp(r'\[[^\]]+\]').allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(0),
        style: TextStyle(backgroundColor: highlight),
      ),
    );
    start = match.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }
  return spans;
}
