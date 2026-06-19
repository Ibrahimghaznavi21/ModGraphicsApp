import 'package:flutter/foundation.dart';

import '../models/workflow_models.dart';
import '../services/workflow_service.dart';

class WorkflowProvider extends ChangeNotifier {
  WorkflowProvider({WorkflowService? service})
    : _service = service ?? WorkflowService.instance;

  final WorkflowService _service;

  final List<ProductOption> _products = const [
    ProductOption(
      name: 'Business cards',
      basePrice: 3500,
      materials: ['Matte card', 'Gloss card', 'Textured card'],
      sizes: ['Standard', 'Square', 'Custom'],
    ),
    ProductOption(
      name: 'Packaging labels',
      basePrice: 5200,
      materials: ['Vinyl', 'Kraft paper', 'Transparent film'],
      sizes: ['2 x 2 in', '3 x 4 in', 'Custom'],
    ),
    ProductOption(
      name: 'Banners',
      basePrice: 8500,
      materials: ['Flex', 'Canvas', 'Mesh'],
      sizes: ['3 x 6 ft', '4 x 8 ft', 'Custom'],
    ),
    ProductOption(
      name: 'T-shirts',
      basePrice: 1200,
      materials: ['Cotton', 'Dry fit', 'Polo'],
      sizes: ['S-XL', 'Mixed sizes', 'Custom'],
    ),
  ];
  List<WorkflowOrder> _orders = [];
  List<InventoryItem> _inventory = [];
  List<TeamMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ProductOption> get products => List.unmodifiable(_products);
  List<WorkflowOrder> get orders => List.unmodifiable(_orders);
  List<InventoryItem> get inventory => List.unmodifiable(_inventory);
  List<TeamMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchOrders(),
        _service.fetchInventory(),
        _service.fetchMessages(),
      ]);
      _orders = results[0] as List<WorkflowOrder>;
      _inventory = results[1] as List<InventoryItem>;
      _messages = results[2] as List<TeamMessage>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<WorkflowOrder> get activeOrders =>
      _orders.where((o) => o.status != RequestStatus.delivered).toList();

  List<WorkflowOrder> get deliveryQueue =>
      _orders.where((o) => o.status == RequestStatus.outForDelivery).toList();

  int get pendingDesigns => _orders
      .where(
        (o) =>
            o.status == RequestStatus.awaitingDesign ||
            o.status == RequestStatus.proofReady,
      )
      .length;

  int get inProduction => _orders
      .where(
        (o) =>
            o.status == RequestStatus.approved ||
            o.status == RequestStatus.printing ||
            o.status == RequestStatus.qualityCheck,
      )
      .length;

  double get receivables =>
      _orders.fold<double>(0, (sum, order) => sum + order.balance);

  List<WorkflowOrder> ordersForStage(ProductionStage stage) =>
      _orders.where((o) => o.stage == stage).toList();

  Future<void> createOrder({
    required String customerName,
    required String phoneNumber,
    required ProductOption product,
    required int quantity,
    required String material,
    required String size,
    required String colors,
    required String designBrief,
    required String deliveryAddress,
  }) async {
    final nextNumber = 1049 + _orders.length;
    final total = product.basePrice + (quantity * product.basePrice * 0.08);
    final order = WorkflowOrder(
      id: 'ORD-$nextNumber',
      customerName: customerName,
      phoneNumber: phoneNumber,
      product: product.name,
      quantity: quantity,
      material: material,
      size: size,
      colors: colors,
      designBrief: designBrief,
      status: RequestStatus.awaitingDesign,
      priority: OrderPriority.normal,
      stage: ProductionStage.design,
      progress: 0.08,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      deliveryAddress: deliveryAddress,
      total: total,
      paid: 0,
      assignee: 'Unassigned',
    );
    final saved = await _service.insertOrder(order);
    _orders = [saved, ..._orders];
    notifyListeners();
  }

  Future<void> advanceOrder(String id) async {
    final index = _orders.indexWhere((order) => order.id == id);
    if (index == -1) return;
    final order = _orders[index];
    final next = _nextStatus(order.status);
    final updated = order.copyWith(
      status: next,
      stage: _stageForStatus(next),
      progress: (_progressForStatus(next)).clamp(0, 1),
    );
    final saved = await _service.updateOrder(updated);
    _orders = List<WorkflowOrder>.from(_orders)..[index] = saved;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final saved = await _service.insertMessage(trimmed);
    _messages = [saved, ..._messages];
    notifyListeners();
  }

  RequestStatus _nextStatus(RequestStatus current) {
    switch (current) {
      case RequestStatus.draft:
        return RequestStatus.awaitingDesign;
      case RequestStatus.awaitingDesign:
        return RequestStatus.proofReady;
      case RequestStatus.proofReady:
        return RequestStatus.approved;
      case RequestStatus.approved:
        return RequestStatus.printing;
      case RequestStatus.printing:
        return RequestStatus.qualityCheck;
      case RequestStatus.qualityCheck:
        return RequestStatus.outForDelivery;
      case RequestStatus.outForDelivery:
      case RequestStatus.delivered:
        return RequestStatus.delivered;
    }
  }

  ProductionStage _stageForStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
      case RequestStatus.awaitingDesign:
      case RequestStatus.proofReady:
        return ProductionStage.design;
      case RequestStatus.approved:
        return ProductionStage.prepress;
      case RequestStatus.printing:
        return ProductionStage.printing;
      case RequestStatus.qualityCheck:
        return ProductionStage.finishing;
      case RequestStatus.outForDelivery:
      case RequestStatus.delivered:
        return ProductionStage.packing;
    }
  }

  double _progressForStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return 0.02;
      case RequestStatus.awaitingDesign:
        return 0.12;
      case RequestStatus.proofReady:
        return 0.26;
      case RequestStatus.approved:
        return 0.4;
      case RequestStatus.printing:
        return 0.62;
      case RequestStatus.qualityCheck:
        return 0.78;
      case RequestStatus.outForDelivery:
        return 0.92;
      case RequestStatus.delivered:
        return 1;
    }
  }
}
