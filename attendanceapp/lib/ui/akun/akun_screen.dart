import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _image;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // TODO: Upload image to Firebase Storage and get URL
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Akun Saya")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
                child: _image == null && _imageUrl == null
                    ? Icon(Icons.camera_alt, size: 50)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            Text(user?.email ?? "No Email", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            StreamBuilder(
              stream: _firestore.collection("activity_logs").where("userId", isEqualTo: user?.uid).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text("Tidak ada riwayat aktivitas.");
                }
                return Expanded(
                  child: ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return ListTile(
                        title: Text(doc["activity"]),
                        subtitle: Text(doc["timestamp"].toDate().toString()),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
