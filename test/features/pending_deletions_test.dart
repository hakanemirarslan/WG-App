import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/features/shopping_list/providers/shopping_providers.dart';

void main() {
  test('a deleted entry is hidden until undo restores it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pending = container.read(pendingDeletionsProvider.notifier);

    expect(container.read(pendingDeletionsProvider), isEmpty);
    pending.hide('e1');
    pending.hide('e2');
    expect(container.read(pendingDeletionsProvider), {'e1', 'e2'});
    pending.restore('e1');
    expect(container.read(pendingDeletionsProvider), {'e2'});
  });

  test('restoring an entry that is not hidden changes nothing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pendingDeletionsProvider.notifier).restore('missing');
    expect(container.read(pendingDeletionsProvider), isEmpty);
  });
}
