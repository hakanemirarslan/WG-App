import '../../../core/supabase_client.dart';

/// Display names of a product: either a catalog entry (DE + EN + TR) or a
/// free-text name typed by a group member (single language, SPEC 12).
class ProductName {
  final String? customName;
  final String? nameDe;
  final String? nameEn;
  final String? nameTr;

  ProductName({this.customName, this.nameDe, this.nameEn, this.nameTr});

  /// [map] is a `group_items` row embedding `catalog_items(name_de, name_en, name_tr)`.
  factory ProductName.fromGroupItemMap(Map<String, dynamic> map) {
    final catalog = map['catalog_items'] as Map<String, dynamic>?;
    return ProductName(
      customName: map['custom_name'] as String?,
      nameDe: catalog?['name_de'] as String?,
      nameEn: catalog?['name_en'] as String?,
      nameTr: catalog?['name_tr'] as String?,
    );
  }

  String localized(String languageCode) {
    if (customName != null) return customName!;
    final preferred = switch (languageCode) {
      'de' => nameDe,
      'tr' => nameTr,
      _ => nameEn,
    };
    return preferred ?? nameEn ?? nameDe ?? '';
  }
}

/// What the user picked: a catalog product or a new free-text one.
/// Exactly one of the two fields is set.
class PickedProduct {
  final String? catalogItemId;
  final String? customName;

  const PickedProduct.catalog(String this.catalogItemId) : customName = null;
  const PickedProduct.custom(String this.customName) : catalogItemId = null;

  /// Identity for "already chosen?" checks. Free text compares the way the
  /// database does (case-insensitive), so "milch" and "Milch" are one product.
  String get key => catalogItemId != null
      ? 'catalog:$catalogItemId'
      : 'custom:${customName!.trim().toLowerCase()}';
}

class CatalogItem {
  final String id;
  final String nameDe;
  final String nameEn;

  /// Null until a Turkish name exists; the English one is shown then.
  final String? nameTr;
  final String category;

  CatalogItem({
    required this.id,
    required this.nameDe,
    required this.nameEn,
    required this.nameTr,
    required this.category,
  });

  factory CatalogItem.fromMap(Map<String, dynamic> map) => CatalogItem(
    id: map['id'] as String,
    nameDe: map['name_de'] as String,
    nameEn: map['name_en'] as String,
    nameTr: map['name_tr'] as String?,
    category: map['category'] as String,
  );

  String localized(String languageCode) => switch (languageCode) {
    'de' => nameDe,
    'tr' => nameTr ?? nameEn,
    _ => nameEn,
  };
}

/// A product the group has used before (catalog-based or free text).
class GroupItem {
  final String id;
  final String? catalogItemId;
  final ProductName name;
  final int useCount;

  GroupItem({
    required this.id,
    required this.catalogItemId,
    required this.name,
    required this.useCount,
  });

  factory GroupItem.fromMap(Map<String, dynamic> map) => GroupItem(
    id: map['id'] as String,
    catalogItemId: map['catalog_item_id'] as String?,
    name: ProductName.fromGroupItemMap(map),
    useCount: map['use_count'] as int,
  );
}

class CatalogRepository {
  Future<List<CatalogItem>> fetchCatalog() async {
    final rows = await supabase
        .from('catalog_items')
        .select('id, name_de, name_en, name_tr, category')
        // Food was dropped from the picker (WG shopping is about shared household goods);
        // old group items that point at food rows still show their names elsewhere.
        .neq('category', 'food');
    return rows.map(CatalogItem.fromMap).toList();
  }

  /// Most used first, ties broken by most recently used (SPEC 7). Top 12.
  Future<List<GroupItem>> fetchFrequentItems(String groupId) async {
    final rows = await supabase
        .from('group_items')
        .select(
          'id, catalog_item_id, custom_name, use_count, catalog_items(name_de, name_en, name_tr)',
        )
        .eq('group_id', groupId)
        .gt('use_count', 0)
        .order('use_count', ascending: false)
        .order('last_used_at', ascending: false, nullsFirst: false)
        .limit(12);
    return rows.map(GroupItem.fromMap).toList();
  }

  /// Finds or creates the group's record for a product. Exactly one of
  /// [catalogItemId] / [customName] must be set. Done server-side so two
  /// members picking the same product at once cannot create duplicates.
  Future<String> getOrCreateGroupItem(
    String groupId, {
    String? catalogItemId,
    String? customName,
  }) async {
    final id = await supabase.rpc(
      'get_or_create_group_item',
      params: {'gid': groupId, 'cat_id': catalogItemId, 'custom': customName},
    );
    return id as String;
  }

  Future<void> touchGroupItem(String groupItemId) =>
      supabase.rpc('touch_group_item', params: {'item_id': groupItemId});
}
