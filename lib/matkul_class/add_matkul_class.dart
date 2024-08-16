import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMatkulClassPage extends StatefulWidget {
  @override
  _AddMatkulClassPageState createState() => _AddMatkulClassPageState();
}

class _AddMatkulClassPageState extends State<AddMatkulClassPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSemester;
  String? _selectedClass;
  List<String> _selectedMatkulIds = [];
  List<String> _semesters = [];
  Map<String, String> _classes = {}; // Map class ID to class name
  Map<String, String> _matkuls = {}; // Map matkul ID to matkul name

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

  Future<void> _fetchMatkuls() async {
    var snapshot = await _firestore.collection('matkul').get();
    setState(() {
      _matkuls = {for (var doc in snapshot.docs) doc.id: doc['name']};
    });
  }

  void _submitForm() async {
    if (_selectedSemester == null ||
        _selectedClass == null ||
        _selectedMatkulIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Please select semester, class, and at least one subject'),
      ));
      return;
    }

    try {
      await _firestore.collection('matkul_class').add({
        'semester_id': _selectedSemester,
        'class_id': _selectedClass,
        'matkul_id': _selectedMatkulIds,
        'created_by': 'user_id_here', // Replace with actual user ID
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Matkul Class added successfully'),
      ));

      Navigator.pop(context);
    } catch (e) {
      print("Error adding Matkul Class: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error adding Matkul Class'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Matkul Class'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('semester').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                var semesters = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Select Semester'),
                  value: _selectedSemester,
                  items: semesters.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                      _selectedClass =
                          null; // Reset class when semester changes
                      _fetchClasses(value!);
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
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
            SizedBox(height: 16.0),
            FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('matkul').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                var matkuls = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: matkuls.map((doc) {
                    final id = doc.id;
                    final name = doc['name'];

                    return CheckboxListTile(
                      title: Text(name),
                      value: _selectedMatkulIds.contains(id),
                      onChanged: (isChecked) {
                        setState(() {
                          if (isChecked!) {
                            _selectedMatkulIds.add(id);
                          } else {
                            _selectedMatkulIds.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text('Add Matkul Class'),
            ),
          ],
        ),
      ),
    );
  }
}
