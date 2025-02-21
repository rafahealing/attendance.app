import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedCategory;

  void _deleteHistory(String docId) async {
    await _firestore.collection('notes').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Catatan")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text("Filter Berdasarkan Kategori"),
              items: ["Semua", "Umum", "Pekerjaan", "Pribadi", "Belajar"]
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('notes')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var notes = snapshot.data!.docs;

                if (_selectedCategory != null && _selectedCategory != "Semua") {
                  notes = notes.where((note) => note['category'] == _selectedCategory).toList();
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    var note = notes[index];

                    return ListTile(
                      title: Text(note['title']),
                      subtitle: Text("Kategori: ${note['category']}"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(note['title']),
                              content: Text(note['content']),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Tutup"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deleteHistory(note.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
