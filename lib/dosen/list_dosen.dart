import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presensi_api/dosen/add_dosen.dart';
import 'package:presensi_api/mahasiswa/add_mahasiswa.dart';

class ListDosen extends StatefulWidget {
  @override
  _ListDosenState createState() => _ListDosenState();
}

class _ListDosenState extends State<ListDosen> {
  String searchQuery = '';
  Map<String, String> classNames = {};
  Map<String, String> semesterNames = {};

  @override
  void initState() {
    super.initState();
    fetchClassNames();
    fetchSemesterNames();
  }

  Future<void> fetchClassNames() async {
    var snapshot = await FirebaseFirestore.instance.collection('kelas').get();
    var classDocs = snapshot.docs;

    setState(() {
      classNames = {
        for (var doc in classDocs) doc.id: doc['name'],
      };
    });
  }

  Future<void> fetchSemesterNames() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('semester').get();
    var semesterDocs = snapshot.docs;

    setState(() {
      semesterNames = {
        for (var doc in semesterDocs) doc.id: doc['name'],
      };
    });
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User deleted successfully'),
      ));
    } catch (e) {
      print("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting user'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Name or NIP',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('user_type', isEqualTo: 2)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> filteredUsers =
                    snapshot.data!.docs.where((user) {
                  final nama = user['nama'].toLowerCase();
                  final nim = user['nim']?.toLowerCase() ?? '';
                  final query = searchQuery.toLowerCase();

                  return nama.contains(query) || nim.contains(query);
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 1.0, horizontal: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50, // Fixed width
                                  height: 50, // Fixed height
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle, // Square shape
                                    borderRadius: BorderRadius.circular(
                                        8), // Optional: Rounded corners
                                    image: DecorationImage(
                                      image: user['profile_img'] != null
                                          ? NetworkImage(user['profile_img'])
                                          : AssetImage(
                                                  'assets/default_profile_image.png')
                                              as ImageProvider,
                                      fit: BoxFit
                                          .cover, // Ensure the image covers the container
                                    ),
                                  ),
                                  child: user['profile_img'] == null
                                      ? Center(
                                          child: Icon(Icons.person, size: 24))
                                      : null,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(user['nama'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text('NIP: ${user['nim'] ?? 'N/A'}'),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      // Text(
                                      //     'Kelas: ${classNames[user['class_id']] ?? 'N/A'}'),
                                      // SizedBox(
                                      //   height: 5,
                                      // ),
                                      // Text(
                                      //     'Semester: ${semesterNames[user['semester_id']] ?? 'N/A'}'),
                                      // SizedBox(
                                      //   height: 5,
                                      // ),
                                      Text('Email: ${user['email']}'),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                          'Jenis Kelamin: ${user['gender'] ?? 'N/A'}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddDosenUser(
                                          userId: user.id,
                                          name: user['nama'],
                                          nim: user['nim'],
                                          email: user['email'],
                                          gender: user['gender'],
                                          profileImageUrl: user['profile_img'],
                                          // semesterId: user['semester_id'],
                                          // classId: user['class_id'],
                                        ),
                                      ),
                                    ).then((_) {
                                      // Refresh the list after editing
                                      fetchClassNames();
                                      fetchSemesterNames();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteUser(user.id);
                                  },
                                ),
                              ],
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDosenUser()),
          ).then((_) {
            // Refresh the list after adding
            fetchClassNames();
            fetchSemesterNames();
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
