import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<String> tags;
  final bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.tags,
    this.isPinned = false,
  });

  /// Factory constructor to create a [Note] from a Firestore document map.
  /// Handles type safety and fallback cases gracefully.
  factory Note.fromMap(Map<String, dynamic> map, String id) {
    final rawCreatedAt = map['createdAt'];
    DateTime parsedDate;
    
    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedDate = rawCreatedAt;
    } else {
      parsedDate = DateTime.now();
    }

    return Note(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: parsedDate,
      tags: List<String>.from(map['tags'] ?? []),
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }

  /// Converts the [Note] instance to a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
      'isPinned': isPinned,
    };
  }

  /// Copy constructor for easy duplication or editing.
  Note copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    List<String>? tags,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
