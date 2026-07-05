import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../utils/constants.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPinToggle;

  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onPinToggle,
  });

  /// Dynamic icon and background color generation based on note content keywords
  Widget _buildLeadIcon(String title, String description, bool isDarkMode) {
    final text = '$title $description'.toLowerCase();
    
    IconData iconData = Icons.description_rounded;
    Color iconColor = isDarkMode ? const Color(0xFF818CF8) : const Color(0xFF4F46E5); // Indigo default
    
    if (text.contains('design') || text.contains('tutorial') || text.contains('youtube') || text.contains('ux') || text.contains('ui')) {
      iconData = Icons.play_arrow_rounded;
      iconColor = isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626); // Red
    } else if (text.contains('marketing') || text.contains('digital') || text.contains('mic') || text.contains('voice') || text.contains('audio')) {
      iconData = Icons.mic_rounded;
      iconColor = isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB); // Blue
    } else if (text.contains('progress') || text.contains('profession') || text.contains('file') || text.contains('folder') || text.contains('upload')) {
      iconData = Icons.folder_rounded;
      iconColor = isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706); // Amber
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withAlpha(25) : Colors.black.withAlpha(12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  List<TextSpan> _parseMarkdown(String text, TextStyle baseStyle, bool isDarkMode) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'(\*\*\*[^\*]+\*\*\*)|(\*\*[^\*]+\*\*)|(\*[^\*]+\*)|(\`[^\`]+\`)');
    
    int start = 0;
    for (final Match match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: baseStyle));
      }
      
      final String matchText = match.group(0)!;
      if (matchText.startsWith('***') && matchText.endsWith('***') && matchText.length > 6) {
        spans.add(TextSpan(
          text: matchText.substring(3, matchText.length - 3),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      } else if (matchText.startsWith('**') && matchText.endsWith('**') && matchText.length > 4) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchText.startsWith('*') && matchText.endsWith('*') && matchText.length > 2) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchText.startsWith('`') && matchText.endsWith('`') && matchText.length > 2) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (baseStyle.fontSize ?? 13) - 1,
            backgroundColor: isDarkMode ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20),
            color: isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
          ),
        ));
      } else {
        spans.add(TextSpan(text: matchText, style: baseStyle));
      }
      start = match.end;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Format timestamp: e.g., "30 jun, 2026 • 10:28 AM"
    final formattedDate = DateFormat('d MMM, yyyy • hh:mm a').format(note.createdAt).toLowerCase();

    // Check if the note was created in the last 2 hours
    final isNew = DateTime.now().difference(note.createdAt).inHours < 2;

    final cardBgColor = AppConstants.getNoteColor(note.id, isDarkMode);
    final borderColor = isDarkMode 
        ? (cardBgColor == const Color(0xFF16171F) ? AppConstants.darkBorder : cardBgColor.withAlpha(120))
        : (cardBgColor == const Color(0xFFFFFFFF) ? AppConstants.lightBorder : cardBgColor.withAlpha(150));

    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final bodyColor = isDarkMode ? Colors.white70 : const Color(0xFF334155);
    final dateColor = isDarkMode ? Colors.white54 : const Color(0xFF64748B);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spaceMD),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: isDarkMode ? [] : [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceMD,
                  vertical: AppConstants.spaceMD,
                ),
                child: Row(
                  children: [
                    // Dynamic Left Icon
                    _buildLeadIcon(note.title, note.description, isDarkMode),
                    const SizedBox(width: AppConstants.spaceMD),
                    
                    // Middle content: Title, Description Preview & DateTime
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.title.isNotEmpty ? note.title : 'Untitled',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (note.isPinned)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: Icon(
                                    Icons.push_pin_rounded,
                                    size: 14,
                                    color: isDarkMode ? AppConstants.darkPrimary : const Color(0xFF3B82F6),
                                  ),
                                ),
                            ],
                          ),
                          if (note.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: _parseMarkdown(
                                  note.description,
                                  theme.textTheme.bodyMedium?.copyWith(
                                    color: bodyColor,
                                    fontSize: 13,
                                    height: 1.4,
                                  ) ?? const TextStyle(),
                                  isDarkMode,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: dateColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right Action Menu Button
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDarkMode ? AppConstants.darkBorder : AppConstants.lightBorder,
                          width: 1.0,
                        ),
                      ),
                      color: isDarkMode ? AppConstants.darkSurface : Colors.white,
                      elevation: 4,
                      offset: const Offset(0, 36),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDarkMode ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onTap();
                        } else if (value == 'delete') {
                          onDelete();
                        } else if (value == 'pin') {
                          onPinToggle();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, 
                                  size: 18, 
                                  color: isDarkMode ? AppConstants.darkTextSecondary : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  note.isPinned ? 'Unpin note' : 'Pin to top',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined, 
                                  size: 18, 
                                  color: isDarkMode ? AppConstants.darkTextSecondary : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded, 
                                  size: 18, 
                                  color: AppConstants.colorError,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: AppConstants.colorError,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // "NEW" Badge overlay in the top-right corner
        if (isNew)
          Positioned(
            top: -2,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF059669).withAlpha(150) : const Color(0xFF34D399).withAlpha(100),
                  width: 1,
                ),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF065F46),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
