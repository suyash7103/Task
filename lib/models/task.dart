import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final Timestamp dueDate;
  final String priority;
  final bool isCompleted;
  final String userId;
  final Timestamp createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.userId,
    required this.createdAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] as Timestamp,
      priority: data['priority'] ?? 'low',
      isCompleted: data['isCompleted'] ?? false,
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'priority': priority,
      'isCompleted': isCompleted,
      'userId': userId,
      'createdAt': createdAt,
    };
  }

  Task copyWith({
    String? title,
    String? description,
    Timestamp? dueDate,
    String? priority,
    bool? isCompleted,
    String? userId,
    Timestamp? createdAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}