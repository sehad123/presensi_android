import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddMahasiswaUser extends StatefulWidget {
  final String? userId; // ID of the user to edit, null for adding new
  final String? name;
  final String? nim;
  final String? email;
  final String? gender;
  final String? profileImageUrl;
  final String? semesterId;
  final String? classId;

  AddMahasiswaUser({
    this.userId,
    this.name,
    this.nim,
    this.email,
    this.gender,
    this.profileImageUrl,
    this.semesterId,
    this.classId,
  });

  @override
  _AddMahasiswaUserState createState() => _AddMahasiswaUserState();
}

class _AddMahasiswaUserState extends State<AddMahasiswaUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? _selectedSemester;
  String? _selectedClass;
  XFile? _profileImage;
  String? _name;
  String? _nim;
  String? _email;
  String? _gender;
  String? _password;

  List<String> _semesters = [];
  Map<String, String> _classes = {}; // Map class ID to class name

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _nim = widget.nim;
    _email = widget.email;
    _gender = widget.gender;
    _selectedSemester = widget.semesterId;
    _selectedClass = widget.classId;

    if (widget.userId == null) {
      _fetchSemesters();
    } else {
      _fetchSemesters().then((_) {
        _fetchClasses(_selectedSemester!);
      });
    }
  }

  Future<void> _fetchSemesters() async {
    var snapshot = await _firestore.collection('semester').get();
    setState(() {
      _semesters = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _fetchClasses(String semesterId) async {
    var snapshot = await _firestore
        .collection('class_semester')
        .where('semester_id', isEqualTo: semesterId)
        .get();

    var classIds =
        snapshot.docs.map((doc) => doc['class_id'] as String).toList();

    var classSnapshot = await _firestore
        .collection('kelas')
        .where(FieldPath.documentId, whereIn: classIds)
        .get();

    setState(() {
      _classes = {for (var doc in classSnapshot.docs) doc.id: doc['name']};
    });
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return widget.profileImageUrl;

    try {
      var file = File(_profileImage!.path);
      var storageRef = _storage
          .ref()
          .child('profile_images/${DateTime.now().toIso8601String()}');
      var uploadTask = storageRef.putFile(file);
      var snapshot = await uploadTask;
      var downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Failed to upload image: $e");
      return null;
    }
  }

  void _submitForm() async {
    if (_selectedSemester == null || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select semester and class'),
      ));
      return;
    }

    String? profileImageUrl = await _uploadProfileImage();

    try {
      if (widget.userId == null) {
        // Create user in Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );

        String userId = userCredential.user!.uid;

        // Add new user to Firestore
        await _firestore.collection('users').doc(userId).set({
          'id': userId,
          'nama': _name,
          'nim': _nim,
          'email': _email,
          'gender': _gender,
          'profile_img': profileImageUrl,
          'user_type': 3,
          'semester_id': _selectedSemester,
          'class_id': _selectedClass,
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });
      } else {
        // Update existing user in Firestore
        await _firestore.collection('users').doc(widget.userId).update({
          'nama': _name,
          'nim': _nim,
          'email': _email,
          'gender': _gender,
          'profile_img': profileImageUrl ?? widget.profileImageUrl,
          'user_type': 3,
          'semester_id': _selectedSemester,
          'class_id': _selectedClass,
          'updated_at': Timestamp.now(),
        });

        // Update email in Firebase Authentication
        if (_email != null) {
          User? currentUser = _auth.currentUser;
          if (currentUser != null) {
            await currentUser.updateEmail(_email!);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.userId == null
            ? 'User added successfully'
            : 'User updated successfully'),
      ));

      Navigator.pop(context);
    } catch (e) {
      print("Error ${widget.userId == null ? 'adding' : 'updating'} user: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Error ${widget.userId == null ? 'adding' : 'updating'} user'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId == null ? 'Add Mahasiswa' : 'Edit User'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
              controller: TextEditingController(text: _name),
              onChanged: (value) => _name = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'NIM'),
              controller: TextEditingController(text: _nim),
              onChanged: (value) => _nim = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              controller: TextEditingController(text: _email),
              onChanged: (value) => _email = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Gender'),
              controller: TextEditingController(text: _gender),
              onChanged: (value) => _gender = value,
            ),
            if (widget.userId == null) ...[
              TextField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => _password = value,
              ),
            ],
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                var image =
                    await _picker.pickImage(source: ImageSource.gallery);
                setState(() {
                  _profileImage = image;
                });
              },
              child: Text(_profileImage == null
                  ? 'Upload Profile Image'
                  : 'Change Profile Image'),
            ),
            SizedBox(height: 16.0),
            FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('semester').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                var semesters = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Select Semester'),
                  value: _selectedSemester,
                  items: semesters.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                      _fetchClasses(value!);
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Class'),
              value: _selectedClass,
              items: _classes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClass = value;
                });
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(widget.userId == null ? 'Add User' : 'Update User'),
            ),
          ],
        ),
      ),
    );
  }
}
