import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presensi_api/mahasiswa/presensi_mahasiswa.dart';

class RekapPresensiDosen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RekapPresensiDosen({Key? key, required this.userData})
      : super(key: key);

  @override
  _RekapPresensiDosenState createState() => _RekapPresensiDosenState();
}

class _RekapPresensiDosenState extends State<RekapPresensiDosen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedTanggal;
  String? selectedMatkul;

  List<String> tanggalList = [];
  Map<String, String> matkulMap = {};

  String? currentClassId;

  @override
  void initState() {
    super.initState();
    currentClassId = widget.userData['class_id'];
    _fetchTanggal();
    _fetchMatkul();
  }

  Future<void> _fetchTanggal() async {
    var snapshot = await _firestore.collection('jadwal').get();
    setState(() {
      tanggalList = snapshot.docs
          .map((doc) => (doc['tanggal'] as Timestamp).toDate())
          .map((date) => DateFormat('yyyy-MM-dd').format(date))
          .toSet()
          .toList();
    });
  }

  Future<void> _fetchMatkul() async {
    var snapshot = await _firestore.collection('matkul').get();
    setState(() {
      matkulMap = {for (var doc in snapshot.docs) doc.id: doc['name']};
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('presensi');

    if (selectedTanggal != null) {
      DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(selectedTanggal!);
      query =
          query.where('tanggal', isEqualTo: Timestamp.fromDate(selectedDate));
    }
    if (selectedMatkul != null) {
      query = query.where('matkul_id', isEqualTo: selectedMatkul);
    }
    query = query.where('student_id', isEqualTo: widget.userData['user_id']);

    return query.snapshots();
  }

  void resetFilters() {
    setState(() {
      selectedTanggal = null;
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
                value: selectedTanggal,
                onChanged: (value) {
                  setState(() {
                    selectedTanggal = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                ),
                items: tanggalList
                    .map((tanggal) => DropdownMenuItem<String>(
                          value: tanggal,
                          child: Text(tanggal),
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

                  if (matkulMap.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

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
                            matkulMap[jadwal['matkul_id']] ?? 'Unknown Matkul',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Kelas : ${jadwal['class_id'] ?? 'Unknown Class'}'),
                              Text(
                                  'Bukti Wajah: ${jadwal['face_image'] ?? 'Not Available'}'),
                              Text(
                                  'Status : ${jadwal['presensi_type'] ?? 'Unknown Type'}'),
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
