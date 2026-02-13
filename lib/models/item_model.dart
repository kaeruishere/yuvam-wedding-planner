import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String status; // 'to_buy', 'bought'
  final String notes;
  final double cost;
  final String supplier;
  final String? location;
  final String? creatorId; // Added creatorId
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DocumentAttachment> documents;

  Item({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.status = 'to_buy',
    this.notes = '',
    this.cost = 0.0,
    this.supplier = '',
    this.location,
    this.creatorId,
    this.createdAt,
    this.updatedAt,
    this.documents = const [],
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      status: data['status'] ?? 'to_buy',
      notes: data['notes'] ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      supplier: data['supplier'] ?? '',
      location: data['location'],
      creatorId: data['creatorId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      documents: (data['documents']?['list'] as List<dynamic>?)
              ?.map((d) => DocumentAttachment.fromMap(d))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'status': status,
      'notes': notes,
      'cost': cost,
      'supplier': supplier,
      'location': location,
      'creatorId': creatorId, // Crucial for notifications
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'documents': {
        'list': documents.map((d) => d.toMap()).toList(),
      },
    };
  }

  Item copyWith({
    String? name,
    String? category,
    int? quantity,
    String? status,
    String? notes,
    double? cost,
    String? supplier,
    String? location,
    String? creatorId, // Added creatorId to copyWith
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documents: documents ?? this.documents,
    );
  }
}

class DocumentAttachment {
  final String id;
  final String name;
  final String link;
  final String type;
  final DateTime? createdAt;

  DocumentAttachment({
    required this.id,
    required this.name,
    required this.link,
    this.type = 'link',
    this.createdAt,
  });

  factory DocumentAttachment.fromMap(Map<String, dynamic> map) {
    return DocumentAttachment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      link: map['link'] ?? '',
      type: map['type'] ?? 'link',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'link': link,
      'type': type,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
