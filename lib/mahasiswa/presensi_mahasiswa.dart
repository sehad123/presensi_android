import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:presensi_api/mahasiswa/mypresensi_mahasiswa.dart';
import 'package:http/http.dart' as http;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http_parser/http_parser.dart';

class PresensiMahasiswa extends StatefulWidget {
  final Map<String, dynamic> jadwalData;
  final Map<String, dynamic> userData;

  const PresensiMahasiswa(
      {Key? key, required this.jadwalData, required this.userData})
      : super(key: key);

  @override
  _PresensiMahasiswaState createState() => _PresensiMahasiswaState();
}

class _PresensiMahasiswaState extends State<PresensiMahasiswa> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  bool _loadingLocation = true;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  final LatLng _referenceLocation = LatLng(-7.5395562137055165,
      110.7758042610071); // Replace with your reference location
  final double _radius = 200.0; // Radius in meters
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeController();

    if (widget.jadwalData['status'] != 'Online') {
      _getLocation();
    }
  }

  Future<void> _initializeController() async {
    // Misalkan ini adalah contoh inisialisasi controller
    // Ganti dengan kode yang sesuai untuk controller yang Anda gunakan
    await Future.delayed(Duration(seconds: 1)); // Contoh proses inisialisasi
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _loadingLocation = false;
      });
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _loadingLocation = false;
        });
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _loadingLocation = false;
      });
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _loadingLocation = false;
      if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        );
      }
    });
  }

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      _verifyFace(File(image.path));
    } else {
      Fluttertoast.showToast(msg: 'Gambar tidak diambil.');
    }
  }

  Future<void> _verifyFace(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'User not logged in.');
      return;
    }

    final profileImageFile = await _getProfileImage(user.uid);

    final facesTakenImage = await _detectFaces(imageFile);
    final facesProfileImage = await _detectFaces(profileImageFile);

    if (facesTakenImage.isEmpty || facesProfileImage.isEmpty) {
      Fluttertoast.showToast(msg: 'Tidak ada wajah yang terdeteksi.');
      return;
    }

    // Simplified face comparison logic
    final faceMatch = facesTakenImage.length == facesProfileImage.length;

    if (faceMatch) {
      // Save the face image to Firebase Storage
      final faceImageUrl = await _uploadFaceImage(imageFile);
      _handleAttendance('hadir', faceImageUrl);
    } else {
      Fluttertoast.showToast(msg: 'Verifikasi wajah gagal.');
    }
  }

  Future<File> _getProfileImage(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final String? imageUrl = doc.data()?['profile_img'];

    if (imageUrl == null) {
      Fluttertoast.showToast(msg: 'Gambar profil tidak ditemukan.');
      throw Exception('Gambar profil tidak ditemukan.');
    }

    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/profile_image.jpg');
    await file.writeAsBytes(bytes);

    return file;
  }

  Future<List<Face>> _detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    try {
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Terjadi kesalahan: $e');
      return [];
    }
  }

  Future<String> _uploadFaceImage(File imageFile) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('face_images')
        .child('$userId-${DateTime.now().millisecondsSinceEpoch}.jpg');

    try {
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal mengupload gambar wajah: $e');
    }
  }

  Future<void> _handleAttendance(
      String presensiType, String faceImageUrl) async {
    if (widget.jadwalData['status'] != 'Online' && _currentPosition == null) {
      Fluttertoast.showToast(msg: 'Tidak dapat mendeteksi lokasi.');
      return;
    }

    if (widget.jadwalData['status'] != 'Online') {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _referenceLocation.latitude,
        _referenceLocation.longitude,
      );

      if (distance > _radius) {
        Fluttertoast.showToast(
            msg: 'Lokasi Anda berada di luar radius yang diizinkan.');
        return;
      }
    }

    try {
      // Cek apakah user sudah presensi untuk jadwal ini
      QuerySnapshot presensiSnapshot = await FirebaseFirestore.instance
          .collection('presensi')
          .where('class_id', isEqualTo: widget.jadwalData['class_id'])
          .where('hari_id', isEqualTo: widget.jadwalData['hari_id'])
          .where('matkul_id', isEqualTo: widget.jadwalData['matkul_id'])
          .where('student_id', isEqualTo: widget.userData['user_id'])
          .get();

      if (presensiSnapshot.docs.isNotEmpty) {
        // Fluttertoast.showToast(
        //     msg: 'Anda sudah melakukan presensi untuk jadwal ini.');
        // Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Anda sudah melakukan presensi untuk jadwal ini')),
        );

        Navigator.pop(context);
        return;
      }

      await _initializeControllerFuture;

      // Hitung keterlambatan
      DateTime now = DateTime.now();
      int jamMulai =
          int.tryParse(widget.jadwalData['jam_mulai'].toString()) ?? 0;
      int menitMulai =
          int.tryParse(widget.jadwalData['menit_mulai'].toString()) ?? 0;
      DateTime startTime =
          DateTime(now.year, now.month, now.day, jamMulai, menitMulai);

      Duration difference = now.difference(startTime);
      if (difference.inMinutes > 30) {
        presensiType = 'tidak hadir';
      } else if (difference.inMinutes > 20) {
        presensiType = 'terlambat B';
      } else if (difference.inMinutes > 10) {
        presensiType = 'terlambat A';
      }

      final attendanceData = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'class_id': widget.jadwalData['class_id'],
        'tanggal': DateTime.now(),
        'student_id':
            widget.userData['user_type'] == 3 ? widget.userData['nama'] : null,
        'dosen_id':
            widget.userData['user_type'] == 2 ? widget.userData['nama'] : null,
        'presensi_type': presensiType,
        'created_by': widget.userData['nama'],
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
        'matkul_id': widget.jadwalData['matkul_id'],
        'hari_id': widget.jadwalData['hari_id'],
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'face_image': faceImageUrl,
      };
      await FirebaseFirestore.instance
          .collection('presensi')
          .add(attendanceData);

      Fluttertoast.showToast(msg: 'Absensi berhasil dilakukan.');

      // Navigasi ke halaman RekapPresensi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RekapPresensiMahasiswa(userData: widget.userData),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Terjadi kesalahan: $e');
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    var jadwal = widget.jadwalData;
    var user = widget.userData;

    DateTime? dateTime;
    if (jadwal['tanggal'] != null && jadwal['tanggal'] is Timestamp) {
      dateTime = (jadwal['tanggal'] as Timestamp).toDate();
    }

    bool isOnline = jadwal['status'] == 'Online';
    DateTime now = DateTime.now();

    // Parse time safely
    int jamMulai = int.tryParse(jadwal['jam_mulai'].toString()) ?? 0;
    int menitMulai = int.tryParse(jadwal['menit_mulai'].toString()) ?? 0;
    int jamAkhir = int.tryParse(jadwal['jam_akhir'].toString()) ?? 23;
    int menitAkhir = int.tryParse(jadwal['menit_akhir'].toString()) ?? 59;

    DateTime startTime =
        DateTime(now.year, now.month, now.day, jamMulai, menitMulai);
    DateTime endTime =
        DateTime(now.year, now.month, now.day, jamAkhir, menitAkhir);

    bool isInTimeRange = dateTime != null &&
        isSameDay(now, dateTime) &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('Presensi Mahasiswa'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                '${jadwal['matkul_id'] ?? 'Unknown Matkul'}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Nama: ${user['nama'] ?? 'Unknown User'}',
                style: TextStyle(fontSize: 16),
              ),
              Text('Hari: ${jadwal['hari_id'] ?? 'Unknown Hari'}'),
              Text('Kelas: ${jadwal['class_id'] ?? 'Unknown Kelas'}'),
              Text(
                  'Jam: ${jamMulai.toString().padLeft(2, '0')}:${menitMulai.toString().padLeft(2, '0')} - ${jamAkhir.toString().padLeft(2, '0')}:${menitAkhir.toString().padLeft(2, '0')}'),
              Text('Status: ${jadwal['status'] ?? 'Unknown Status'}'),
              if (jadwal['status'] == 'Offline' &&
                  jadwal['room_number'] != null)
                Text('Ruangan: ${jadwal['room_number']}'),
              if (jadwal['status'] == 'Online' && jadwal['link'] != null)
                Text('Link Zoom: ${jadwal['link']}'),
              if (dateTime != null)
                Text('Tanggal: ${DateFormat('d MMMM yyyy').format(dateTime)}'),
              SizedBox(height: 16),
              if (_currentPosition != null)
                Container(
                  height: 200,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                            color: Colors.blue.withOpacity(0.7),
                            radius: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                CircularProgressIndicator(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (isInTimeRange) {
                        _takePicture();
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Anda belum bisa melakukan presensi');
                      }
                    },
                    child: Text(isOnline || isInTimeRange
                        ? 'Hadir'
                        : 'Anda belum bisa melakukan presensi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
