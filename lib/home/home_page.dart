import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presensi_api/dashboard.dart';
import 'package:presensi_api/mahasiswa/jadwal_mahasiswa.dart';
import 'package:presensi_api/mahasiswa/mypresensi_mahasiswa.dart';
import 'package:presensi_api/menu_page.dart';
import 'package:presensi_api/profile/profile_page.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      } else {
        print("User data not found.");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    Widget _getSelectedPage() {
      if (_userData == null) {
        return Center(child: CircularProgressIndicator());
      }

      switch (_selectedIndex) {
        case 0:
          return _userData!['user_type'] == 1
              ? DashboardPage()
              : JadwalMahasiswastis(userData: _userData!);
        case 1:
          return _userData!['user_type'] == 1
              ? MenuPage()
              : RekapPresensiMahasiswa(userData: _userData!);
        case 2:
          return ProfilePage(userData: _userData!);
        default:
          return Center(child: Text('Page not found'));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Presensi')),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: _userData!['user_type'] == 1 ? 'Dashboard' : 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: _userData!['user_type'] == 1 ? 'Menu' : 'Rekapan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Placeholder pages for Jadwal and Rekapan
class JadwalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jadwal')),
      body: Center(child: Text('Jadwal Page')),
    );
  }
}

class RekapanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rekapan')),
      body: Center(child: Text('Rekapan Page')),
    );
  }
}
