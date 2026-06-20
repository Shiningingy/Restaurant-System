import 'package:flutter/material.dart';

/// An item's name with its optional second-language name stacked beneath it
/// (e.g. an English name over its 中文 name). The merchant publishes both;
/// showing them together is what makes a bilingual menu readable to either
/// customer regardless of the app's language setting.
class ItemName extends StatelessWidget {
  final String name;
  final String? nameSecondary;
  final TextStyle? style;

  const ItemName({
    super.key,
    required this.name,
    this.nameSecondary,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final second = nameSecondary?.trim();
    if (second == null || second.isEmpty) {
      return Text(name, style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: style),
        Text(
          second,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
