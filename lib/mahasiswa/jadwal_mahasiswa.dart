import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presensi_api/mahasiswa/presensi_mahasiswa.dart';
import 'package:presensi_api/menu_page.dart'; // Import paket intl

class JadwalMahasiswastis extends StatefulWidget {
  final Map<String, dynamic> userData;

  const JadwalMahasiswastis({Key? key, required this.userData})
      : super(key: key);

  @override
  _JadwalMahasiswastisState createState() => _JadwalMahasiswastisState();
}

class _JadwalMahasiswastisState extends State<JadwalMahasiswastis> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedHari;
  String? selectedMatkul;

  List<String> hariList = [];
  Map<String, String> matkulMap = {};

  String? currentClassId;
  String? currentSemesterId;

  @override
  void initState() {
    super.initState();
    currentClassId = widget.userData['class_id'];
    currentSemesterId = widget.userData['semester_id'];
    _fetchHari();
    _fetchMatkul();
  }

  Future<void> _fetchHari() async {
    var snapshot = await _firestore.collection('hari').get();
    setState(() {
      hariList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> _fetchMatkul() async {
    if (currentClassId != null && currentSemesterId != null) {
      var snapshot = await _firestore
          .collection('matkul_class')
          .where('class_id', isEqualTo: currentClassId)
          .where('semester_id', isEqualTo: currentSemesterId)
          .get();

      var matkulIds = snapshot.docs
          .map((doc) => doc['matkul_id'] as List)
          .expand((x) => x)
          .toList();

      var matkulSnapshot = await _firestore
          .collection('matkul')
          .where(FieldPath.documentId, whereIn: matkulIds)
          .get();

      setState(() {
        matkulMap = {for (var doc in matkulSnapshot.docs) doc.id: doc['name']};
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('jadwal');

    if (selectedHari != null) {
      query = query.where('hari_id', isEqualTo: selectedHari);
    }
    if (selectedMatkul != null) {
      query = query.where('matkul_id', isEqualTo: selectedMatkul);
    }
    query = query.where('class_id', isEqualTo: currentClassId);
    query = query.where('semester_id', isEqualTo: currentSemesterId);

    return query.snapshots();
  }

  void resetFilters() {
    setState(() {
      selectedHari = null;
      selectedMatkul = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Jadwal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DropdownButtonFormField<String>(
                value: selectedHari,
                onChanged: (value) {
                  setState(() {
                    selectedHari = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Hari',
                ),
                items: hariList
                    .map((hari) => DropdownMenuItem<String>(
                          value: hari,
                          child: Text(hari),
                        ))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DropdownButtonFormField<String>(
                value: selectedMatkul,
                onChanged: (value) {
                  setState(() {
                    selectedMatkul = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Mata Kuliah',
                ),
                items: matkulMap.entries
                    .map((entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
              ),
            ),
            ElevatedButton(
              onPressed: resetFilters,
              child: Text('Reset Filter'),
            ),
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
                          title: Text(
                            jadwal['matkul_id'] ?? 'Unknown Matkul',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Hari: ${jadwal['hari_id'] ?? 'Unknown Hari'}'),
                              Text(
                                  'Kelas: ${jadwal['class_id'] ?? 'Unknown Kelas'}'),
                              Text(
                                  'Jam: ${jadwal['jam_mulai']}:${jadwal['menit_mulai']} - ${jadwal['jam_akhir']}:${jadwal['menit_akhir']}'),
                              Text(
                                  'Status: ${jadwal['status'] ?? 'Unknown Status'}'),
                              if (jadwal['status'] == 'Offline' &&
                                  jadwal['room_number'] != null)
                                Text('Ruangan: ${jadwal['room_number']}'),
                              if (jadwal['status'] == 'Online' &&
                                  jadwal['link'] != null)
                                Text('Link Zoom: ${jadwal['link']}'),
                              if (dateTime != null)
                                Text(
                                    'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PresensiMahasiswa(
                                  jadwalData:
                                      jadwal, // Kirim data jadwal yang dipilih
                                  userData: widget
                                      .userData, // Kirim data pengguna yang login
                                ),
                              ),
                            );
                          },
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
