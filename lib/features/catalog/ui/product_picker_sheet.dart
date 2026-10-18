import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/text_search.dart';
import '../../../l10n/app_localizations.dart';
import '../data/catalog_repository.dart';
import '../providers/catalog_providers.dart';

/// What the user picked: a catalog product or a new free-text one.
/// Exactly one of the two fields is set.
class PickedProduct {
  final String? catalogItemId;
  final String? customName;

  const PickedProduct.catalog(String this.catalogItemId) : customName = null;
  const PickedProduct.custom(String this.customName) : catalogItemId = null;
}

/// Bottom sheet product picker (SPEC 7): search, frequently used, catalog by
/// category, and "add 'xyz'" for products that do not exist yet.
Future<PickedProduct?> showProductPicker(BuildContext context, String groupId) {
  return showModalBottomSheet<PickedProduct>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ProductPickerSheet(groupId: groupId),
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
  const _ProductPickerSheet({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _query = '';

  bool _matches(String query, Iterable<String?> names) {
    return names.any((name) => name != null && normalizeForSearch(name).contains(query));
  }

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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(catalogProvider),
                  child: Text(l10n.retryButton),
                ),
              ),
              data: (catalog) {
                final frequent = frequentAsync.value ?? const <GroupItem>[];
                return _buildList(context, l10n, lang, query, rawQuery, catalog, frequent);
              },
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
        children.add(ListTile(
          title: Text(item.name.localized(lang)),
          onTap: () => Navigator.pop(
            context,
            item.catalogItemId != null
                ? PickedProduct.catalog(item.catalogItemId!)
                : PickedProduct.custom(item.name.customName!),
          ),
        ));
      }
    }

    String? currentCategory;
    for (final item in matchingCatalog) {
      if (item.category != currentCategory) {
        currentCategory = item.category;
        children.add(_SectionHeader(categoryLabel(l10n, item.category)));
      }
      children.add(ListTile(
        title: Text(item.localized(lang)),
        onTap: () => Navigator.pop(context, PickedProduct.catalog(item.id)),
      ));
    }

    if (searching && !exactMatchExists) {
      children.insert(
        0,
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l10n.addCustomProduct(rawQuery)),
          onTap: () => Navigator.pop(context, PickedProduct.custom(rawQuery)),
        ),
      );
    }

    if (children.isEmpty) {
      return Center(child: Text(l10n.noSearchResults));
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
