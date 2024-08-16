import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:presensi_api/semester_class/add_semester_class.dart';

class ListSemesterClassPage extends StatefulWidget {
  @override
  _ListSemesterClassPageState createState() => _ListSemesterClassPageState();
}

class _ListSemesterClassPageState extends State<ListSemesterClassPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('class_semester').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var classSemesterDocs = snapshot.data!.docs;
                var filteredDocs = classSemesterDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['class_id']
                          .toString()
                          .toLowerCase()
                          .contains(_searchTerm) ||
                      data['semester_id']
                          .toString()
                          .toLowerCase()
                          .contains(_searchTerm);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var classSemesterData =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    var docId =
                        filteredDocs[index].id; // Document ID for deletion

                    // Fetching the class name and semester name using the ids stored in class_semester
                    return FutureBuilder<List<String>>(
                      future: _getClassAndSemesterNames(
                          classSemesterData['class_id'],
                          classSemesterData['semester_id']),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return ListTile(
                            title: Text('Loading...'),
                          );
                        }

                        var names = snapshot.data!;
                        var className = names[0];
                        var semesterName = names[1];

                        return ListTile(
                          leading: Text('${index + 1}'), // Nomor urut
                          title: Text('Class: $className'),
                          subtitle: Text('Semester: $semesterName'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmationDialog(docId);
                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddClassSemesterPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<List<String>> _getClassAndSemesterNames(
      String classId, String semesterId) async {
    var classDoc = await _firestore.collection('kelas').doc(classId).get();
    var semesterDoc =
        await _firestore.collection('semester').doc(semesterId).get();

    String className = classDoc['name'];
    String semesterName = semesterDoc['name'];

    return [className, semesterName];
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteDocument(docId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDocument(String docId) async {
    try {
      await _firestore.collection('class_semester').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
      );
    }
  }
}
