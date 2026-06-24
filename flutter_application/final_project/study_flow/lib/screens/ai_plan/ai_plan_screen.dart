import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_flow/models/ai_plan_item.dart';
import 'package:study_flow/screens/ai_plan/ai_chat_screen.dart';
import 'package:study_flow/screens/ai_plan/done_plans_screen.dart';
import 'package:study_flow/services/location_service.dart';
import 'package:study_flow/services/notification_service.dart';

class AiPlanScreen extends StatelessWidget {
  const AiPlanScreen({super.key});

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
      body: Column(
        children: [
          // Sub-pages top navigation row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Completed list button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.assignment_turned_in_outlined, size: 18, color: Colors.green),
                  label: const Text('Marked as Done'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DonePlansScreen()),
                    );
                  },
                ),
                // AI Chat button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18, color: Colors.blue),
                  label: const Text('AI Chat'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiChatScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Timeline list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: col.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // 1. Map to models & filter active items in-memory
                final List<AiPlanItem> items = docs
                    .map((doc) => AiPlanItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .where((item) => !item.isCompleted)
                    .toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No active tasks on your timeline.'),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + to add your first study plan!',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // 2. Sort items chronologically
                items.sort(_comparePlanItems);

                // 3. Group by date header
                final grouped = _groupItemsByDate(items);

                // 4. Create lists for building
                final headers = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemCount: headers.length,
                  itemBuilder: (context, idx) {
                    final header = headers[idx];
                    final dayItems = grouped[header]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
                          child: Text(
                            header,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // List of items under this date
                        ...dayItems.map((item) {
                          return _AiPlanCard(
                            item: item,
                            onCheck: () => _checkItem(context, col, item),
                            onEdit: () => _showItemDialog(context, col, item),
                            onDelete: () => _confirmDelete(context, col, item),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final colRef = _col;
          if (colRef != null) {
            _showItemDialog(context, colRef);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  int _comparePlanItems(AiPlanItem a, AiPlanItem b) {
    final dateComparison = a.date.year.compareTo(b.date.year);
    if (dateComparison != 0) return dateComparison;

    final monthComparison = a.date.month.compareTo(b.date.month);
    if (monthComparison != 0) return monthComparison;

    final dayComparison = a.date.day.compareTo(b.date.day);
    if (dayComparison != 0) return dayComparison;

    if (a.time != null && b.time != null) {
      final hourComparison = a.time!.hour.compareTo(b.time!.hour);
      if (hourComparison != 0) return hourComparison;
      return a.time!.minute.compareTo(b.time!.minute);
    } else if (a.time != null) {
      return -1;
    } else if (b.time != null) {
      return 1;
    }
    return 0;
  }

  Map<String, List<AiPlanItem>> _groupItemsByDate(List<AiPlanItem> items) {
    final Map<String, List<AiPlanItem>> groups = {};
    for (final item in items) {
      final headerStr = _formatDateHeader(item.date);
      if (!groups.containsKey(headerStr)) {
        groups[headerStr] = [];
      }
      groups[headerStr]!.add(item);
    }
    return groups;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    if (difference == 0) {
      return 'Today, $weekday ${date.day} $month';
    } else if (difference == 1) {
      return 'Tomorrow, $weekday ${date.day} $month';
    } else if (difference == -1) {
      return 'Yesterday, $weekday ${date.day} $month';
    } else {
      return '$weekday, ${date.day} $month ${date.year}';
    }
  }

  void _checkItem(BuildContext context, CollectionReference col, AiPlanItem item) async {
    if (item.id == null) return;
    await col.doc(item.id).update({'isCompleted': true});

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked "${item.title}" as completed!'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await col.doc(item.id).update({'isCompleted': false});
            },
          ),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, CollectionReference col, AiPlanItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (item.id != null) {
                await col.doc(item.id).delete();
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              await NotificationService.instance
                  .show('Item deleted', '"${item.title}" was removed from your AI Plan.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(
    BuildContext context,
    CollectionReference col, [
    AiPlanItem? existingItem,
  ]) {
    final isEdit = existingItem != null;

    final titleController = TextEditingController(text: existingItem?.title);
    final descController = TextEditingController(text: existingItem?.description);
    
    DateTime selectedDate = existingItem?.date ?? DateTime.now();
    TimeOfDay? selectedTime = existingItem?.time;
    String selectedType = existingItem?.type ?? 'general';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Item' : 'New Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Type dropdown
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General Task (Blue)')),
                        DropdownMenuItem(value: 'deadline', child: Text('Deadline (Yellow)')),
                        DropdownMenuItem(value: 'event', child: Text('Event (Red)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    // Date picker field
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: const Text('Pick'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Time picker field
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedTime != null
                                ? 'Time: ${selectedTime!.format(context)}'
                                : 'Time: All Day',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (selectedTime != null)
                          TextButton(
                            onPressed: () {
                              setState(() => selectedTime = null);
                            },
                            child: const Text('Clear'),
                          ),
                        OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
                            );
                            if (time != null) {
                              setState(() => selectedTime = time);
                            }
                          },
                          child: const Text('Pick'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    Navigator.pop(dialogCtx);

                    if (isEdit) {
                      await col.doc(existingItem.id).update({
                        'title': title,
                        'description': descController.text.trim(),
                        'type': selectedType,
                        'date': selectedDate.toIso8601String(),
                        'time': selectedTime != null
                            ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                            : null,
                      });
                      await NotificationService.instance.show(
                        'Item updated',
                        '"$title" was updated in your AI Plan.',
                      );
                    } else {
                      final location = await LocationService.instance.getCurrentLocationName();
                      await col.add({
                        'title': title,
                        'description': descController.text.trim(),
                        'type': selectedType,
                        'date': selectedDate.toIso8601String(),
                        'time': selectedTime != null
                            ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                            : null,
                        'location': location,
                        'isCompleted': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      await NotificationService.instance.show(
                        'Item added',
                        '"$title" was added to your timeline.',
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AiPlanCard extends StatefulWidget {
  final AiPlanItem item;
  final VoidCallback onCheck;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AiPlanCard({
    required this.item,
    required this.onCheck,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AiPlanCard> createState() => _AiPlanCardState();
}

class _AiPlanCardState extends State<_AiPlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    Color cardBgColor = Colors.grey.shade100;
    Color accentColor = Colors.grey.shade800;
    Color textColor = Colors.black87;

    if (widget.item.type == 'deadline') {
      cardBgColor = const Color(0xFFFFF9C4); // pastel yellow
      accentColor = const Color(0xFFE5A93C); // dark yellow/amber
    } else if (widget.item.type == 'event') {
      cardBgColor = const Color(0xFFFFCDD2); // pastel red
      accentColor = const Color(0xFFC62828); // dark red
    } else if (widget.item.type == 'general') {
      cardBgColor = const Color(0xFFBBDEFB); // pastel blue
      accentColor = const Color(0xFF0D47A1); // dark blue
    }

    final timeStr = widget.item.time != null
        ? '${widget.item.time!.hour.toString().padLeft(2, '0')}:${widget.item.time!.minute.toString().padLeft(2, '0')}'
        : 'All Day';

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.item.description.isNotEmpty) {
              setState(() {
                _expanded = !_expanded;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Checkbox
                    GestureDetector(
                      onTap: widget.onCheck,
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.circle,
                          size: 0, // Not checked, empty
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and Time details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 14, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                              if (widget.item.location.isNotEmpty && widget.item.location != LocationService.unknown) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.location_on_outlined, size: 14, color: accentColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.item.location,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: accentColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit and Delete icons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.edit_outlined, size: 18, color: accentColor),
                          onPressed: widget.onEdit,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.delete_outline, size: 18, color: accentColor),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
                // Description (collapsible/expandable)
                if (widget.item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 38.0),
                    child: Text(
                      widget.item.description,
                      maxLines: _expanded ? null : 1,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


