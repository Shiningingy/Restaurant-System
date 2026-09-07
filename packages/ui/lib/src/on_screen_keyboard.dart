import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Wraps the whole app so a docked on-screen keyboard appears whenever a text
/// field is focused and [enabled] is true. Built for touch-only terminals with
/// no physical keyboard (a Windows POS won't raise the OS soft keyboard).
///
/// It routes taps into the currently focused field (numbers get a numpad, text
/// gets a QWERTY), and reserves space at the bottom — via an overridden
/// [MediaQuery] `viewInsets` — exactly like the system soft keyboard, so the
/// focused field and any dialog stay visible above it.
///
/// Mount it in `MaterialApp.builder` so it also sits above dialogs (the PIN
/// prompt, the payment sheet). It touches no individual field: it finds the
/// focused [EditableTextState] by walking from the primary focus, so every
/// current and future text field is covered for free.
class OnScreenKeyboardScope extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const OnScreenKeyboardScope({
    super.key,
    required this.child,
    required this.enabled,
  });

  @override
  State<OnScreenKeyboardScope> createState() => _OnScreenKeyboardScopeState();
}

class _OnScreenKeyboardScopeState extends State<OnScreenKeyboardScope> {
  static const double _height = 336;

  bool _show = false;
  bool _numeric = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant OnScreenKeyboardScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _onFocusChange();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    super.dispose();
  }

  /// The editable the primary focus currently sits in, or null. Checks the
  /// focus node's own context, its descendants, and its ancestors, so it works
  /// regardless of exactly where the focus node is attached inside the field.
  EditableTextState? _focusedEditable() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return null;
    EditableTextState? result;
    void visit(Element element) {
      if (result != null) return;
      if (element is StatefulElement && element.state is EditableTextState) {
        result = element.state as EditableTextState;
        return;
      }
      element.visitChildren(visit);
    }

    visit(context as Element);
    result ??= context.findAncestorStateOfType<EditableTextState>();
    return result;
  }

  static bool _isNumeric(TextInputType? type) {
    if (type == null) return false;
    // number / numberWithOptions share the "number" index; phone is numeric too.
    return type.index == TextInputType.number.index ||
        type.index == TextInputType.phone.index;
  }

  void _onFocusChange() {
    final editable = widget.enabled ? _focusedEditable() : null;
    final show = editable != null && !editable.widget.readOnly;
    final numeric = show && _isNumeric(editable.widget.keyboardType);
    if (show == _show && numeric == _numeric) return;

    void apply() {
      if (!mounted) return;
      setState(() {
        _show = show;
        _numeric = numeric;
      });
    }

    // Focus can change mid-frame; never setState during the build phase.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  // ── Input actions, applied to the focused editable ──

  EditableTextState? _target() => _focusedEditable();

  void _insert(String text) {
    final editable = _target();
    if (editable == null) return;
    final value = editable.textEditingValue;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final newText = value.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    editable.userUpdateTextEditingValue(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _backspace() {
    final editable = _target();
    if (editable == null) return;
    final value = editable.textEditingValue;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    if (selection.start == selection.end) {
      if (selection.start == 0) return;
      final newText = value.text.replaceRange(
        selection.start - 1,
        selection.start,
        '',
      );
      editable.userUpdateTextEditingValue(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start - 1),
        ),
        SelectionChangedCause.keyboard,
      );
    } else {
      final newText = value.text.replaceRange(
        selection.start,
        selection.end,
        '',
      );
      editable.userUpdateTextEditingValue(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start),
        ),
        SelectionChangedCause.keyboard,
      );
    }
  }

  void _done() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final show = widget.enabled && _show;
    return Stack(
      children: [
        MediaQuery(
          data: show
              ? media.copyWith(
                  viewInsets: media.viewInsets.copyWith(
                    bottom: media.viewInsets.bottom + _height,
                  ),
                )
              : media,
          // Tapping "nothing" dismisses the keyboard, the way a system soft
          // keyboard behaves. Without this the field keeps focus forever and the
          // panel sits there covering a third of a touch-only terminal.
          //
          // translucent + a tap gesture is deliberate: hit testing runs
          // innermost-first, so any child that handles its own taps (a button,
          // another text field) is added to the gesture arena first and wins.
          // This only fires when the tap landed on genuinely empty space.
          // Drags and scrolls are unaffected — onTap never claims those.
          child: show
              ? GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: widget.child,
                )
              : widget.child,
        ),
        if (show)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _height,
            // TextFieldTapRegion: taps on the keyboard count as "inside" the
            // field, so the field's tap-outside handler doesn't unfocus it.
            // ExcludeFocus: keys never steal focus from the field being typed.
            child: TextFieldTapRegion(
              child: ExcludeFocus(
                child: _Keyboard(
                  numeric: _numeric,
                  onKey: _insert,
                  onBackspace: _backspace,
                  onDone: _done,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The docked keyboard panel: a numeric pad or a full QWERTY, filling a fixed
/// height so every key is a large touch target.
class _Keyboard extends StatefulWidget {
  final bool numeric;
  final void Function(String) onKey;
  final VoidCallback onBackspace;
  final VoidCallback onDone;

  const _Keyboard({
    required this.numeric,
    required this.onKey,
    required this.onBackspace,
    required this.onDone,
  });

  @override
  State<_Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<_Keyboard> {
  bool _shift = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: widget.numeric ? _numericPad() : _qwertyPad(),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) =>
      Expanded(child: Row(children: children));

  Widget _numericPad() {
    Widget digit(String d) => _Key(label: d, onTap: () => widget.onKey(d));
    return Column(
      children: [
        _row([digit('1'), digit('2'), digit('3')]),
        _row([digit('4'), digit('5'), digit('6')]),
        _row([digit('7'), digit('8'), digit('9')]),
        _row([
          digit('.'),
          digit('0'),
          _Key(
            icon: const Icon(Icons.backspace_outlined),
            onTap: widget.onBackspace,
          ),
        ]),
        _row([
          _Key(
            icon: const Icon(Icons.check),
            highlight: true,
            onTap: widget.onDone,
          ),
        ]),
      ],
    );
  }

  Widget _qwertyPad() {
    const row0 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    const row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
    const row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
    const row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

    String glyph(String c) => _shift ? c.toUpperCase() : c;
    Widget letter(String c) =>
        _Key(label: glyph(c), onTap: () => widget.onKey(glyph(c)));

    return Column(
      children: [
        _row([for (final c in row0) letter(c)]),
        _row([for (final c in row1) letter(c)]),
        _row([for (final c in row2) letter(c)]),
        _row([
          _Key(
            icon: const Icon(Icons.arrow_upward),
            highlight: _shift,
            onTap: () => setState(() => _shift = !_shift),
          ),
          for (final c in row3) letter(c),
          _Key(
            icon: const Icon(Icons.backspace_outlined),
            onTap: widget.onBackspace,
          ),
        ]),
        _row([
          _Key(label: '.', onTap: () => widget.onKey('.')),
          _Key(
            icon: const Icon(Icons.space_bar),
            flex: 6,
            onTap: () => widget.onKey(' '),
          ),
          _Key(
            icon: const Icon(Icons.check),
            flex: 2,
            highlight: true,
            onTap: widget.onDone,
          ),
        ]),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final int flex;
  final bool highlight;
  final VoidCallback onTap;

  const _Key({
    this.label,
    this.icon,
    this.flex = 1,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: highlight ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child:
                  icon ??
                  Text(
                    label ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
