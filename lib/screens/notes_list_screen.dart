import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../services/firestore_service.dart';
import '../widgets/note_tile.dart';
import '../utils/constants.dart';
import 'add_edit_note_screen.dart';

// Simple theme provider to allow toggle between light and dark mode
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String? _selectedTag;
  bool _isGroupedByTag = false;
  String _sortBy = 'date';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Delete note and show SnackBar with undo option
  Future<void> _deleteNoteWithUndo(Note note, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    // Delete operation
    await _firestoreService.deleteNote(note.id);
    
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Note "${note.title}" deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: theme.colorScheme.primaryContainer,
          onPressed: () async {
            // Restore note
            await _firestoreService.restoreNote(note);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
        (themeProvider.themeMode == ThemeMode.system && 
         MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              themeProvider.toggleTheme(!isDark);
            },
          ),
          // Layout Toggle (Grid/List)
          IconButton(
            icon: Icon(
              _isGroupedByTag ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
            ),
            tooltip: _isGroupedByTag ? 'Show List View' : 'Group by Tag (Grid)',
            onPressed: () {
              setState(() {
                _isGroupedByTag = !_isGroupedByTag;
              });
            },
          ),
          // Settings gear icon as in the mockup
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
            ),
            tooltip: 'Settings',
            onPressed: () {
              // Open Settings Sheet or show info
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notes app settings - designed by Antigravity'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mockup Title: "My notes" in large, bold format below App Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My notes',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 34,
                        color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organize your thoughts & tags',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                StreamBuilder<List<Note>>(
                  stream: _firestoreService.getNotesStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '$count notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppConstants.darkPrimary : AppConstants.lightPrimary,
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceMD),

          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
            child: Row(
              children: [
                // Search Input Field
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppConstants.darkTextSecondary.withAlpha(150) : AppConstants.lightTextSecondary.withAlpha(150),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppConstants.darkSurface : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                          borderSide: BorderSide(
                            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                          borderSide: BorderSide(
                            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                          borderSide: BorderSide(
                            color: isDark ? AppConstants.darkPrimary : AppConstants.lightPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Mockup Tune/Filter button
                Container(
                  margin: const EdgeInsets.only(left: AppConstants.spaceSM),
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                    border: Border.all(
                      color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      color: isDark ? AppConstants.darkPrimary : AppConstants.lightPrimary,
                      size: 20,
                    ),
                    tooltip: 'Sort options',
                    onPressed: () {
                      _showSortOptionsBottomSheet(context, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceSM),

          // Stream of Notes containing dynamically computed tags and list
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _firestoreService.getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spaceLG),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: AppConstants.spaceMD),
                          Text(
                            'Something went wrong!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spaceSM),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allNotes = snapshot.data ?? [];

                // Extract all unique tags dynamically from notes
                final allTags = allNotes
                    .expand((note) => note.tags)
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toSet()
                    .toList();

                // Filter notes by search query AND selected tag
                final filteredNotes = allNotes.where((note) {
                  final matchesQuery = note.title.toLowerCase().contains(_searchQuery) ||
                      note.description.toLowerCase().contains(_searchQuery);
                  final matchesTag = _selectedTag == null || note.tags.contains(_selectedTag);
                  return matchesQuery && matchesTag;
                }).toList();

                // Sort: Pinned notes at the top, then sort by date or title
                filteredNotes.sort((a, b) {
                  if (a.isPinned && !b.isPinned) return -1;
                  if (!a.isPinned && b.isPinned) return 1;
                  
                  if (_sortBy == 'title') {
                    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
                  } else {
                    return b.createdAt.compareTo(a.createdAt);
                  }
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Tags/Badges Row matching mockup
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spaceMD,
                        vertical: AppConstants.spaceSM,
                      ),
                      child: Row(
                        children: [
                          // Create Tag Chip
                          InkWell(
                            onTap: () {
                              _showCreateTagDialog(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E3A8A).withAlpha(80) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF3B82F6).withAlpha(120) : const Color(0xFF3B82F6).withAlpha(100),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add, 
                                    size: 14, 
                                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Create tag',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppConstants.spaceSM),
                          
                          // All Tags Chip
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTag = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: _selectedTag == null
                                    ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)])
                                    : null,
                                color: _selectedTag == null
                                    ? null
                                    : (isDark ? AppConstants.darkSurface : AppConstants.lightBg),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedTag == null
                                      ? Colors.transparent
                                      : (isDark ? AppConstants.darkBorder : AppConstants.lightBorder),
                                ),
                                boxShadow: _selectedTag == null
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF3B82F6).withAlpha(60),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'All tags',
                                style: TextStyle(
                                  color: _selectedTag == null
                                      ? Colors.white
                                      : (isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          // Render Dynamic Tags
                          ...allTags.map((tag) {
                            final isSelected = _selectedTag == tag;
                            return Padding(
                              padding: const EdgeInsets.only(left: AppConstants.spaceSM),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTag = isSelected ? null : tag;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)])
                                        : null,
                                    color: isSelected
                                        ? null
                                        : (isDark ? AppConstants.darkSurface : Colors.white),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : (isDark ? AppConstants.darkBorder : AppConstants.lightBorder),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF3B82F6).withAlpha(60),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceSM),
                    
                    // Filtered Notes List or Grid Folder View
                    Expanded(
                      child: filteredNotes.isEmpty
                          ? _buildEmptyState(
                              context,
                              theme,
                              isSearching: _searchQuery.isNotEmpty || _selectedTag != null,
                            )
                          : _isGroupedByTag
                              ? _buildGroupedGridView(context, filteredNotes, isDark)
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
                                  itemCount: filteredNotes.length,
                                  itemBuilder: (context, index) {
                                    final note = filteredNotes[index];
                                    
                                    return Dismissible(
                                  key: Key(note.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await _showDeleteConfirmationDialog(context, note);
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: AppConstants.spaceLG),
                                    margin: const EdgeInsets.only(bottom: AppConstants.spaceMD),
                                    decoration: BoxDecoration(
                                      color: AppConstants.colorError,
                                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                                    ),
                                    child: const Icon(
                                      Icons.delete_sweep_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  onDismissed: (direction) => _deleteNoteWithUndo(note, context),
                                  child: NoteTile(
                                    note: note,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEditNoteScreen(note: note),
                                        ),
                                      );
                                    },
                                    onDelete: () async {
                                      final confirmed = await _showDeleteConfirmationDialog(context, note);
                                      if (confirmed == true && context.mounted) {
                                        _deleteNoteWithUndo(note, context);
                                      }
                                    },
                                    onPinToggle: () async {
                                      await _firestoreService.togglePin(note.id, note.isPinned);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      // Royal Blue FAB Capsule aligned center float at bottom
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)], // Royal Blue to Indigo
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withAlpha(100),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditNoteScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(26),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Note',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, Note note) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? const Color(0xFFEBEBF5).withAlpha(153) : const Color(0xFF3C3C43).withAlpha(153);
    final borderColor = isDark ? const Color(0x388E8E93) : const Color(0x3C3C3C43);
    final cancelColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    const deleteColor = Color(0xFFFF3B30); // iOS Red

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      Text(
                        'Delete this note?',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will be removed permanently. This action can\'t be undone.',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.5,
                  color: borderColor,
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context, false),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                        ),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: cancelColor,
                              fontSize: 17,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.5,
                      height: 48,
                      color: borderColor,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(14),
                        ),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: deleteColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter tag name (e.g. Work, Ideas)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final tagName = controller.text.trim();
              if (tagName.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditNoteScreen(
                      note: Note(
                        id: '',
                        title: '',
                        description: '',
                        createdAt: DateTime.now(),
                        tags: [tagName],
                      ),
                    ),
                  ),
                );
              }
            },
            child: const Text('Create & Write Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, {required bool isSearching}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spaceLG),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.note_alt_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLG),
            Text(
              isSearching ? 'No match found' : 'Your workspace is empty',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spaceSM),
            Text(
              isSearching
                  ? 'Try searching with different keywords or check spelling.'
                  : 'Capture ideas, organize tasks, and sync in real-time. Tap the button below to write your first note!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: AppConstants.spaceLG),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditNoteScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create First Note'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceLG,
                    vertical: AppConstants.spaceMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedGridView(BuildContext context, List<Note> notes, bool isDark) {
    final Map<String, List<Note>> grouped = {};
    final List<Note> untagged = [];
    
    for (final note in notes) {
      if (note.tags.isEmpty) {
        untagged.add(note);
      } else {
        for (final tag in note.tags) {
          final trimmed = tag.trim();
          if (trimmed.isNotEmpty) {
            grouped.putIfAbsent(trimmed, () => []).add(note);
          }
        }
      }
    }

    final groupKeys = grouped.keys.toList()..sort();
    if (untagged.isNotEmpty) {
      groupKeys.add('Uncategorized');
    }

    if (groupKeys.isEmpty) {
      return _buildEmptyState(context, Theme.of(context), isSearching: true);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMD),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final key = groupKeys[index];
        final List<Note> groupNotes = key == 'Uncategorized' ? untagged : (grouped[key] ?? []);
        return TagGroupCard(
          tag: key,
          notes: groupNotes,
          isDark: isDark,
          onTagTap: () {
            setState(() {
              if (key == 'Uncategorized') {
                _selectedTag = null;
              } else {
                _selectedTag = key;
              }
              _isGroupedByTag = false; // Go to list view for this tag
            });
          },
          onNoteTap: (note) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditNoteScreen(note: note),
              ),
            );
          },
        );
      },
    );
  }

  void _showSortOptionsBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppConstants.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sort Notes By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSortOption(
                      context: context,
                      title: 'Date Created (Newest)',
                      value: 'date',
                      icon: Icons.calendar_today_rounded,
                      isDark: isDark,
                      setSheetState: setSheetState,
                    ),
                    _buildSortOption(
                      context: context,
                      title: 'Alphabetical (Title)',
                      value: 'title',
                      icon: Icons.sort_by_alpha_rounded,
                      isDark: isDark,
                      setSheetState: setSheetState,
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    required StateSetter setSheetState,
  }) {
    final isSelected = _sortBy == value;
    final primaryColor = isDark ? AppConstants.darkPrimary : AppConstants.lightPrimary;
    
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        setSheetState(() {});
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: primaryColor.withAlpha(80), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : (isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class TagGroupCard extends StatelessWidget {
  final String tag;
  final List<Note> notes;
  final bool isDark;
  final VoidCallback onTagTap;
  final Function(Note) onNoteTap;

  const TagGroupCard({
    super.key,
    required this.tag,
    required this.notes,
    required this.isDark,
    required this.onTagTap,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF334155);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16171F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          width: 1.0,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTagTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Folder Icon, Tag Title & Count
                Row(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 18,
                      color: isDark ? AppConstants.darkPrimary : AppConstants.lightPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${notes.length} >',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Bullet points of notes
                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notes.length > 3 ? 3 : notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return GestureDetector(
                        onTap: () => onNoteTap(note),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppConstants.darkPrimary.withAlpha(120) : AppConstants.lightPrimary.withAlpha(150),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  note.title.isNotEmpty ? note.title : 'Untitled',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtitleColor,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
