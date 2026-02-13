import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String provider; // Originally 'category', now provider/company name
  final double totalCost;
  final double paidAmount;
  final String status; // 'pending', 'paid', 'partial'
  final DateTime? paymentDate;
  final String notes;
  final String contactPhone;
  final String contactEmail;
  final String contactWebsite;
  final String location;
  final List<DocumentAttachment> documents;
  final List<PaymentRecord> payments; // If you have payment history
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.name,
    this.provider = '',
    this.totalCost = 0.0,
    this.paidAmount = 0.0,
    this.status = 'pending',
    this.paymentDate,
    this.notes = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.contactWebsite = '',
    this.location = '',
    this.documents = const [],
    this.payments = const [],
    this.createdAt,
    this.updatedAt,
  });

  double get remainingAmount => totalCost - paidAmount;

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      provider: data['provider'] ?? '',
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactWebsite: data['contactWebsite'] ?? '',
      location: data['location'] ?? '',
      documents: (data['documents']?['list'] as List<dynamic>?)
              ?.map((d) => DocumentAttachment.fromMap(d))
              .toList() ??
          [],
      payments: (data['payments'] as List<dynamic>?)
              ?.map((p) => PaymentRecord.fromMap(p))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'provider': provider,
      'totalCost': totalCost,
      'paidAmount': paidAmount,
      'status': status,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'notes': notes,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'contactWebsite': contactWebsite,
      'location': location,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  Service copyWith({
    String? name,
    String? provider,
    double? totalCost,
    double? paidAmount,
    String? status,
    DateTime? paymentDate,
    String? notes,
    String? contactPhone,
    String? contactEmail,
    String? contactWebsite,
    String? location,
    List<DocumentAttachment>? documents,
    List<PaymentRecord>? payments,
  }) {
    return Service(
      id: id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      totalCost: totalCost ?? this.totalCost,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactWebsite: contactWebsite ?? this.contactWebsite,
      location: location ?? this.location,
      documents: documents ?? this.documents,
      payments: payments ?? this.payments,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class DocumentAttachment {
  final String id;
  final String name;
  final String link;
  final String type; // 'file', 'link'
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
}

class PaymentRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      note: map['note'] ?? '',
    );
  }
}
