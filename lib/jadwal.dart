import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Library untuk format tanggal

class JadwalMahasiswa extends StatefulWidget {
  @override
  _JadwalMahasiswaState createState() => _JadwalMahasiswaState();
}

class _JadwalMahasiswaState extends State<JadwalMahasiswa> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tanggalController = TextEditingController();

  String? selectedSemester;
  String? selectedKelas;
  String? selectedMatkul;
  String? selectedHari;
  String? status;
  String? roomNumber;
  String? link;
  DateTime? selectedDate;
  String? jamMulai;
  String? menitMulai;
  String? jamAkhir;
  String? menitAkhir;
  List<String> semesterList = [];
  List<String> kelasList = [];
  List<String> matkulList = [];
  List<String> hariList = [];
  Map<String, dynamic>? jadwalDetails;
  bool searchPerformed = false;

  @override
  void initState() {
    super.initState();
    fetchSemesterList();
    fetchHariList();
  }

  Future<void> fetchSemesterList() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('semester').get();
    setState(() {
      semesterList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> fetchKelasList(String semesterId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('class_semester')
        .where('semester_id', isEqualTo: semesterId)
        .get();

    var classIds =
        snapshot.docs.map((doc) => doc['class_id'] as String).toList();

    var classSnapshot = await FirebaseFirestore.instance
        .collection('kelas')
        .where(FieldPath.documentId, whereIn: classIds)
        .get();

    setState(() {
      kelasList = classSnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> fetchMatkulList(String classId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('matkul_class')
        .where('class_id', isEqualTo: classId)
        .get();

    var matkulIds = snapshot.docs
        .map((doc) => doc['matkul_id'] as List)
        .expand((x) => x)
        .toList();

    var matkulSnapshot = await FirebaseFirestore.instance
        .collection('matkul')
        .where(FieldPath.documentId, whereIn: matkulIds)
        .get();

    setState(() {
      matkulList =
          matkulSnapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> fetchJadwalList() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('jadwal')
        .where('semester_id', isEqualTo: selectedSemester)
        .where('class_id', isEqualTo: selectedKelas)
        .where('matkul_id', isEqualTo: selectedMatkul)
        .where('hari_id', isEqualTo: selectedHari)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        jadwalDetails = snapshot.docs.first.data();
        status = jadwalDetails?['status'];
        roomNumber = jadwalDetails?['room_number'];
        link = jadwalDetails?['link'];
        selectedDate = (jadwalDetails?['tanggal'] as Timestamp?)?.toDate();
        _tanggalController.text = selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : '';
        jamMulai = jadwalDetails?['jam_mulai'];
        menitMulai = jadwalDetails?['menit_mulai'];
        jamAkhir = jadwalDetails?['jam_akhir'];
        menitAkhir = jadwalDetails?['menit_akhir'];
      });
    } else {
      setState(() {
        jadwalDetails = null;
        status = null;
        roomNumber = null;
        link = null;
        selectedDate = null;
        _tanggalController.text = '';
        jamMulai = null;
        menitMulai = null;
        jamAkhir = null;
        menitAkhir = null;
      });
    }
  }

  Future<void> fetchHariList() async {
    var snapshot = await FirebaseFirestore.instance.collection('hari').get();
    setState(() {
      hariList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      int? parsedRoomNumber = int.tryParse(roomNumber ?? '');
      int? parsedJamMulai = int.tryParse(jamMulai ?? '');
      int? parsedMenitMulai = int.tryParse(menitMulai ?? '');
      int? parsedJamAkhir = int.tryParse(jamAkhir ?? '');
      int? parsedMenitAkhir = int.tryParse(menitAkhir ?? '');

      Map<String, dynamic> jadwalData = {
        'semester_id': selectedSemester,
        'class_id': selectedKelas,
        'matkul_id': selectedMatkul,
        'hari_id': selectedHari,
        'status': status,
        'room_number': status == 'Offline' ? parsedRoomNumber : null,
        'link': status == 'Online' ? link : null,
        'tanggal': selectedDate,
        'jam_mulai': parsedJamMulai,
        'menit_mulai': parsedMenitMulai,
        'jam_akhir': parsedJamAkhir,
        'menit_akhir': parsedMenitAkhir,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('jadwal').add(jadwalData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jadwal berhasil disimpan!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Mahasiswa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Row for Hari and Semester
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Hari"),
                            value: selectedHari,
                            onChanged: (value) {
                              setState(() {
                                selectedHari = value;
                              });
                            },
                            items: hariList.map((hari) {
                              return DropdownMenuItem<String>(
                                value: hari,
                                child: Text(hari),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Semester"),
                            value: selectedSemester,
                            onChanged: (value) {
                              setState(() {
                                selectedSemester = value;
                                selectedKelas = null;
                                selectedMatkul = null;
                                kelasList.clear();
                                matkulList.clear();
                                searchPerformed = false;
                                if (value != null) {
                                  fetchKelasList(value);
                                }
                              });
                            },
                            items: semesterList.map((semester) {
                              return DropdownMenuItem<String>(
                                value: semester,
                                child: Text(semester),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),

                    // Row for Kelas and Matkul
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Kelas"),
                            value: selectedKelas,
                            onChanged: (value) {
                              setState(() {
                                selectedKelas = value;
                                selectedMatkul = null;
                                matkulList.clear();
                                searchPerformed = false;
                                if (value != null) {
                                  fetchMatkulList(value);
                                }
                              });
                            },
                            items: kelasList.map((kelas) {
                              return DropdownMenuItem<String>(
                                value: kelas,
                                child: Text(kelas),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: DropdownButton<String>(
                            hint: Text("Select Matkul"),
                            value: selectedMatkul,
                            onChanged: (value) {
                              setState(() {
                                selectedMatkul = value;
                                searchPerformed = false;
                              });
                            },
                            items: matkulList.map((matkul) {
                              return DropdownMenuItem<String>(
                                value: matkul,
                                child: Text(matkul),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),

                    // Search Button
                    ElevatedButton(
                      onPressed: () {
                        fetchJadwalList();
                        setState(() {
                          searchPerformed = true;
                        });
                      },
                      child: Text("Search"),
                    ),

                    // Status Dropdown
                    if (searchPerformed)
                      Column(
                        children: [
                          SizedBox(height: 16.0),
                          DropdownButton<String>(
                            hint: Text("Select Status"),
                            value: status,
                            onChanged: (value) {
                              setState(() {
                                status = value;
                              });
                            },
                            items: ['Online', 'Offline'].map((statusOption) {
                              return DropdownMenuItem<String>(
                                value: statusOption,
                                child: Text(statusOption),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16.0),

                          // Room Number or Link Input
                          if (status == 'Offline') ...[
                            TextFormField(
                              initialValue: roomNumber,
                              decoration:
                                  InputDecoration(labelText: "Room Number"),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                roomNumber = value;
                              },
                            ),
                          ] else if (status == 'Online') ...[
                            TextFormField(
                              initialValue: link,
                              decoration: InputDecoration(labelText: "Link"),
                              keyboardType: TextInputType.url,
                              onChanged: (value) {
                                link = value;
                              },
                            ),
                          ],
                          SizedBox(height: 16.0),

                          // Date Picker
                          TextFormField(
                            controller: _tanggalController,
                            decoration: InputDecoration(labelText: "Tanggal"),
                            readOnly: true,
                            onTap: () async {
                              selectedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (selectedDate != null) {
                                _tanggalController.text =
                                    DateFormat('yyyy-MM-dd')
                                        .format(selectedDate!);
                              }
                            },
                          ),
                          SizedBox(height: 16.0),

                          // Time Input Fields
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration:
                                      InputDecoration(labelText: "Jam Mulai"),
                                  keyboardType: TextInputType.number,
                                  initialValue: jamMulai,
                                  onChanged: (value) {
                                    jamMulai = value;
                                  },
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: TextFormField(
                                  decoration:
                                      InputDecoration(labelText: "Menit Mulai"),
                                  keyboardType: TextInputType.number,
                                  initialValue: menitMulai,
                                  onChanged: (value) {
                                    menitMulai = value;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration:
                                      InputDecoration(labelText: "Jam Akhir"),
                                  keyboardType: TextInputType.number,
                                  initialValue: jamAkhir,
                                  onChanged: (value) {
                                    jamAkhir = value;
                                  },
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: TextFormField(
                                  decoration:
                                      InputDecoration(labelText: "Menit Akhir"),
                                  keyboardType: TextInputType.number,
                                  initialValue: menitAkhir,
                                  onChanged: (value) {
                                    menitAkhir = value;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),

                          // Submit Button
                          ElevatedButton(
                            onPressed: handleSubmit,
                            child: Text("Submit"),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
