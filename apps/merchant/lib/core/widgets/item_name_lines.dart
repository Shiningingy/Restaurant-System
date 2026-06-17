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

  /// Whether to render the second name line (when present). The merchant can
  /// turn this off for the order screen in Settings; the menu-management list
  /// always passes true.
  final bool showSecondary;

  const ItemNameLines({
    super.key,
    required this.name,
    this.code,
    this.nameSecondary,
    this.style,
    this.showSecondary = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.isNotEmpty;
    final hasSecondary =
        showSecondary && nameSecondary != null && nameSecondary!.isNotEmpty;
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
