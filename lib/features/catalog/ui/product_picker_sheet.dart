import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/text_search.dart';
import '../../../core/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/catalog_repository.dart';
import '../providers/catalog_providers.dart';

/// Bottom sheet product picker (SPEC 7): search, frequently used, catalog by
/// category, and "add 'xyz'" for products that do not exist yet.
/// Single choice: closes with the tapped product (shopping list).
Future<PickedProduct?> showProductPicker(BuildContext context, String groupId) {
  return showModalBottomSheet<PickedProduct>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: _sheetHeightFactor,
      child: _ProductPickerSheet(groupId: groupId),
    ),
  );
}

/// Leaves a strip of the page visible above the sheet, so it can be closed by tapping outside.
const _sheetHeightFactor = 0.88;

/// Multi choice (expense form, SPEC 7): taps toggle products, "Done" closes
/// with all of them. Dismissing the sheet returns null and keeps [initial].
Future<List<PickedProduct>?> showProductMultiPicker(
  BuildContext context,
  String groupId, {
  List<PickedProduct> initial = const [],
}) {
  return showModalBottomSheet<List<PickedProduct>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: _sheetHeightFactor,
      child: _ProductPickerSheet(groupId: groupId, multi: true, initial: initial),
    ),
  );
}

String categoryLabel(AppLocalizations l10n, String category) {
  return switch (category) {
    'food' => l10n.categoryFood,
    'household' => l10n.categoryHousehold,
    _ => category,
  };
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet({required this.groupId, this.multi = false, this.initial = const []});

  final String groupId;
  final bool multi;
  final List<PickedProduct> initial;

  @override
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  late final Map<String, PickedProduct> _chosen;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _chosen = {for (final product in widget.initial) product.key: product};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String query, Iterable<String?> names) {
    return names.any((name) => name != null && normalizeForSearch(name).contains(query));
  }

  /// Single mode closes the sheet with the product; multi mode toggles it.
  void _onTap(PickedProduct product) {
    if (!widget.multi) {
      Navigator.pop(context, product);
      return;
    }
    setState(() {
      if (_chosen.remove(product.key) == null) _chosen[product.key] = product;
    });
  }

  /// "Add 'xyz'": in multi mode keep the sheet open and clear the search.
  void _onAddCustom(String name) {
    final product = PickedProduct.custom(name);
    if (!widget.multi) {
      Navigator.pop(context, product);
      return;
    }
    setState(() {
      _chosen[product.key] = product;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final catalogAsync = ref.watch(catalogProvider);
    final frequentAsync = ref.watch(frequentItemsProvider(widget.groupId));
    final query = normalizeForSearch(_query);
    final rawQuery = _query.trim();

    final title = widget.multi ? l10n.chooseItemsButton : l10n.addItemButton;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancelButton,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchProductsHint,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _query = '';
                          _searchController.clear();
                        }),
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: catalogAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) =>
                  ErrorView(error: error, onRetry: () => ref.invalidate(catalogProvider)),
              data: (catalog) {
                final frequent = frequentAsync.value ?? const <GroupItem>[];
                return _buildList(context, l10n, lang, query, rawQuery, catalog, frequent);
              },
            ),
          ),
          if (widget.multi)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _chosen.values.toList()),
                    child: Text(l10n.pickerDoneButton(_chosen.length)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    String lang,
    String query,
    String rawQuery,
    List<CatalogItem> catalog,
    List<GroupItem> frequent,
  ) {
    final searching = query.isNotEmpty;
    final matchingCatalog = searching
        ? catalog.where((item) => _matches(query, [item.nameDe, item.nameEn, item.nameTr])).toList()
        : catalog;
    // Free-text products of this group are only reachable via frequent items.
    final matchingFrequent = frequent.where((item) {
      if (!searching) return true;
      return _matches(query, [
        item.name.customName,
        item.name.nameDe,
        item.name.nameEn,
        item.name.nameTr,
      ]);
    }).toList();

    final exactMatchExists = [
      ...matchingCatalog.expand((item) => [item.nameDe, item.nameEn, item.nameTr]),
      ...matchingFrequent.map((item) => item.name.customName),
    ].any((name) => name != null && normalizeForSearch(name) == query);

    final sections = <Widget>[];

    if (searching && !exactMatchExists) {
      // The new-product action comes first so it is reachable without scrolling.
      sections.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.addCustomProduct(rawQuery)),
              onPressed: () => _onAddCustom(rawQuery),
            ),
          ),
        ),
      );
    }

    if (matchingFrequent.isNotEmpty) {
      sections.add(
        _ChipSection(
          icon: Icons.history,
          title: l10n.frequentTitle,
          chips: [
            for (final item in matchingFrequent)
              _chip(
                item.name.localized(lang),
                item.catalogItemId != null
                    ? PickedProduct.catalog(item.catalogItemId!)
                    : PickedProduct.custom(item.name.customName!),
              ),
          ],
        ),
      );
    }

    // Catalog items arrive sorted by category, so group them in order.
    final byCategory = <String, List<CatalogItem>>{};
    for (final item in matchingCatalog) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }
    for (final entry in byCategory.entries) {
      sections.add(
        _ChipSection(
          icon: _categoryIcon(entry.key),
          title: categoryLabel(l10n, entry.key),
          chips: [
            for (final item in entry.value)
              _chip(item.localized(lang), PickedProduct.catalog(item.id)),
          ],
        ),
      );
    }

    if (sections.isEmpty) {
      return EmptyView(icon: Icons.search_off, message: l10n.noSearchResults);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: sections);
  }

  /// One tappable product. Single mode: tap picks and closes. Multi mode: tap toggles.
  Widget _chip(String label, PickedProduct product) {
    if (!widget.multi) {
      return ActionChip(label: Text(label), onPressed: () => _onTap(product));
    }
    return FilterChip(
      label: Text(label),
      selected: _chosen.containsKey(product.key),
      onSelected: (_) => _onTap(product),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
  'food' => Icons.restaurant_outlined,
  'household' => Icons.cleaning_services_outlined,
  _ => Icons.category_outlined,
};

/// A titled group of product chips that wrap onto as many lines as needed.
class _ChipSection extends StatelessWidget {
  const _ChipSection({required this.icon, required this.title, required this.chips});

  final IconData icon;
  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}
