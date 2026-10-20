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
    builder: (context) => _ProductPickerSheet(groupId: groupId),
  );
}

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
    builder: (context) => _ProductPickerSheet(groupId: groupId, multi: true, initial: initial),
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

  Widget? _checkmark(PickedProduct product) => widget.multi && _chosen.containsKey(product.key)
      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final catalogAsync = ref.watch(catalogProvider);
    final frequentAsync = ref.watch(frequentItemsProvider(widget.groupId));
    final query = normalizeForSearch(_query);
    final rawQuery = _query.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchProductsHint,
                border: const OutlineInputBorder(),
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
                padding: const EdgeInsets.all(16),
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
        ? catalog.where((item) => _matches(query, [item.nameDe, item.nameEn])).toList()
        : catalog;
    // Free-text products of this group are only reachable via frequent items.
    final matchingFrequent = frequent.where((item) {
      if (!searching) return true;
      return _matches(query, [item.name.customName, item.name.nameDe, item.name.nameEn]);
    }).toList();

    final exactMatchExists = [
      ...matchingCatalog.expand((item) => [item.nameDe, item.nameEn]),
      ...matchingFrequent.map((item) => item.name.customName),
    ].any((name) => name != null && normalizeForSearch(name) == query);

    final children = <Widget>[];

    if (matchingFrequent.isNotEmpty) {
      children.add(_SectionHeader(l10n.frequentTitle));
      for (final item in matchingFrequent) {
        final product = item.catalogItemId != null
            ? PickedProduct.catalog(item.catalogItemId!)
            : PickedProduct.custom(item.name.customName!);
        children.add(
          ListTile(
            title: Text(item.name.localized(lang)),
            trailing: _checkmark(product),
            onTap: () => _onTap(product),
          ),
        );
      }
    }

    String? currentCategory;
    for (final item in matchingCatalog) {
      if (item.category != currentCategory) {
        currentCategory = item.category;
        children.add(_SectionHeader(categoryLabel(l10n, item.category)));
      }
      final product = PickedProduct.catalog(item.id);
      children.add(
        ListTile(
          title: Text(item.localized(lang)),
          trailing: _checkmark(product),
          onTap: () => _onTap(product),
        ),
      );
    }

    if (searching && !exactMatchExists) {
      children.insert(
        0,
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l10n.addCustomProduct(rawQuery)),
          onTap: () => _onAddCustom(rawQuery),
        ),
      );
    }

    if (children.isEmpty) {
      return EmptyView(icon: Icons.search_off, message: l10n.noSearchResults);
    }
    return ListView(children: children);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
