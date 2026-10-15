import 'package:flutter/material.dart';

import '../domain/text_rules.dart';

/// Asks for a list name (FR-02). Returns the entered text, or null on cancel.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
  required String confirmLabel,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) =>
          _NameDialog(title: title, initial: initial, confirmLabel: confirmLabel),
    );

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initial,
    required this.confirmLabel,
  });

  final String title;
  final String initial;
  final String confirmLabel;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initial.length);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = cleanName(_controller.text, TextRules.listNameMaxLength);
    if (name == null) {
      setState(() => _error = 'Enter a name');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('name-field'),
        controller: _controller,
        autofocus: true,
        maxLength: TextRules.listNameMaxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Name',
          errorText: _error,
          counterText: '',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('name-confirm'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// The result of the item dialog.
typedef ItemEdit = ({String name, String? note});

/// Edits an item's name and note (FR-03, FR-06). [validateName] returns an
/// error text (e.g. for a duplicate name) or null.
Future<ItemEdit?> showItemDialog(
  BuildContext context, {
  required String name,
  String? note,
  required String? Function(String name) validateName,
}) =>
    showDialog<ItemEdit>(
      context: context,
      builder: (_) =>
          _ItemDialog(name: name, note: note, validateName: validateName),
    );

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({
    required this.name,
    required this.note,
    required this.validateName,
  });

  final String name;
  final String? note;
  final String? Function(String name) validateName;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _note = TextEditingController(text: widget.note ?? '');
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final name = cleanName(_name.text, TextRules.itemNameMaxLength);
    final error = name == null ? 'Enter a name' : widget.validateName(name);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop((name: name!, note: cleanNote(_note.text)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('item-name-field'),
            controller: _name,
            maxLength: TextRules.itemNameMaxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Item',
              errorText: _error,
              counterText: '',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('item-note-field'),
            controller: _note,
            autofocus: true,
            maxLength: TextRules.noteMaxLength,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. 2 l, whole grain, brand',
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('item-save'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// A yes / no question. Returns true only if confirmed.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Picks one of [options]; the current one is marked. Option keys: `<keyPrefix>-<id>`.
Future<T?> showChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) label,
  required String Function(T) id,
  required String keyPrefix,
}) =>
    showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final o in options)
            SimpleDialogOption(
              key: Key('$keyPrefix-${id(o)}'),
              onPressed: () => Navigator.of(context).pop(o),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: o == selected ? const Icon(Icons.check, size: 20) : null,
                  ),
                  Expanded(child: Text(label(o))),
                ],
              ),
            ),
        ],
      ),
    );
