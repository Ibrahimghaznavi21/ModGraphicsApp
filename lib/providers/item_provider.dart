import 'package:flutter/foundation.dart';

import '../models/item_model.dart';
import '../services/supabase_service.dart';

/// Caches item lists keyed by user id so returning to a detail screen
/// is instant.
class ItemProvider extends ChangeNotifier {
  ItemProvider({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  final SupabaseService _service;

  final Map<String, List<ItemModel>> _itemsByUser = {};
  final Set<String> _loadingUsers = <String>{};
  String? _error;

  List<ItemModel> itemsFor(String userId) =>
      List.unmodifiable(_itemsByUser[userId] ?? const []);

  bool isLoadingFor(String userId) => _loadingUsers.contains(userId);

  String? get error => _error;

  /// Fetches all items for [userId].
  Future<void> loadItems(String userId) async {
    _loadingUsers.add(userId);
    _error = null;
    notifyListeners();
    try {
      final items = await _service.fetchItemsForUser(userId);
      _itemsByUser[userId] = items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingUsers.remove(userId);
      notifyListeners();
    }
  }

  /// Inserts [item] into Supabase and prepends it to the cache.
  /// Rethrows so the caller can decide how to notify the user.
  Future<void> addItem(ItemModel item) async {
    try {
      final saved = await _service.insertItem(item);
      final existing = _itemsByUser[item.userId] ?? const <ItemModel>[];
      _itemsByUser[item.userId] = [saved, ...existing];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Persists [item] to Supabase and swaps it into the cache in place.
  /// Preserves list order, unlike [addItem]. Rethrows on failure so the
  /// caller can surface an error; the cache is only mutated on success,
  /// so a failed save leaves the UI consistent with the server.
  Future<void> updateItem(ItemModel item) async {
    try {
      final saved = await _service.updateItem(item);
      final list = _itemsByUser[item.userId];
      if (list != null) {
        final idx = list.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          final next = List<ItemModel>.from(list);
          next[idx] = saved;
          _itemsByUser[item.userId] = next;
        }
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Sum of `remaining` across all items for [userId]  — the customer's
  /// outstanding balance.
  double balanceFor(String userId) {
    final items = _itemsByUser[userId] ?? const [];
    return items.fold<double>(0, (sum, i) => sum + i.remaining);
  }

  /// Sum of gross totals across all items.
  double totalFor(String userId) {
    final items = _itemsByUser[userId] ?? const [];
    return items.fold<double>(0, (sum, i) => sum + i.totalPrice);
  }
}
