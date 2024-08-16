import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:presensi_api/matkul_class/add_matkul_class.dart';

class MatkulClassListPage extends StatefulWidget {
  @override
  _MatkulClassListPageState createState() => _MatkulClassListPageState();
}

class _MatkulClassListPageState extends State<MatkulClassListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSemester;
  String? _selectedClass;

  List<String> _semesters = [];
  Map<String, String> _classes = {}; // Map class ID to class name

  @override
  void initState() {
    super.initState();
    _fetchSemesters();
  }

  Future<void> _fetchSemesters() async {
    var snapshot = await _firestore.collection('semester').get();
    setState(() {
      _semesters = snapshot.docs.map((doc) => doc.id).toList();
    });

    // Also fetch classes if a semester is selected
    if (_selectedSemester != null) {
      _fetchClasses(_selectedSemester!);
    }
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

  Future<void> _deleteMatkulClass(String id) async {
    try {
      await _firestore.collection('matkul_class').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Entry deleted successfully'),
      ));
    } catch (e) {
      print("Error deleting entry: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting entry'),
      ));
    }
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
                    decoration: InputDecoration(labelText: 'Select Semester'),
                    value: _selectedSemester,
                    items: _semesters.map((semesterId) {
                      return DropdownMenuItem<String>(
                        value: semesterId,
                        child: Text(
                            semesterId), // You can use semester names if available
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSemester = value;
                        _selectedClass =
                            null; // Reset class filter when semester changes
                        _fetchClasses(value!);
                      });
                    },
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('matkul_class').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var matkulClasses = snapshot.data!.docs;

                  if (matkulClasses.isEmpty) {
                    return Center(child: Text('No data available'));
                  }

                  // Apply filters
                  if (_selectedSemester != null) {
                    matkulClasses = matkulClasses.where((doc) {
                      return doc['semester_id'] == _selectedSemester;
                    }).toList();
                  }
                  if (_selectedClass != null) {
                    matkulClasses = matkulClasses.where((doc) {
                      return doc['class_id'] == _selectedClass;
                    }).toList();
                  }

                  return ListView.builder(
                    itemCount: matkulClasses.length,
                    itemBuilder: (context, index) {
                      var doc = matkulClasses[index];
                      var semesterId = doc['semester_id'];
                      var classId = doc['class_id'];
                      var matkulIds = List<String>.from(doc['matkul_id']);

                      return FutureBuilder<Map<String, String>>(
                        future: _fetchDetails(semesterId, classId, matkulIds),
                        builder: (context, detailsSnapshot) {
                          if (!detailsSnapshot.hasData) {
                            return ListTile(
                              title: Text('Loading...'),
                            );
                          }

                          var details = detailsSnapshot.data!;
                          var semesterName = details['semester'] ?? 'Unknown';
                          var className = details['class'] ?? 'Unknown';
                          var matkulNames = details['matkul'] ?? 'Unknown';

                          return ListTile(
                            title: Text('$semesterName - $className'),
                            subtitle: Text(matkulNames),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMatkulClass(doc.id),
                            ),
                          );
                        },
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
            MaterialPageRoute(builder: (context) => AddMatkulClassPage()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Matkul Class',
      ),
    );
  }

  Future<Map<String, String>> _fetchDetails(
      String semesterId, String classId, List<String> matkulIds) async {
    Map<String, String> details = {};

    try {
      var semesterDoc =
          await _firestore.collection('semester').doc(semesterId).get();
      details['semester'] = semesterDoc.data()?['name'] ?? 'Unknown';

      var classDoc = await _firestore.collection('kelas').doc(classId).get();
      details['class'] = classDoc.data()?['name'] ?? 'Unknown';

      var matkulDocs = await _firestore
          .collection('matkul')
          .where(FieldPath.documentId, whereIn: matkulIds)
          .get();
      details['matkul'] =
          matkulDocs.docs.map((doc) => doc.data()['name'] as String).join(', ');
    } catch (e) {
      print("Error fetching details: $e");
    }

    return details;
  }
}
