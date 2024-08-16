import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presensi_api/menu_page.dart';

class DashboardPage extends StatelessWidget {
  Future<int> _getCount(String collection,
      [Map<String, dynamic>? query]) async {
    QuerySnapshot snapshot;
    if (query != null) {
      snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where(query.keys.first, isEqualTo: query.values.first)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance.collection(collection).get();
    }
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildCard(
              title: 'Total Kelas',
              future: _getCount('kelas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SemesterClassPage()),
                );
              },
            ),
            _buildCard(
              title: 'Total Dosen',
              future: _getCount('users', {'user_type': 2}),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DosenPage()),
                );
              },
            ),
            _buildCard(
              title: 'Total Mahasiswa',
              future: _getCount('users', {'user_type': 3}),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MahasiswaPage()),
                );
              },
            ),
            _buildCard(
              title: 'Total Mata Kuliah',
              future: _getCount('matkul'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MatkulClassPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required Future<int> future,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: FutureBuilder<int>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.data}',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
