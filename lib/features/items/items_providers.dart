import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item.dart';
import 'items_db.dart';
import 'items_repository.dart';

final itemsDbProvider = Provider<ItemsDb>((ref) => ItemsDb.instance);

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final db = ref.watch(itemsDbProvider);
  return ItemsRepository(db);
});

/// Wichtig: Provider-Name so, dass du ihn im Screen verwenden kannst.
/// Wenn dein Screen "itemsListProvider" erwartet, dann bleibt der Name genau so.
final itemsListProvider =
    StateNotifierProvider<ItemsController, AsyncValue<List<Item>>>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return ItemsController(repo)..load();
});

class ItemsController extends StateNotifier<AsyncValue<List<Item>>> {
  final ItemsRepository _repo;

  String _vaultId = 'personal';

  ItemsController(this._repo) : super(const AsyncValue.loading());

  Future<void> load({String vaultId = 'personal'}) async {
    _vaultId = vaultId;
    state = const AsyncValue.loading();
    try {
      final items = await _repo.listItems(vaultId: _vaultId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final items = await _repo.listItems(vaultId: _vaultId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> upsert(Item item) async {
    await _repo.upsert(item);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteById(id);
    await refresh();
  }
}
