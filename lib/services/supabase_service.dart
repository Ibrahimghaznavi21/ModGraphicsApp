import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item_model.dart';
import '../models/user_model.dart';

/// Thin wrapper around Supabase for all reads and writes in the app.
///
/// Every method converts `PostgrestException`s into plain error strings so the
/// UI layer can show them without importing Supabase types.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ──────────────────────────────── USERS ────────────────────────────────

  Future<List<UserModel>> fetchUsers() async {
    try {
      final data = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => UserModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw 'Failed to load users: ${e.message}';
    } catch (e) {
      throw 'Failed to load users: $e';
    }
  }

  Future<UserModel> insertUser({
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final data = await _client
          .from('users')
          .insert({'name': name, 'phone_number': phoneNumber})
          .select()
          .single();
      return UserModel.fromMap(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      throw 'Failed to save user: ${e.message}';
    } catch (e) {
      throw 'Failed to save user: $e';
    }
  }

  /// Looks up a user by phone number. Returns the existing record if found,
  /// otherwise inserts a new one. Keeps the user list clean when re-entering
  /// items for an existing customer.
  Future<UserModel> findOrCreateUser({
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final existing = await _client
          .from('users')
          .select()
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (existing != null) {
        return UserModel.fromMap(Map<String, dynamic>.from(existing));
      }
      return await insertUser(name: name, phoneNumber: phoneNumber);
    } on PostgrestException catch (e) {
      throw 'Failed to save customer: ${e.message}';
    } catch (e) {
      throw 'Failed to save customer: $e';
    }
  }

  /// Deletes a user by id. The `items.user_id` FK has `ON DELETE CASCADE`
  /// set at the schema level, so the user's items are removed server-side
  /// in the same transaction — no manual cleanup needed.
  Future<void> deleteUser(String id) async {
    try {
      await _client.from('users').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw 'Failed to delete user: ${e.message}';
    } catch (e) {
      throw 'Failed to delete user: $e';
    }
  }

  // ──────────────────────────────── ITEMS ────────────────────────────────

  Future<List<ItemModel>> fetchItemsForUser(String userId) async {
    try {
      final data = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => ItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw 'Failed to load items: ${e.message}';
    } catch (e) {
      throw 'Failed to load items: $e';
    }
  }

  Future<ItemModel> insertItem(ItemModel item) async {
    try {
      final data = await _client
          .from('items')
          .insert(item.toInsertMap())
          .select()
          .single();
      return ItemModel.fromMap(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      throw 'Failed to save item: ${e.message}';
    } catch (e) {
      throw 'Failed to save item: $e';
    }
  }

  /// Updates an existing item row by id and returns the server's version.
  Future<ItemModel> updateItem(ItemModel item) async {
    try {
      final data = await _client
          .from('items')
          .update(item.toInsertMap())
          .eq('id', item.id)
          .select()
          .single();
      return ItemModel.fromMap(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      throw 'Failed to update item: ${e.message}';
    } catch (e) {
      throw 'Failed to update item: $e';
    }
  }
}
