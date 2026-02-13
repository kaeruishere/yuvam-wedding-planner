class WeddingEvent {
  final String id;
  final String title;
  final DateTime date;
  final bool isActive;

  WeddingEvent({
    required this.id,
    required this.title,
    required this.date,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'isActive': isActive,
    };
  }
  
  factory WeddingEvent.fromMap(Map<String, dynamic> map) {
    return WeddingEvent(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      isActive: map['isActive'],
    );
  }
}