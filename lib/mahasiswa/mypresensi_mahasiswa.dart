import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RekapPresensiMahasiswa extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RekapPresensiMahasiswa({Key? key, required this.userData})
      : super(key: key);

  @override
  _RekapPresensiMahasiswaState createState() => _RekapPresensiMahasiswaState();
}

class _RekapPresensiMahasiswaState extends State<RekapPresensiMahasiswa> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('presensi')
        .where('student_id', isEqualTo: widget.userData['user_id']);

    return query.snapshots();
  }

  void resetFilters() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Presensi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getJadwalStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No data found'));
                  }

                  var jadwalList = snapshot.data!.docs
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
                          leading: jadwal['face_image'] != null
                              ? Image.network(
                                  jadwal['face_image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.person, size: 50),
                          title: Text(
                            '${jadwal['student_id'] ?? 'Unknown Student'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Kelas: ${jadwal['class_id'] ?? 'Unknown Class'}'),
                              Text(
                                  'Mata Kuliah: ${jadwal['matkul_id'] ?? 'Unknown Matkul'}'),
                              Text(
                                  'Status: ${jadwal['presensi_type'] ?? 'Unknown Type'}'),
                              if (dateTime != null)
                                Text(
                                    'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
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
