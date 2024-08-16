import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  final LatLng _referenceLocation = LatLng(-7.5395562137055165,
      110.7758042610071); // Replace with your reference location
  final double _radius = 200.0; // Radius in meters

  @override
  void initState() {
    super.initState();
    if (widget.jadwalData['status'] != 'Online') {
      _getLocation();
    }
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(firstCamera, ResolutionPreset.high);
    _initializeControllerFuture = _cameraController.initialize();
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

  Future<void> _handleAttendance(String presensiType) async {
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
        Fluttertoast.showToast(
            msg: 'Anda sudah melakukan presensi untuk jadwal ini.');
        return;
      }

      await _initializeControllerFuture;

      final image = await _cameraController.takePicture();
      final imageFile = XFile(image.path);

      final isFaceRecognized = await _recognizeFace(imageFile);

      if (!isFaceRecognized) {
        Fluttertoast.showToast(msg: 'Wajah tidak dikenali.');
        return;
      }

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
        'face_image': imageFile.path,
      };
      await FirebaseFirestore.instance
          .collection('presensi')
          .add(attendanceData);
      Fluttertoast.showToast(msg: 'Absensi berhasil dilakukan.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Terjadi kesalahan: $e');
    }
  }

  Future<bool> _recognizeFace(XFile imageFile) async {
    // TODO: Implement your face recognition logic here
    // Return true if face recognized, otherwise false
    return true;
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
                        _handleAttendance('hadir');
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
