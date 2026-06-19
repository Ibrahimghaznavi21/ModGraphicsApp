

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/supabase_service.dart';

/// Holds the list of users shown on the home screen.
class UserProvider extends ChangeNotifier {
  UserProvider({SupabaseService? service})
    : _service = service ?? SupabaseService.instance;

  final SupabaseService _service;

  List<UserModel> _users = const [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Users matching [searchQuery]. Case-insensitive partial match on name.
  /// Returns the full list when the query is empty.
  ///
  /// Runs on the in-memory list — no network trip per keystroke.
  List<UserModel> get filteredUsers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return users;
    return List.unmodifiable(
      _users.where((u) => u.name.toLowerCase().contains(q)),
    );
  }

  /// Updates the search query and notifies listeners.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Shortcut used by the clear (✕) button in the search field.
  void clearSearch() => setSearchQuery('');

  /// Pulls the full user list from Supabase.
  Future<void> loadUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _service.fetchUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Finds an existing user by phone number or creates a new one.
  /// Updates the local cache so the home screen stays in sync without
  /// a second network trip.
  Future<UserModel> findOrCreate({
    required String name,
    required String phoneNumber,
  }) async {
    final user = await _service.findOrCreateUser(
      name: name,
      phoneNumber: phoneNumber,
    );

    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx == -1) {
      _users = [user, ..._users];
    } else {
      // Keep the most recent name/phone in the local cache.
      final updated = List<UserModel>.from(_users);
      updated[idx] = user;
      _users = updated;
    }
    notifyListeners();
    return user;
  }

  /// Case-insensitive name match or digits-only phone match against the
  /// local cache. Returns `null` if nothing matches. No network call.
  UserModel? findByNameOrPhone(String name, String phone) {
    final nameLower = name.trim().toLowerCase();
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');

    for (final u in _users) {
      if (nameLower.isNotEmpty && u.name.trim().toLowerCase() == nameLower) {
        return u;
      }
      if (phoneDigits.isNotEmpty &&
          u.phoneNumber.replaceAll(RegExp(r'\D'), '') == phoneDigits) {
        return u;
      }
    }
    return null;
  }

  /// Inserts a new user and prepends it to the local cache.
  Future<UserModel> createUser({
    required String name,
    required String phoneNumber,
  }) async {
    final user = await _service.insertUser(
      name: name,
      phoneNumber: phoneNumber,
    );
    _users = [user, ..._users];
    notifyListeners();
    return user;
  }

  /// Optimistically deletes a user from the local cache, then persists
  /// the delete to Supabase. On failure, reinserts the user at the same
  /// position and rethrows so the UI can surface an error.
  ///
  /// The items FK has `ON DELETE CASCADE`, so related items are removed
  /// server-side. We don't need to touch [ItemProvider] here — its cache
  /// is keyed by user id, and any entries for a deleted user become
  /// unreachable (the detail screen is the only consumer, and its user
  /// is gone from the list).
  Future<void> deleteUser(UserModel user) async {
    final previous = _users;
    final index = previous.indexWhere((u) => u.id == user.id);
    if (index == -1) return;

    // Optimistic removal
    _users = List<UserModel>.from(previous)..removeAt(index);
    notifyListeners();

    try {
      await _service.deleteUser(user.id);
    } catch (e) {
      // Roll back to the exact prior state — same user, same position.
      _users = List<UserModel>.from(_users)..insert(index, user);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Call after a screen has shown the error to clear it.
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
