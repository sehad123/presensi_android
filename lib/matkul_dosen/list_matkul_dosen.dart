import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:presensi_api/matkul_dosen/add_matkul_dosen.dart';

class MatkulDosenListPage extends StatefulWidget {
  @override
  _MatkulDosenListPageState createState() => _MatkulDosenListPageState();
}

class _MatkulDosenListPageState extends State<MatkulDosenListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _matkulDosenList = [];
  List<DocumentSnapshot> _filteredMatkulDosenList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatkulDosen();
  }

  Future<void> _fetchMatkulDosen() async {
    try {
      // Fetch matkul_dosen records
      var snapshot = await _firestore.collection('matkul_dosen').get();

      // Fetch related information
      final matkulDosenList = snapshot.docs;

      // Fetch related matkul, semester, class, and dosen
      List<String> matkulIds = [];
      List<String> semesterIds = [];
      List<String> classIds = [];
      List<String> dosenIds = [];

      for (var doc in matkulDosenList) {
        matkulIds.add(doc['matkul_id']);
        semesterIds.add(doc['semester_id']);
        classIds.add(doc['class_id']);
        dosenIds.add(doc['dosen_id']);
      }

      var matkulSnapshot = await _firestore
          .collection('matkul')
          .where(FieldPath.documentId, whereIn: matkulIds)
          .get();
      var semesterSnapshot = await _firestore
          .collection('semester')
          .where(FieldPath.documentId, whereIn: semesterIds)
          .get();
      var classSnapshot = await _firestore
          .collection('kelas')
          .where(FieldPath.documentId, whereIn: classIds)
          .get();
      var dosenSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: dosenIds)
          .get();

      setState(() {
        _matkulDosenList = matkulDosenList;
        _filteredMatkulDosenList = matkulDosenList;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching matkul dosen: $e");
    }
  }

  void _filterList(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMatkulDosenList = _matkulDosenList;
      });
    } else {
      setState(() {
        _filteredMatkulDosenList = _matkulDosenList.where((doc) {
          final matkulId = doc['matkul_id'];
          final semesterId = doc['semester_id'];
          final classId = doc['class_id'];
          final dosenId = doc['dosen_id'];

          return matkulId.toLowerCase().contains(query.toLowerCase()) ||
              semesterId.toLowerCase().contains(query.toLowerCase()) ||
              classId.toLowerCase().contains(query.toLowerCase()) ||
              dosenId.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _deleteMatkulDosen(String id) async {
    try {
      await _firestore.collection('matkul_dosen').doc(id).delete();
      _fetchMatkulDosen(); // Refresh the list
    } catch (e) {
      print("Error deleting matkul dosen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _filterList,
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredMatkulDosenList.length,
                      itemBuilder: (context, index) {
                        final doc = _filteredMatkulDosenList[index];
                        final matkulId = doc['matkul_id'];
                        final semesterId = doc['semester_id'];
                        final classId = doc['class_id'];
                        final dosenId = doc['dosen_id'];

                        return FutureBuilder(
                          future: Future.wait([
                            _firestore.collection('matkul').doc(matkulId).get(),
                            _firestore
                                .collection('semester')
                                .doc(semesterId)
                                .get(),
                            _firestore.collection('kelas').doc(classId).get(),
                            _firestore.collection('users').doc(dosenId).get(),
                          ]),
                          builder: (context,
                              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text('Loading...'),
                              );
                            }

                            if (snapshot.hasError) {
                              return ListTile(
                                title: Text('Error loading data'),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.any((doc) => !doc.exists)) {
                              return ListTile(
                                title: Text('Daftat Matkul & Dosen'),
                              );
                            }

                            final matkulDoc = snapshot.data![0];
                            final semesterDoc = snapshot.data![1];
                            final classDoc = snapshot.data![2];
                            final dosenDoc = snapshot.data![3];

                            return ListTile(
                              title: Text(
                                  '${matkulDoc['name']} - ${classDoc['name']} - ${semesterDoc['name']}'),
                              subtitle: Text(dosenDoc['nama'] ?? 'No name'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteMatkulDosen(doc.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMatkulDosenPage(),
            ),
          ).then(
              (_) => _fetchMatkulDosen()); // Refresh list after navigating back
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
