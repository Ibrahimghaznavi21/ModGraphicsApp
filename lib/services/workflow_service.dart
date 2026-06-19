import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workflow_models.dart';

class WorkflowService {
  WorkflowService._();

  static final WorkflowService instance = WorkflowService._();

  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw 'Please sign in again.';
    return id;
  }

  Future<List<WorkflowOrder>> fetchOrders() async {
    try {
      final data = await _client
          .from('workflow_orders')
          .select()
          .eq('owner_id', _userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((row) => WorkflowOrder.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (e) {
      throw 'Failed to load orders: ${e.message}';
    }
  }

  Future<List<InventoryItem>> fetchInventory() async {
    try {
      final data = await _client
          .from('inventory_items')
          .select()
          .eq('owner_id', _userId)
          .order('name');
      return (data as List)
          .map((row) => InventoryItem.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (e) {
      throw 'Failed to load inventory: ${e.message}';
    }
  }

  Future<List<TeamMessage>> fetchMessages() async {
    try {
      final data = await _client
          .from('team_messages')
          .select()
          .eq('owner_id', _userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((row) => TeamMessage.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (e) {
      throw 'Failed to load messages: ${e.message}';
    }
  }

  Future<WorkflowOrder> insertOrder(WorkflowOrder order) async {
    try {
      final data = await _client
          .from('workflow_orders')
          .insert(order.toInsertMap(ownerId: _userId)..remove('id'))
          .select()
          .single();
      return WorkflowOrder.fromMap(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      throw 'Failed to save order: ${e.message}';
    }
  }

  Future<WorkflowOrder> updateOrder(WorkflowOrder order) async {
    try {
      final data = await _client
          .from('workflow_orders')
          .update(order.toInsertMap()..remove('owner_id'))
          .eq('id', order.id)
          .eq('owner_id', _userId)
          .select()
          .single();
      return WorkflowOrder.fromMap(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      throw 'Failed to update order: ${e.message}';
    }
  }

  Future<TeamMessage> insertMessage(String text) async {
    try {
      final data = await _client
          .from('team_messages')
          .insert({
            'owner_id': _userId,
            'sender': 'Admin',
            'text': text,
            'is_customer': false,
          })
          .select()
          .single();
      return TeamMessage.fromMap(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      throw 'Failed to send message: ${e.message}';
    }
  }
}
