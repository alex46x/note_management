import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isPinned = false;

  bool get isEditMode => widget.note != null && widget.note!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController = TextEditingController(text: widget.note?.description ?? '');
    _tagsController = TextEditingController(text: widget.note?.tags.join(', ') ?? '');
    _isPinned = widget.note?.isPinned ?? false;

    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
    _tagsController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final originalTitle = widget.note?.title ?? '';
    final originalDescription = widget.note?.description ?? '';
    final originalTags = widget.note?.tags.join(', ') ?? '';
    final originalPinned = widget.note?.isPinned ?? false;
    
    final currentTitle = _titleController.text;
    final currentDescription = _descriptionController.text;
    final currentTags = _tagsController.text;

    final changed = currentTitle != originalTitle || 
        currentDescription != originalDescription || 
        currentTags != originalTags || 
        _isPinned != originalPinned;
    
    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _tagsController.removeListener(_onTextChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _isSaving = true;
    });

    try {
      if (isEditMode) {
        await _firestoreService.updateNote(
          widget.note!.id,
          _titleController.text,
          _descriptionController.text,
          tags,
          _isPinned,
        );
      } else {
        await _firestoreService.addNote(
          _titleController.text,
          _descriptionController.text,
          tags,
          _isPinned,
        );
      }

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Note updated successfully' : 'Note saved successfully'),
          backgroundColor: AppConstants.colorSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save note: $e'),
          backgroundColor: AppConstants.colorError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.colorError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Parse live tags from input text
    final tagList = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return PopScope(
      canPop: !_hasChanges && !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDarkMode ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
              size: 20,
            ),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            isEditMode ? 'Edit Note' : 'New Note',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned 
                    ? (isDarkMode ? AppConstants.darkPrimary : const Color(0xFF3B82F6)) 
                    : (isDarkMode ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary),
              ),
              tooltip: _isPinned ? 'Unpin note' : 'Pin to top',
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _onTextChanged();
                });
              },
            ),
            if (_hasChanges && !_isSaving)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.check_rounded, size: 26),
                  tooltip: isEditMode ? 'Update note' : 'Save note',
                  onPressed: _saveNote,
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.spaceMD),
                children: [
                  // Unified Paper Sheet/Canvas for notes input
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppConstants.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(
                        color: isDarkMode ? AppConstants.darkBorder : AppConstants.lightBorder,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Input Field
                        TextFormField(
                          controller: _titleController,
                          maxLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Note Title',
                            hintStyle: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.hintColor.withAlpha(100),
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spaceMD,
                              vertical: AppConstants.spaceMD,
                            ),
                            filled: false, // Override theme fill
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title cannot be empty';
                            }
                            return null;
                          },
                        ),
                        
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        
                        // Tags Input Field
                        TextFormField(
                          controller: _tagsController,
                          maxLines: 1,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add tags (comma separated: work, ideas, etc.)',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor.withAlpha(100),
                            ),
                            prefixIcon: Icon(
                              Icons.label_outline_rounded, 
                              size: 18,
                              color: isDarkMode ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spaceMD,
                              vertical: AppConstants.spaceSM,
                            ),
                            filled: false, // Override theme fill
                          ),
                        ),

                        // Live Tags Preview rendering Chips
                        if (tagList.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppConstants.spaceMD,
                              right: AppConstants.spaceMD,
                              bottom: AppConstants.spaceSM,
                            ),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: tagList.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? const Color(0xFF1E3A8A).withAlpha(100) 
                                        : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF3B82F6).withAlpha(60),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.tag_rounded,
                                        size: 11,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        tag,
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        const Divider(height: 1, indent: 16, endIndent: 16),
                        
                        // Formatting Toolbar Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: isDarkMode ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
                          child: Row(
                            children: [
                              _buildFormatButton(
                                icon: const Icon(Icons.format_bold_rounded),
                                tooltip: 'Bold',
                                onTap: () => _insertMarkup('**', '**'),
                              ),
                              _buildFormatButton(
                                icon: const Icon(Icons.format_italic_rounded),
                                tooltip: 'Italic',
                                onTap: () => _insertMarkup('*', '*'),
                              ),
                              _buildFormatButton(
                                icon: const Icon(Icons.code_rounded),
                                tooltip: 'Inline Code',
                                onTap: () => _insertMarkup('`', '`'),
                              ),
                              _buildFormatButton(
                                icon: const Icon(Icons.format_list_bulleted_rounded),
                                tooltip: 'Bullet List',
                                onTap: () => _insertMarkup('\n• ', ''),
                              ),
                              _buildFormatButton(
                                icon: const Icon(Icons.playlist_add_check_rounded),
                                tooltip: 'Todo Checkbox',
                                onTap: () => _insertMarkup('\n[ ] ', ''),
                              ),
                            ],
                          ),
                        ),
                        
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        
                        // Description Input Field
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: null,
                          minLines: 8,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: isDarkMode ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Start writing your note here...',
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.hintColor.withAlpha(100),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spaceMD,
                              vertical: AppConstants.spaceMD,
                            ),
                            filled: false, // Override theme fill
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading Overlay when saving
            if (_isSaving)
              Container(
                color: Colors.black.withAlpha(26),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
        
        // Premium centered gradient button in bottomNavigationBar
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMD),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)], // Royal Blue to Indigo
                ),
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                child: InkWell(
                  onTap: _isSaving ? null : _saveNote,
                  borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isEditMode ? 'Update Note' : 'Save Note',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatButton({required Widget icon, required String tooltip, required VoidCallback onTap}) {
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: Theme.of(context).brightness == Brightness.dark 
          ? AppConstants.darkTextSecondary 
          : AppConstants.lightTextSecondary,
    );
  }

  void _insertMarkup(String openTag, String closeTag) {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    
    final int start = selection.start;
    final int end = selection.end;
    
    String newText;
    int newCursorOffset;

    if (start < 0 || end < 0) {
      newText = text + openTag + closeTag;
      newCursorOffset = newText.length - closeTag.length;
    } else {
      final selectedText = text.substring(start, end);
      final replacement = openTag + selectedText + closeTag;
      newText = text.replaceRange(start, end, replacement);
      newCursorOffset = start + openTag.length + selectedText.length;
    }
    
    _descriptionController.text = newText;
    _descriptionController.selection = TextSelection.collapsed(offset: newCursorOffset);
    _onTextChanged();
  }
}
