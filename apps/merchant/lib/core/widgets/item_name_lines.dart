import 'package:flutter/material.dart';

/// Renders an item's identity the way it should appear everywhere a name is
/// shown: an optional code prefix on the first line, and the optional second
/// (e.g. native-language) name stacked beneath. Both lines always show
/// together regardless of the app's UI language — they're user data.
class ItemNameLines extends StatelessWidget {
  final String? code;
  final String name;
  final String? nameSecondary;
  final TextStyle? style;

  const ItemNameLines({
    super.key,
    required this.name,
    this.code,
    this.nameSecondary,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.isNotEmpty;
    final hasSecondary = nameSecondary != null && nameSecondary!.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hasCode ? '$code  $name' : name, style: style),
        if (hasSecondary)
          Text(
            nameSecondary!,
            style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
