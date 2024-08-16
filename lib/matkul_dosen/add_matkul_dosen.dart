import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMatkulDosenPage extends StatefulWidget {
  @override
  _AddMatkulDosenPageState createState() => _AddMatkulDosenPageState();
}

class _AddMatkulDosenPageState extends State<AddMatkulDosenPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSemester;
  String? _selectedClass;
  String? _selectedMatkul;
  String? _selectedDosen;

  List<String> _semesters = [];
  Map<String, String> _classes = {}; // Map class ID to class name
  Map<String, String> _matkul = {}; // Map matkul ID to matkul name
  Map<String, String> _dosen = {}; // Map dosen ID to dosen name

  @override
  void initState() {
    super.initState();
    _fetchSemesters();
    _fetchDosen(); // Fetch dosen when initializing
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
      _matkul = {for (var doc in matkulSnapshot.docs) doc.id: doc['name']};
    });
  }

  Future<void> _fetchDosen() async {
    try {
      var snapshot = await _firestore
          .collection('users')
          .where('user_type', isEqualTo: 2)
          .get();

      setState(() {
        _dosen = {for (var doc in snapshot.docs) doc.id: doc['nama']};
      });
    } catch (e) {
      print("Error fetching dosen: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_selectedSemester == null ||
        _selectedClass == null ||
        _selectedMatkul == null ||
        _selectedDosen == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields'),
      ));
      return;
    }

    try {
      await _firestore.collection('matkul_dosen').add({
        'semester_id': _selectedSemester,
        'class_id': _selectedClass,
        'matkul_id': _selectedMatkul,
        'dosen_id': _selectedDosen,
        'created_by':
            'current_user_id', // Replace with actual user ID if available
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Matkul Dosen added successfully'),
      ));

      Navigator.pop(context);
    } catch (e) {
      print("Error adding Matkul Dosen: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error adding Matkul Dosen'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Matkul Dosen'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Semester'),
              value: _selectedSemester,
              items: _semesters.map((semesterId) {
                return DropdownMenuItem<String>(
                  value: semesterId,
                  child: Text(semesterId), // Use semester names if available
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSemester = value;
                  _selectedClass =
                      null; // Reset class and matkul when semester changes
                  _selectedMatkul = null;
                  _fetchClasses(value!);
                });
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
                  _selectedMatkul = null; // Reset matkul when class changes
                  _fetchMatkul(value!);
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Matkul'),
              value: _selectedMatkul,
              items: _matkul.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMatkul = value;
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Dosen'),
              value: _selectedDosen,
              items: _dosen.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDosen = value;
                });
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text('Add Matkul Dosen'),
            ),
          ],
        ),
      ),
    );
  }
}
