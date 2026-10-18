import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => CatalogRepository());

/// The catalog is global and rarely changes, so it is fetched once per session.
final catalogProvider = FutureProvider<List<CatalogItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchCatalog();
});

final frequentItemsProvider =
    FutureProvider.autoDispose.family<List<GroupItem>, String>((ref, groupId) {
  return ref.watch(catalogRepositoryProvider).fetchFrequentItems(groupId);
});
