import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreTestScreen extends StatelessWidget {
  const FirestoreTestScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('test_items');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Test')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _col.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No items yet. Tap + to add one.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, i) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final title = doc['title'] as String;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _col.doc(doc.id).delete(),
                child: ListTile(
                  title: Text(title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showItemDialog(context, docId: doc.id, existing: title),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showItemDialog(BuildContext context, {String? docId, String? existing}) {
    final controller = TextEditingController(text: existing);
    final isEdit = docId != null;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Item' : 'New Item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(context, controller, docId),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submit(context, controller, docId),
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _submit(
    BuildContext context,
    TextEditingController controller,
    String? docId,
  ) {
    final title = controller.text.trim();
    if (title.isEmpty) return;

    if (docId != null) {
      _col.doc(docId).update({'title': title});
    } else {
      _col.add({'title': title, 'createdAt': FieldValue.serverTimestamp()});
    }

    Navigator.pop(context);
  }
}
