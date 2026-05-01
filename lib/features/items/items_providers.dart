import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/db_providers.dart';
import 'item.dart';
import 'items_repository.dart';

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final dbManager = ref.watch(databaseManagerProvider);
  return ItemsRepository(dbManager: dbManager);
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

  ItemsController(this._repo) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repo.listItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final items = await _repo.listItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> upsert(Item item) async {
    await _repo.upsert(item);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _repo.deleteById(id);
    await refresh();
  }
}
