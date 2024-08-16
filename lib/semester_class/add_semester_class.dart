import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddClassSemesterPage extends StatefulWidget {
  @override
  _AddClassSemesterPageState createState() => _AddClassSemesterPageState();
}

class _AddClassSemesterPageState extends State<AddClassSemesterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSemester;
  List<String> _selectedClasses = [];
  String _createdBy = "YourUserID"; // Replace with the actual user ID.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Class Semester'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                    items: semesters.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSemester = value;
                      });
                    },
                  );
                },
              ),
              SizedBox(height: 16.0),
              FutureBuilder<QuerySnapshot>(
                future: _firestore.collection('kelas').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  var classes = snapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: classes.map((doc) {
                      return CheckboxListTile(
                        title: Text(doc['name']),
                        value: _selectedClasses.contains(doc.id),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedClasses.add(doc.id);
                            } else {
                              _selectedClasses.remove(doc.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _selectedSemester == null || _selectedClasses.isEmpty
                    ? null
                    : _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    for (var classId in _selectedClasses) {
      // Generate a unique ID for the document in 'class_semester'
      final docRef = _firestore.collection('class_semester').doc();

      await docRef.set({
        'id': docRef.id, // Use the generated ID as the primary key
        'semester_id': _selectedSemester,
        'class_id': classId,
        'created_by': _createdBy,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data added successfully')),
    );

    Navigator.pop(context);
  }
}
