import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import paket intl
import 'package:presensi_api/edit_jadwal.dart';
import 'package:presensi_api/jadwal.dart';

class ListJadwal extends StatefulWidget {
  @override
  _ListJadwalState createState() => _ListJadwalState();
}

class _ListJadwalState extends State<ListJadwal> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedHari;
  String? selectedSemester;
  String? selectedKelas;
  String? selectedMatkul;

  List<String> hariList = [];
  List<String> semesterList = [];
  Map<String, String> kelasMap = {};
  Map<String, String> matkulMap = {};

  @override
  void initState() {
    super.initState();
    _fetchHari();
    _fetchSemester();
  }

  Future<void> _fetchHari() async {
    var snapshot = await _firestore.collection('hari').get();
    setState(() {
      hariList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> _fetchSemester() async {
    var snapshot = await _firestore.collection('semester').get();
    setState(() {
      semesterList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _fetchKelas(String semesterId) async {
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
      kelasMap = {for (var doc in classSnapshot.docs) doc.id: doc['name']};
    });
  }

  Future<void> _fetchMatkul(String classId) async {
    var snapshot = await _firestore
        .collection('matkul_class')
        .where('class_id', isEqualTo: classId)
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _getJadwalStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('jadwal');

    // Build the query dynamically based on provided filters
    if (selectedHari != null) {
      query = query.where('hari_id', isEqualTo: selectedHari);
    }
    if (selectedSemester != null) {
      query = query.where('semester_id', isEqualTo: selectedSemester);
    }
    if (selectedKelas != null) {
      query = query.where('class_id', isEqualTo: selectedKelas);
    }
    if (selectedMatkul != null) {
      query = query.where('matkul_id', isEqualTo: selectedMatkul);
    }

    return query.snapshots();
  }

  void filterJadwalList() {
    // This method is no longer needed since StreamBuilder handles filtering
  }

  void resetFilters() {
    setState(() {
      selectedHari = null;
      selectedSemester = null;
      selectedKelas = null;
      selectedMatkul = null;
      kelasMap.clear();
      matkulMap.clear();
    });
    // No need to call fetchJadwalList() here
  }

  void deleteJadwal(String docId) async {
    await _firestore.collection('jadwal').doc(docId).delete();
    // No need to call fetchJadwalList() here
  }

  void editJadwal(String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditJadwal(docId: docId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedHari,
                    onChanged: (value) {
                      setState(() {
                        selectedHari = value;
                      });
                      // No need to call filterJadwalList()
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
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSemester,
                    onChanged: (value) {
                      setState(() {
                        selectedSemester = value;
                        selectedKelas = null;
                        selectedMatkul = null;
                        _fetchKelas(value!);
                      });
                      // No need to call filterJadwalList()
                    },
                    decoration: InputDecoration(
                      labelText: 'Semester',
                    ),
                    items: semesterList
                        .map((semesterId) => DropdownMenuItem<String>(
                              value: semesterId,
                              child: Text(semesterId),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedKelas,
                    onChanged: (value) {
                      setState(() {
                        selectedKelas = value;
                        selectedMatkul = null;
                        _fetchMatkul(value!);
                      });
                      // No need to call filterJadwalList()
                    },
                    decoration: InputDecoration(
                      labelText: 'Kelas',
                    ),
                    items: kelasMap.entries
                        .map((entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMatkul,
                    onChanged: (value) {
                      setState(() {
                        selectedMatkul = value;
                      });
                      // No need to call filterJadwalList()
                    },
                    decoration: InputDecoration(
                      labelText: 'Matkul',
                    ),
                    items: matkulMap.entries
                        .map((entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
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

                      // Parse and format the date
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
                              fontWeight:
                                  FontWeight.bold, // Bold font for title
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Hari: ${jadwal['hari_id'] ?? 'Unknown Hari'}'),
                              Text(
                                  'Kelas: ${jadwal['class_id'] ?? 'Unknown Hari'}'),
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
                              Text(
                                  '${jadwal['semester_id'] ?? 'Unknown Semester'}'),
                              if (dateTime != null)
                                Text(
                                    'Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => editJadwal(jadwal['id']),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => deleteJadwal(jadwal['id']),
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
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JadwalMahasiswa(),
                  ),
                );
              },
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
