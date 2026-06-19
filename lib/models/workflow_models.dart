import 'package:flutter/material.dart';

enum RequestStatus {
  draft,
  awaitingDesign,
  proofReady,
  approved,
  printing,
  qualityCheck,
  outForDelivery,
  delivered,
}

enum OrderPriority { normal, rush, vip }

enum ProductionStage { design, prepress, printing, finishing, packing }

extension RequestStatusLabel on RequestStatus {
  static RequestStatus fromName(String? value) {
    return RequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RequestStatus.awaitingDesign,
    );
  }

  String get label {
    switch (this) {
      case RequestStatus.draft:
        return 'Draft';
      case RequestStatus.awaitingDesign:
        return 'Awaiting design';
      case RequestStatus.proofReady:
        return 'Proof ready';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.printing:
        return 'Printing';
      case RequestStatus.qualityCheck:
        return 'Quality check';
      case RequestStatus.outForDelivery:
        return 'Out for delivery';
      case RequestStatus.delivered:
        return 'Delivered';
    }
  }

  IconData get icon {
    switch (this) {
      case RequestStatus.draft:
        return Icons.edit_note;
      case RequestStatus.awaitingDesign:
        return Icons.design_services_outlined;
      case RequestStatus.proofReady:
        return Icons.preview_outlined;
      case RequestStatus.approved:
        return Icons.verified_outlined;
      case RequestStatus.printing:
        return Icons.print_outlined;
      case RequestStatus.qualityCheck:
        return Icons.fact_check_outlined;
      case RequestStatus.outForDelivery:
        return Icons.local_shipping_outlined;
      case RequestStatus.delivered:
        return Icons.done_all;
    }
  }
}

extension ProductionStageLabel on ProductionStage {
  static ProductionStage fromName(String? value) {
    return ProductionStage.values.firstWhere(
      (stage) => stage.name == value,
      orElse: () => ProductionStage.design,
    );
  }

  String get label {
    switch (this) {
      case ProductionStage.design:
        return 'Design';
      case ProductionStage.prepress:
        return 'Prepress';
      case ProductionStage.printing:
        return 'Printing';
      case ProductionStage.finishing:
        return 'Finishing';
      case ProductionStage.packing:
        return 'Packing';
    }
  }
}

extension OrderPriorityLabel on OrderPriority {
  static OrderPriority fromName(String? value) {
    return OrderPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => OrderPriority.normal,
    );
  }

  String get label {
    switch (this) {
      case OrderPriority.normal:
        return 'Normal';
      case OrderPriority.rush:
        return 'Rush';
      case OrderPriority.vip:
        return 'VIP';
    }
  }
}

class ProductOption {
  const ProductOption({
    required this.name,
    required this.basePrice,
    required this.materials,
    required this.sizes,
  });

  final String name;
  final double basePrice;
  final List<String> materials;
  final List<String> sizes;
}

class WorkflowOrder {
  const WorkflowOrder({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.product,
    required this.quantity,
    required this.material,
    required this.size,
    required this.colors,
    required this.designBrief,
    required this.status,
    required this.priority,
    required this.stage,
    required this.progress,
    required this.dueDate,
    required this.deliveryAddress,
    required this.total,
    required this.paid,
    required this.assignee,
  });

  final String id;
  final String customerName;
  final String phoneNumber;
  final String product;
  final int quantity;
  final String material;
  final String size;
  final String colors;
  final String designBrief;
  final RequestStatus status;
  final OrderPriority priority;
  final ProductionStage stage;
  final double progress;
  final DateTime dueDate;
  final String deliveryAddress;
  final double total;
  final double paid;
  final String assignee;

  double get balance => total - paid;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  factory WorkflowOrder.fromMap(Map<String, dynamic> map) {
    return WorkflowOrder(
      id: map['id']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      phoneNumber: map['phone_number']?.toString() ?? '',
      product: map['product']?.toString() ?? '',
      quantity: _toInt(map['quantity']),
      material: map['material']?.toString() ?? '',
      size: map['size']?.toString() ?? '',
      colors: map['colors']?.toString() ?? '',
      designBrief: map['design_brief']?.toString() ?? '',
      status: RequestStatusLabel.fromName(map['status']?.toString()),
      priority: OrderPriorityLabel.fromName(map['priority']?.toString()),
      stage: ProductionStageLabel.fromName(map['stage']?.toString()),
      progress: _toDouble(map['progress']),
      dueDate:
          DateTime.tryParse(map['due_date']?.toString() ?? '') ??
          DateTime.now(),
      deliveryAddress: map['delivery_address']?.toString() ?? '',
      total: _toDouble(map['total']),
      paid: _toDouble(map['paid']),
      assignee: map['assignee']?.toString() ?? 'Unassigned',
    );
  }

  Map<String, dynamic> toInsertMap({String? ownerId}) => {
    if (ownerId != null) 'owner_id': ownerId,
    'customer_name': customerName,
    'phone_number': phoneNumber,
    'product': product,
    'quantity': quantity,
    'material': material,
    'size': size,
    'colors': colors,
    'design_brief': designBrief,
    'status': status.name,
    'priority': priority.name,
    'stage': stage.name,
    'progress': progress,
    'due_date': dueDate.toIso8601String(),
    'delivery_address': deliveryAddress,
    'total': total,
    'paid': paid,
    'assignee': assignee,
  };

  WorkflowOrder copyWith({
    String? id,
    String? customerName,
    String? phoneNumber,
    String? product,
    int? quantity,
    String? material,
    String? size,
    String? colors,
    String? designBrief,
    RequestStatus? status,
    OrderPriority? priority,
    ProductionStage? stage,
    double? progress,
    DateTime? dueDate,
    String? deliveryAddress,
    double? total,
    double? paid,
    String? assignee,
  }) {
    return WorkflowOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      material: material ?? this.material,
      size: size ?? this.size,
      colors: colors ?? this.colors,
      designBrief: designBrief ?? this.designBrief,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      dueDate: dueDate ?? this.dueDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      assignee: assignee ?? this.assignee,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.name,
    required this.stock,
    required this.reorderPoint,
    required this.unit,
  });

  final String name;
  final double stock;
  final double reorderPoint;
  final String unit;

  bool get needsReorder => stock <= reorderPoint;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      name: map['name']?.toString() ?? '',
      stock: _toDouble(map['stock']),
      reorderPoint: _toDouble(map['reorder_point']),
      unit: map['unit']?.toString() ?? '',
    );
  }
}

class TeamMessage {
  const TeamMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isCustomer,
  });

  final String sender;
  final String text;
  final DateTime time;
  final bool isCustomer;

  factory TeamMessage.fromMap(Map<String, dynamic> map) {
    return TeamMessage(
      sender: map['sender']?.toString() ?? 'Team',
      text: map['text']?.toString() ?? '',
      time:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isCustomer: map['is_customer'] == true,
    );
  }
}
