  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:lucide_icons/lucide_icons.dart';
  import 'package:sahayak/theme.dart';
  import 'package:timeago/timeago.dart' as timeago;

  class CommunityFeedScreen extends StatefulWidget {
    const CommunityFeedScreen({super.key});

    @override
    State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
  }

  class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
    bool _isSearching = false;
    String _searchQuery = '';
    final TextEditingController _searchController = TextEditingController();

    @override
    void dispose() {
      _searchController.dispose();
      super.dispose();
    }

    void _showCreatePostSheet(BuildContext context) {
      final TextEditingController contentController = TextEditingController();
      String selectedType = 'Update';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final isCritical = selectedType == 'Medical' || selectedType == 'Emergency';
              
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('New Broadcast', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        const SizedBox(height: 24),
                        
                        // Type Selection
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTypeChip('Update', selectedType, (v) => setSheetState(() => selectedType = v)),
                              _buildTypeChip('Warning', selectedType, (v) => setSheetState(() => selectedType = v)),
                              _buildTypeChip('Medical', selectedType, (v) => setSheetState(() => selectedType = v)),
                              _buildTypeChip('Emergency', selectedType, (v) => setSheetState(() => selectedType = v)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Content Input
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.5 : 1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isCritical ? AppTheme.danger.withValues(alpha: 0.3) : Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                          ),
                          child: TextField(
                            controller: contentController,
                            maxLines: 4,
                            maxLength: 280,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'What is happening right now?',
                              hintStyle: const TextStyle(color: AppTheme.textMuted),
                              border: InputBorder.none,
                              counterStyle: const TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              final text = contentController.text.trim();
                              if (text.isEmpty) return;
                              
                              Navigator.pop(ctx);
                              
                              final user = FirebaseAuth.instance.currentUser;
                              
                              try {
                                await FirebaseFirestore.instance.collection('broadcasts').add({
                                  'userId': user?.uid ?? 'anonymous',
                                  'userName': user?.displayName ?? 'Anonymous User',
                                  'type': selectedType,
                                  'content': text,
                                  'critical': isCritical,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast posted successfully!')));
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCritical ? AppTheme.danger : AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: isCritical ? 8 : 2,
                              shadowColor: isCritical ? AppTheme.danger : AppTheme.primary,
                            ),
                            child: const Text('Broadcast to Mesh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            }
          );
        }
      );
    }

    Widget _buildTypeChip(String label, String currentVal, Function(String) onSelect) {
      final isSelected = label == currentVal;
      final isCritical = label == 'Medical' || label == 'Emergency';
      final activeColor = isCritical ? AppTheme.danger : AppTheme.primary;
      
      return GestureDetector(
        onTap: () => onSelect(label),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? activeColor : AppTheme.textMuted.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search community...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase());
                  },
                )
              : const Text('Community Feed'),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('broadcasts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final docs = snapshot.data?.docs ?? [];
            
            final filteredDocs = docs.where((doc) {
              if (_searchQuery.isEmpty) return true;
              final data = doc.data() as Map<String, dynamic>;
              final content = (data['content'] as String? ?? '').toLowerCase();
              final type = (data['type'] as String? ?? '').toLowerCase();
              final user = (data['userName'] as String? ?? '').toLowerCase();
              return content.contains(_searchQuery) || type.contains(_searchQuery) || user.contains(_searchQuery);
            }).toList();

            if (filteredDocs.isEmpty) {
              return const Center(
                child: Text('No community broadcasts found.', style: TextStyle(color: AppTheme.textMuted)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final data = filteredDocs[index].data() as Map<String, dynamic>;
                if (index == filteredDocs.length - 1) {
                  return Column(
                    children: [
                      _buildPostCard(data),
                      const SizedBox(height: 100), // spacing for floating nav
                    ],
                  );
                }
                return _buildPostCard(data);
              },
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF00FFD1), Color(0xFF00BFAF)]),
              boxShadow: [
                BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              onPressed: () => _showCreatePostSheet(context),
              elevation: 0,
              child: const Icon(LucideIcons.plus, size: 28),
            ),
          ),
        ),
      );
    }

    Widget _buildPostCard(Map<String, dynamic> data) {
      final isCritical = data['critical'] as bool? ?? false;
      final type = data['type'] as String? ?? 'Update';
      final content = data['content'] as String? ?? '';
      final userName = data['userName'] as String? ?? 'Anonymous User';
      
      final timestamp = data['timestamp'] as Timestamp?;
      final timeStr = timestamp != null ? timeago.format(timestamp.toDate()) : 'Just now';

      Color getAccentColor() {
        switch (type.toLowerCase()) {
          case 'medical': return Colors.cyanAccent;
          case 'emergency': return AppTheme.danger;
          case 'warning': return Colors.orangeAccent;
          case 'update': default: return AppTheme.primary;
        }
      }
      final accentColor = getAccentColor();
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.6 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: isCritical ? 0.4 : 0.1),
            width: 1.5,
          ),
          boxShadow: [
            if (isCritical) BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 0),
            if (!isDark && !isCritical) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, spreadRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.2), 
                        accentColor.withValues(alpha: 0.05)
                      ]
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCritical ? LucideIcons.alertTriangle : LucideIcons.radio,
                        color: accentColor,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.2
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  child: Icon(LucideIcons.user, size: 16, color: accentColor),
                ),
                const SizedBox(width: 12),
                Text(
                  userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
