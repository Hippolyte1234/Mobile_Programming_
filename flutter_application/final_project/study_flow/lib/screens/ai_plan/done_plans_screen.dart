import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_flow/models/ai_plan_item.dart';
import 'package:study_flow/services/location_service.dart';
import 'package:study_flow/services/notification_service.dart';

class DonePlansScreen extends StatelessWidget {
  const DonePlansScreen({super.key});

  CollectionReference<Map<String, dynamic>>? get _col {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_plans');
  }

  @override
  Widget build(BuildContext context) {
    final col = _col;
    if (col == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marked as Done'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Map and filter completed items in-memory
          final List<AiPlanItem> items = docs
              .map((doc) => AiPlanItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((item) => item.isCompleted)
              .toList();

          // Sort completed items by createdAt descending
          items.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.now();
            final bTime = b.createdAt ?? DateTime.now();
            return bTime.compareTo(aTime);
          });

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade50,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.done_all_rounded,
                        size: 64,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'All Caught Up!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Any study plan or task you mark as completed on your timeline will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade600, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: Icon(Icons.arrow_back_rounded, size: 18, color: Colors.blue.shade700),
                      label: Text(
                        'Return to Timeline',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = items[i];

              Color cardBgColor = Colors.grey.shade100;
              Color accentColor = Colors.grey.shade600;

              // Use pastel/faded version of original type colors
              if (item.type == 'deadline') {
                cardBgColor = const Color(0xFFFFFDE7); // very light yellow
                accentColor = const Color(0xFFF57F17);
              } else if (item.type == 'event') {
                cardBgColor = const Color(0xFFFFEBEE); // very light red
                accentColor = const Color(0xFFC62828);
              } else if (item.type == 'general') {
                cardBgColor = const Color(0xFFE3F2FD); // very light blue
                accentColor = const Color(0xFF0D47A1);
              }

              // format date & time for subtitle
              final timeStr = item.time != null
                  ? '${item.time!.hour.toString().padLeft(2, '0')}:${item.time!.minute.toString().padLeft(2, '0')}'
                  : '';
              final dateStr = '${item.date.day}/${item.date.month}/${item.date.year}';
              final timeAndDate = timeStr.isNotEmpty ? '$timeStr on $dateStr' : dateStr;

              return Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Checklist circular checkbox
                      GestureDetector(
                        onTap: () => _uncheckItem(context, item),
                        child: Icon(
                          Icons.check_circle,
                          color: accentColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Core details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  timeAndDate,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            if (item.location.isNotEmpty && item.location != LocationService.unknown) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.location,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Permanently',
                        onPressed: () => _confirmDelete(context, item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _uncheckItem(BuildContext context, AiPlanItem item) async {
    final col = _col;
    if (col == null || item.id == null) return;

    await col.doc(item.id).update({'isCompleted': false});
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored "${item.title}" to timeline'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await col.doc(item.id).update({'isCompleted': true});
            },
          ),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, AiPlanItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text('Are you sure you want to permanently delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final col = _col;
              if (col != null && item.id != null) {
                await col.doc(item.id).delete();
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              await NotificationService.instance.show(
                'Item permanently deleted',
                '"${item.title}" was removed from your completed items list.',
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
