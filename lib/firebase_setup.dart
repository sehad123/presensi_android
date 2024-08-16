import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> setupFirebase() async {
  await Firebase.initializeApp();

  final usersCollection = FirebaseFirestore.instance.collection('users');
  final kelasCollection = FirebaseFirestore.instance.collection('kelas');
  final semesterCollection = FirebaseFirestore.instance.collection('semester');
  final matkulCollection = FirebaseFirestore.instance.collection('matkul');
  final hariCollection = FirebaseFirestore.instance.collection('hari');

  // Cek apakah user admin sudah ada
  final querySnapshot =
      await usersCollection.where('email', isEqualTo: 'sehad@gmail.com').get();

  if (querySnapshot.docs.isEmpty) {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'sehad@gmail.com',
        password: 'sehad123',
      );

      await usersCollection.doc(userCredential.user!.uid).set({
        'id': userCredential.user!.uid,
        'nama': 'Admin',
        'password': 'admin123',
        'user_type': 1,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
        'semester_id': null,
        'class_id': null,
        'nim': null,
        'email': 'admin@gmail.com',
        'profile_img': null,
        'gender': null,
      });

      print("Admin user created successfully.");
    } catch (e) {
      print("Error creating admin user: $e");
    }
  } else {
    print("Admin user already exists.");
  }

  // Tambahkan data ke koleksi 'kelas' jika belum ada
  List<String> kelasList = [
    "1ST1",
    "1ST2",
    "1ST3",
    "1D31",
    "1D32",
    "2KS1",
    "2KS2",
    "2KS3",
    "2ST1",
    "2ST2",
    "2ST3",
    "2D31",
    "2D32",
    "3SI1",
    "3SI2",
    "3SI3",
    "3SD1",
    "3SD2",
    "3SK1",
    "3SK2",
    "3SE1",
    "3SE2",
    "3D31",
    "3D32",
    "4SI1",
    "4SI2",
    "4SD1",
    "4SD2",
    "4SE1",
    "4SE2",
    "4SK1",
    "4SK2"
  ];

  for (String kelas in kelasList) {
    final kelasSnapshot =
        await kelasCollection.where('id', isEqualTo: kelas).get();
    if (kelasSnapshot.docs.isEmpty) {
      await kelasCollection.doc(kelas).set({
        'name': kelas,
        'status': 0, // 0: active, 1: inactive
        'created_by': 'admin',
        'is_delete': 0, // 0: not, 1: yes
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
    } else {
      print("Kelas '$kelas' already exists.");
    }
  }

  // Tambahkan data ke koleksi 'semester' jika belum ada
  List<String> semesterList = [
    "Semester 1",
    "Semester 2",
    "Semester 3",
    "Semester 4",
    "Semester 5",
    "Semester 6",
    "Semester 7",
    "Semester 8",
  ];

  for (String semester in semesterList) {
    final semesterSnapshot =
        await semesterCollection.where('id', isEqualTo: semester).get();
    if (semesterSnapshot.docs.isEmpty) {
      await semesterCollection.doc(semester).set({
        'name': semester,
        'created_by': 'admin',
        'is_delete': 0, // 0: not, 1: yes
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
        'status': 0, // 0: non ujian, 1: ujian
      });
    } else {
      print("Semester '$semester' already exists.");
    }
  }

  // Tambahkan data ke koleksi 'matkul' jika belum ada
  List<Map<String, dynamic>> matkulList = [
    {
      'id': 1,
      'name': 'Interaksi Manusia Komputer',
      'type': 'Teori & Praktikum',
      'status': 0,
      'created_by': 'admin',
      'is_delete': 0,
      'created_at': Timestamp.fromDate(DateTime.parse('2024-07-30 09:44:32')),
      'updated_at': Timestamp.fromDate(DateTime.parse('2024-08-07 08:05:23')),
    },
    {
      'id': 2,
      'name': 'Official Statistik Lanjutan',
      'type': 'Teori',
      'status': 0,
      'created_by': 'admin',
      'is_delete': 0,
      'created_at': Timestamp.fromDate(DateTime.parse('2024-07-30 09:44:49')),
      'updated_at': Timestamp.fromDate(DateTime.parse('2024-07-30 09:44:49')),
    },
    // Lanjutkan dengan semua matkul yang ada di gambar
  ];

  for (Map<String, dynamic> matkul in matkulList) {
    final matkulSnapshot =
        await matkulCollection.where('name', isEqualTo: matkul['name']).get();
    if (matkulSnapshot.docs.isEmpty) {
      await matkulCollection.doc(matkul['id'].toString()).set(matkul);
    } else {
      print("Matkul '${matkul['name']}' already exists.");
    }
  }

  // Tambahkan data ke koleksi 'hari' jika belum ada
  List<Map<String, dynamic>> hariList = [
    {'id': 1, 'name': 'Senin', 'fullcalendar_day': 1},
    {'id': 2, 'name': 'Selasa', 'fullcalendar_day': 2},
    {'id': 3, 'name': 'Rabu', 'fullcalendar_day': 3},
    {'id': 4, 'name': 'Kamis', 'fullcalendar_day': 4},
    {'id': 5, 'name': 'Jumat', 'fullcalendar_day': 5},
  ];

  for (Map<String, dynamic> hari in hariList) {
    final hariSnapshot =
        await hariCollection.where('id', isEqualTo: hari['id']).get();
    if (hariSnapshot.docs.isEmpty) {
      await hariCollection.doc(hari['id'].toString()).set({
        'id': hari['id'],
        'name': hari['name'],
        'fullcalendar_day': hari['fullcalendar_day'],
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
    } else {
      print("Hari '${hari['name']}' already exists.");
    }
  }

  print("Kelas, Semester, Matkul, dan Hari data added successfully.");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupFirebase();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Firebase Setup Done")),
      ),
    );
  }
}
