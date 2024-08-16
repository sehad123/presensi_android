import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RekapPresensiMahasiswaFiltered extends StatefulWidget {
  const RekapPresensiMahasiswaFiltered({Key? key}) : super(key: key);

  @override
  _RekapPresensiMahasiswaFilteredState createState() =>
      _RekapPresensiMahasiswaFilteredState();
}

class _RekapPresensiMahasiswaFilteredState
    extends State<RekapPresensiMahasiswaFiltered> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? selectedTanggal;
  String? selectedMatkul;
  String? selectedStudent;
  String? selectedClass;

  Stream<QuerySnapshot<Map<String, dynamic>>> _getPresensiStream() {
    Query<Map<String, dynamic>> query =
        _firestore.collection('presensi').where('dosen_id', isEqualTo: null);

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kolom Pencarian
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getPresensiStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var jadwalList = snapshot.data?.docs
                          .map((doc) => {'id': doc.id, ...doc.data()})
                          .toList() ??
                      [];

                  return ListView.builder(
                    itemCount: jadwalList.length,
                    itemBuilder: (context, index) {
                      var jadwal = jadwalList[index];

                      DateTime? dateTime;
                      if (jadwal['tanggal'] != null) {
                        dateTime = (jadwal['tanggal'] as Timestamp).toDate();
                      }

                      return Card(
                        child: ListTile(
                          contentPadding: EdgeInsets.all(8.0),
                          title: Row(
                            children: [
                              // Menampilkan gambar wajah
                              jadwal['face_image'] != null
                                  ? Image.network(
                                      jadwal['face_image'],
                                      width: 50, // Lebar gambar
                                      height: 50, // Tinggi gambar
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey,
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    ),
                              SizedBox(width: 10),
                              // Menampilkan informasi lainnya
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama: ${jadwal['student_id'] ?? 'Unknown Student'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Kelas: ${jadwal['class_id'] ?? 'Unknown Class'}',
                                    ),
                                    Text(
                                      'Mata Kuliah: ${jadwal['matkul_id'] ?? 'Unknown Matkul'}',
                                    ),
                                    Text(
                                      'Status: ${jadwal['presensi_type'] ?? 'Unknown Type'}',
                                    ),
                                    if (dateTime != null)
                                      Text(
                                        'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}',
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
