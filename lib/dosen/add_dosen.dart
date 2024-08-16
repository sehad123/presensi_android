import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddDosenUser extends StatefulWidget {
  final String? userId; // ID of the user to edit, null for adding new
  final String? name;
  final String? nim;
  final String? email;
  final String? gender;
  final String? profileImageUrl;

  AddDosenUser({
    this.userId,
    this.name,
    this.nim,
    this.email,
    this.gender,
    this.profileImageUrl,
  });

  @override
  _AddDosenUserState createState() => _AddDosenUserState();
}

class _AddDosenUserState extends State<AddDosenUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  XFile? _profileImage;
  String? _name;
  String? _nim;
  String? _email;
  String? _gender;
  String? _password;

  final List<String> _genderOptions = ['Laki-Laki', 'Perempuan'];

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _nim = widget.nim;
    _email = widget.email;
    _gender = widget.gender;
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
    String? profileImageUrl = await _uploadProfileImage();

    try {
      if (widget.userId == null) {
        // Create new user in Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );

        // Add new user to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'nama': _name,
          'nim': _nim,
          'email': _email,
          'gender': _gender,
          'profile_img': profileImageUrl,
          'user_type': 2,
          'semester_id': null, // Set to null
          'class_id': null, // Set to null
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
          'user_type': 2,
          'semester_id': null, // Set to null
          'class_id': null, // Set to null
          'updated_at': Timestamp.now(),
        });

        // Update email and password in Firebase Authentication if needed
        if (_email != widget.email || _password != null) {
          User? user = _auth.currentUser;
          if (user != null) {
            if (_email != widget.email) {
              await user.updateEmail(_email!);
            }
            if (_password != null) {
              await user.updatePassword(_password!);
            }
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
        title: Text(widget.userId == null ? 'Add Dosen' : 'Edit Dosen'),
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
              decoration: InputDecoration(labelText: 'NIP'),
              controller: TextEditingController(text: _nim),
              onChanged: (value) => _nim = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              controller: TextEditingController(text: _email),
              onChanged: (value) => _email = value,
            ),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(labelText: 'Gender'),
              items: _genderOptions.map((gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _gender = value;
              }),
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
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(widget.userId == null ? 'Add Dosen' : 'Update Dosen'),
            ),
          ],
        ),
      ),
    );
  }
}
