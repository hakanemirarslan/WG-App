import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => CatalogRepository());

/// The catalog is global and small. It is dropped when no screen uses it any more, so the
/// next picker always shows the current catalog instead of one cached for the whole session.
final catalogProvider = FutureProvider.autoDispose<List<CatalogItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchCatalog();
});

final frequentItemsProvider =
    FutureProvider.autoDispose.family<List<GroupItem>, String>((ref, groupId) {
  return ref.watch(catalogRepositoryProvider).fetchFrequentItems(groupId);
});
