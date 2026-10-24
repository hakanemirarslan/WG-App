import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';

/// Asks whether the bought item should also be recorded as an expense.
///
/// Returns null if the user cancelled (the item stays open), 0 for "just tick it
/// off" (empty price) and the price in cents otherwise.
Future<int?> showBoughtPriceDialog(BuildContext context, String itemName) {
  return showDialog<int>(
    context: context,
    builder: (context) => _BoughtPriceDialog(itemName: itemName),
  );
}

class _BoughtPriceDialog extends StatefulWidget {
  const _BoughtPriceDialog({required this.itemName});

  final String itemName;

  @override
  State<_BoughtPriceDialog> createState() => _BoughtPriceDialogState();
}

class _BoughtPriceDialogState extends State<_BoughtPriceDialog> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.pop(context, 0);
      return;
    }
    final cents = parseToCents(text);
    if (cents == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, cents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.itemName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.priceOptionalLabel,
          suffixText: '€',
          helperText: l10n.priceSplitHint,
          helperMaxLines: 2,
          errorText: _invalid ? l10n.invalidAmountMessage : null,
        ),
        onChanged: (_) {
          if (_invalid) setState(() => _invalid = false);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancelButton)),
        FilledButton(onPressed: _submit, child: Text(l10n.markBoughtConfirm)),
      ],
    );
  }
}
