import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanningItemType {
  task,
  item,
  service,
}

extension PlanningItemTypeX on PlanningItemType {
  String get asString {
    switch (this) {
      case PlanningItemType.task:
        return 'task';
      case PlanningItemType.item:
        return 'item';
      case PlanningItemType.service:
        return 'service';
    }
  }

  static PlanningItemType fromString(String? value) {
    switch (value) {
      case 'task':
        return PlanningItemType.task;
      case 'item':
        return PlanningItemType.item;
      case 'service':
        return PlanningItemType.service;
      default:
        return PlanningItemType.task;
    }
  }
}

class PlanningItem {
  final String id;
  final PlanningItemType type;
  final String title;

  // Task-specific
  final bool? isDone;

  // Item-specific
  final bool? isBought;
  final double? price;
  final String? category;
  final bool? hasExpenseEntry;

  // Service-specific
  final double? totalPrice;
  final double? depositPaid;
  final double? remainingDebt;
  final List<Map<String, dynamic>>? installments;

  PlanningItem({
    required this.id,
    required this.type,
    required this.title,
    this.isDone,
    this.isBought,
    this.price,
    this.category,
    this.hasExpenseEntry,
    this.totalPrice,
    this.depositPaid,
    this.remainingDebt,
    this.installments,
  });

  factory PlanningItem.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PlanningItem(
      id: doc.id,
      type: PlanningItemTypeX.fromString(data['type'] as String?),
      title: (data['title'] as String?) ?? '',
      isDone: data['isDone'] as bool?,
      isBought: data['isBought'] as bool?,
      price: _toDouble(data['price']),
      category: data['category'] as String?,
      hasExpenseEntry: data['hasExpenseEntry'] as bool?,
      totalPrice: _toDouble(data['totalPrice']),
      depositPaid: _toDouble(data['depositPaid']),
      remainingDebt: _toDouble(data['remainingDebt']),
      installments: (data['installments'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.asString,
      'title': title,
      if (isDone != null) 'isDone': isDone,
      if (isBought != null) 'isBought': isBought,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (hasExpenseEntry != null) 'hasExpenseEntry': hasExpenseEntry,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (depositPaid != null) 'depositPaid': depositPaid,
      if (remainingDebt != null) 'remainingDebt': remainingDebt,
      if (installments != null) 'installments': installments,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

