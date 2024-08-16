import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  ProfilePage({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Akun Saya'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar profil di tengah-tengah
            if (userData['profile_img'] != null &&
                userData['profile_img'].isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 50, // Ukuran lingkaran
                  backgroundImage: NetworkImage(userData['profile_img']),
                  backgroundColor: Colors.transparent,
                ),
              )
            else
              Center(
                child: CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              ),
            SizedBox(height: 16),
            // Identitas pengguna
            if (userData['nama'] != null)
              buildInfoRow('Nama', userData['nama']),
            if (userData['gender'] != null)
              buildInfoRow('Jenis Kelamin', userData['gender']),
            if (userData['email'] != null)
              buildInfoRow('Email', userData['email']),
            if (userData['class_id'] != null)
              buildInfoRow('Kelas', userData['class_id']),
            if (userData['semester_id'] != null)
              buildInfoRow('Semester', userData['semester_id']),
            SizedBox(height: 1),
            // Tombol Logout
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context)
                      .pushReplacementNamed('/login'); // Adjust route as needed
                } catch (e) {
                  print("Error logging out: $e");
                }
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(value ?? ''),
        ],
      ),
    );
  }
}
