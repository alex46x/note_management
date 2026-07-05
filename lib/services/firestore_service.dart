import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Reference to the 'notes' collection
  CollectionReference get _notesCollection => _firestore.collection('notes');

  /// Stream all notes in real-time.
  /// Ordered by 'createdAt' descending (newest first).
  Stream<List<Note>> getNotesStream() {
    return _notesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return Note.fromMap(data, doc.id);
          }).toList();
        });
  }

  /// Add a new note to Firestore.
  Future<DocumentReference> addNote(String title, String description, [List<String> tags = const []]) async {
    final newNote = Note(
      id: '',
      title: title.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
      tags: tags,
    );
    
    return await _notesCollection.add(newNote.toMap());
  }

  /// Update an existing note in Firestore.
  Future<void> updateNote(String id, String title, String description, [List<String> tags = const []]) async {
    return await _notesCollection.doc(id).update({
      'title': title.trim(),
      'description': description.trim(),
      'createdAt': Timestamp.fromDate(DateTime.now()), // Or keep original createdAt, but usually update timestamp is fine. The model has createdAt, so updating it shows modified date.
      'tags': tags,
    });
  }

  /// Delete a note from Firestore.
  Future<void> deleteNote(String id) async {
    return await _notesCollection.doc(id).delete();
  }

  /// Helper: Add a specific note back (used for Swipe-to-Delete Undo feature).
  Future<void> restoreNote(Note note) async {
    return await _notesCollection.doc(note.id).set(note.toMap());
  }
}
