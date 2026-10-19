import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/split.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/providers/catalog_providers.dart';
import '../../catalog/ui/product_picker_sheet.dart';
import '../../groups/providers/groups_providers.dart';
import '../../groups/ui/group_error_text.dart';
import '../data/expenses_repository.dart';
import '../providers/expenses_providers.dart';

enum SplitMode { equal, amounts, shares }

/// A possible participant: an active member, or a former member who is
/// already on the expense being edited (SPEC 10: they stay on old expenses).
class _Person {
  final String id;
  final String name;
  final bool isFormer;

  _Person(this.id, this.name, {this.isFormer = false});
}

/// New / edit expense form (SPEC 8). [expenseId] null means a new expense.
class ExpenseFormPage extends ConsumerWidget {
  const ExpenseFormPage({super.key, required this.groupId, this.expenseId});

  final String groupId;
  final String? expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final expensesAsync = ref.watch(expensesProvider(groupId));
    final title = expenseId == null ? l10n.newExpenseTitle : l10n.editExpenseTitle;

    Widget body() {
      if (membersAsync.hasError || expensesAsync.hasError) {
        return ErrorView(
          error: membersAsync.error ?? expensesAsync.error,
          onRetry: () {
            ref.invalidate(groupMembersProvider(groupId));
            ref.invalidate(expensesProvider(groupId));
          },
        );
      }
      final members = membersAsync.value;
      final expenses = expensesAsync.value;
      if (members == null || expenses == null) {
        return const LoadingView();
      }

      Expense? initial;
      if (expenseId != null) {
        final matches = expenses.where((e) => e.id == expenseId);
        if (matches.isEmpty) return EmptyView(message: l10n.expenseNotFound);
        initial = matches.first;
      }

      final people = [for (final m in members) _Person(m.userId, m.displayName)];
      if (initial != null) {
        // Former members already on this expense must stay selectable.
        final known = people.map((p) => p.id).toSet();
        for (final share in initial.shares) {
          if (known.add(share.userId)) {
            people.add(_Person(share.userId, share.name, isFormer: true));
          }
        }
        if (known.add(initial.paidBy)) {
          people.add(_Person(initial.paidBy, initial.paidByName, isFormer: true));
        }
      }
      return _ExpenseForm(groupId: groupId, people: people, initial: initial);
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body(),
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({required this.groupId, required this.people, required this.initial});

  final String groupId;
  final List<_Person> people;
  final Expense? initial;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Map<String, TextEditingController> _shareAmountControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  late final Set<String> _selected;
  List<PickedProduct> _items = [];
  late String _payerId;
  late DateTime _date;
  SplitMode _mode = SplitMode.equal;
  bool _isSaving = false;
  bool _showErrors = false;
  bool _prefilled = false;

  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    for (final person in widget.people) {
      _shareAmountControllers[person.id] = TextEditingController();
      _weightControllers[person.id] = TextEditingController(text: '1');
    }

    final initial = widget.initial;
    if (initial == null) {
      _selected = {for (final p in widget.people.where((p) => !p.isFormer)) p.id};
      _payerId = supabase.auth.currentUser!.id;
      _date = DateTime.now();
    } else {
      _selected = {for (final share in initial.shares) share.userId};
      _payerId = initial.paidBy;
      _date = initial.date;
      _descriptionController.text = initial.description ?? '';
      _items = [for (final item in initial.items) item.product];

      // The split mode is not stored: show "equal" if the saved shares are
      // exactly what an equal split would give, otherwise the saved amounts.
      final equal = splitEqual(initial.amountCents, _selected);
      final isEqual = equal.every((e) => initial.shares
          .any((s) => s.userId == e.userId && s.shareCents == e.shareCents));
      if (!isEqual) _mode = SplitMode.amounts;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs the locale (decimal separator), so it cannot run in initState.
    if (_prefilled) return;
    _prefilled = true;
    final initial = widget.initial;
    if (initial == null) return;
    _amountController.text = formatCentsPlain(initial.amountCents, locale: _lang);
    for (final share in initial.shares) {
      _shareAmountControllers[share.userId]!.text =
          formatCentsPlain(share.shareCents, locale: _lang);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (final c in _shareAmountControllers.values) {
      c.dispose();
    }
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _amountCents => parseToCents(_amountController.text);

  /// The shares for the current input, or null if the input is not valid yet.
  /// [error] explains why, for the save button and the inline hints.
  ({List<ExpenseShare>? shares, String? error}) _computeShares(AppLocalizations l10n) {
    final amount = _amountCents;
    if (amount == null) return (shares: null, error: l10n.invalidAmountMessage);
    if (_selected.isEmpty) return (shares: null, error: l10n.selectParticipantMessage);

    switch (_mode) {
      case SplitMode.equal:
        return (shares: splitEqual(amount, _selected), error: null);
      case SplitMode.shares:
        final weights = <String, int>{};
        for (final id in _selected) {
          final weight = int.tryParse(_weightControllers[id]!.text.trim());
          if (weight == null || weight <= 0) {
            return (shares: null, error: l10n.invalidShareInputMessage);
          }
          weights[id] = weight;
        }
        return (shares: splitByWeights(amount, weights), error: null);
      case SplitMode.amounts:
        final cents = <String, int>{};
        for (final id in _selected) {
          final value = parseShareCents(_shareAmountControllers[id]!.text);
          if (value == null) return (shares: null, error: l10n.invalidShareInputMessage);
          cents[id] = value;
        }
        if (remainingCents(amount, cents) != 0) {
          return (shares: null, error: l10n.sharesMismatchMessage);
        }
        return (shares: splitExact(amount, cents), error: null);
    }
  }

  void _changeMode(SplitMode mode) {
    setState(() {
      // Start "amounts" from the equal split instead of an empty form.
      final amount = _amountCents;
      final allEmpty = _shareAmountControllers.values.every((c) => c.text.trim().isEmpty);
      if (mode == SplitMode.amounts && amount != null && _selected.isNotEmpty && allEmpty) {
        for (final share in splitEqual(amount, _selected)) {
          _shareAmountControllers[share.userId]!.text =
              formatCentsPlain(share.shareCents, locale: _lang);
        }
      }
      _mode = mode;
    });
  }

  Future<void> _chooseItems() async {
    final chosen = await showProductMultiPicker(context, widget.groupId, initial: _items);
    if (chosen != null) setState(() => _items = chosen);
  }

  String _itemLabel(PickedProduct product, List<CatalogItem> catalog) {
    if (product.customName != null) return product.customName!;
    final matches = catalog.where((c) => c.id == product.catalogItemId);
    return matches.isEmpty ? '' : matches.first.localized(_lang);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final result = _computeShares(l10n);
    if (result.shares == null) {
      setState(() => _showErrors = true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Turn the picks into the group's product records (created if new).
      final catalogRepository = ref.read(catalogRepositoryProvider);
      final itemIds = <String>[
        for (final product in _items)
          await catalogRepository.getOrCreateGroupItem(
            widget.groupId,
            catalogItemId: product.catalogItemId,
            customName: product.customName,
          ),
      ];
      await ref.read(expensesRepositoryProvider).saveExpense(
            groupId: widget.groupId,
            expenseId: widget.initial?.id,
            paidBy: _payerId,
            amountCents: _amountCents!,
            description: _descriptionController.text,
            date: _date,
            shares: result.shares!,
            itemIds: itemIds,
          );
      ref.invalidate(expensesProvider(widget.groupId));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(groupErrorText(l10n, error))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final computed = _computeShares(l10n);
    final shareByUser = {
      for (final share in computed.shares ?? const <ExpenseShare>[]) share.userId: share.shareCents,
    };
    final amount = _amountCents;
    final amountText = _amountController.text.trim();

    String personLabel(_Person person) =>
        person.isFormer ? '${person.name} ${l10n.formerMemberSuffix}' : person.name;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _amountController,
              autofocus: widget.initial == null,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                suffixText: '€',
                errorText: amount == null && (amountText.isNotEmpty || _showErrors)
                    ? l10n.invalidAmountMessage
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _payerId,
              decoration: InputDecoration(labelText: l10n.paidByLabel),
              items: [
                for (final person in widget.people)
                  DropdownMenuItem(value: person.id, child: Text(personLabel(person))),
              ],
              onChanged: (value) => setState(() => _payerId = value!),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.dateLabel),
              subtitle: Text(DateFormat.yMMMd(_lang).format(_date)),
              onTap: _pickDate,
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
            const SizedBox(height: 16),
            Text(l10n.itemsTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final product in _items)
                  InputChip(
                    label: Text(_itemLabel(product, ref.watch(catalogProvider).value ?? const [])),
                    onDeleted: () => setState(() => _items.remove(product)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: Text(l10n.chooseItemsButton),
                  onPressed: _chooseItems,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.splitBetweenTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<SplitMode>(
              segments: [
                ButtonSegment(value: SplitMode.equal, label: Text(l10n.splitEqualMode)),
                ButtonSegment(value: SplitMode.amounts, label: Text(l10n.splitAmountsMode)),
                ButtonSegment(value: SplitMode.shares, label: Text(l10n.splitSharesMode)),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => _changeMode(selection.first),
            ),
            const SizedBox(height: 8),
            for (final person in widget.people)
              _ParticipantRow(
                label: personLabel(person),
                selected: _selected.contains(person.id),
                mode: _mode,
                shareText: shareByUser.containsKey(person.id)
                    ? formatCents(shareByUser[person.id]!, locale: _lang)
                    : null,
                amountController: _shareAmountControllers[person.id]!,
                weightController: _weightControllers[person.id]!,
                onSelected: (value) => setState(() {
                  value ? _selected.add(person.id) : _selected.remove(person.id);
                }),
                onChanged: () => setState(() {}),
              ),
            if (_mode == SplitMode.amounts && amount != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.remainingLabel(
                    formatCents(
                      remainingCents(amount, {
                        for (final id in _selected)
                          id: parseShareCents(_shareAmountControllers[id]!.text) ?? 0,
                      }),
                      locale: _lang,
                    ),
                  ),
                  style: TextStyle(
                    color: computed.error == null ? null : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (_showErrors && computed.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  computed.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.label,
    required this.selected,
    required this.mode,
    required this.shareText,
    required this.amountController,
    required this.weightController,
    required this.onSelected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final SplitMode mode;
  final String? shareText;
  final TextEditingController amountController;
  final TextEditingController weightController;
  final ValueChanged<bool> onSelected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    Widget? trailing;
    if (selected) {
      switch (mode) {
        case SplitMode.equal:
          trailing = shareText == null ? null : Text(shareText!);
        case SplitMode.shares:
          trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                child: TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (shareText != null) ...[
                const SizedBox(width: 12),
                SizedBox(width: 80, child: Text(shareText!, textAlign: TextAlign.end)),
              ],
            ],
          );
        case SplitMode.amounts:
          trailing = SizedBox(
            width: 110,
            child: TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(suffixText: '€'),
              onChanged: (_) => onChanged(),
            ),
          );
      }
    }

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: selected,
      onChanged: (value) => onSelected(value ?? false),
      title: Row(
        children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ?trailing,
        ],
      ),
    );
  }
}
