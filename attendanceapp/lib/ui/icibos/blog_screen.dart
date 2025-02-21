import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  _BlogScreenState createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedCategory;

  void _saveNote({String? docId}) async {
    String userId = _auth.currentUser?.uid ?? "guest";
    String title = _titleController.text;
    String content = _contentController.text;

    if (title.isEmpty || content.isEmpty) return;

    if (docId == null) {
      // Simpan catatan baru
      await _firestore.collection('notes').add({
        'userId': userId,
        'title': title,
        'content': content,
        'category': _selectedCategory ?? "Umum",
        'pinned': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Update catatan yang sudah ada
      await _firestore.collection('notes').doc(docId).update({
        'title': title,
        'content': content,
        'category': _selectedCategory ?? "Umum",
      });
    }

    _titleController.clear();
    _contentController.clear();
  }

  void _deleteNote(String docId) async {
    await _firestore.collection('notes').doc(docId).delete();
  }

  void _togglePin(String docId, bool currentPinStatus) async {
    await _firestore.collection('notes').doc(docId).update({
      'pinned': !currentPinStatus,
    });
  }

  void _editNote(String docId, String title, String content, String category) {
    _titleController.text = title;
    _contentController.text = content;
    _selectedCategory = category;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Catatan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController),
              TextField(controller: _contentController, maxLines: 5),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _saveNote(docId: docId);
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Catatan & Blog")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Judul")),
                TextField(controller: _contentController, decoration: const InputDecoration(labelText: "Isi Catatan"), maxLines: 5),
                DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text("Pilih Kategori"),
                  items: ["Umum", "Pekerjaan", "Pribadi", "Belajar"]
                      .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _saveNote, child: const Text("Simpan")),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: "Cari Catatan..."),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('notes')
                  .orderBy('pinned', descending: true) // Menampilkan yang dipin di atas
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var notes = snapshot.data!.docs.where((note) {
                  String title = note['title'].toLowerCase();
                  String searchText = _searchController.text.toLowerCase();
                  return title.contains(searchText);
                }).toList();

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    var note = notes[index];

                    return ListTile(
                      title: Text(note['title']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note['content']),
                          Text("Kategori: ${note['category']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              note['pinned'] ? Icons.push_pin : Icons.push_pin_outlined,
                              color: note['pinned'] ? Colors.orange : Colors.grey,
                            ),
                            onPressed: () => _togglePin(note.id, note['pinned']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editNote(note.id, note['title'], note['content'], note['category']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNote(note.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
