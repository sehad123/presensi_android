import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditJadwal extends StatefulWidget {
  final String docId;

  EditJadwal({required this.docId});

  @override
  _EditJadwalState createState() => _EditJadwalState();
}

class _EditJadwalState extends State<EditJadwal> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> _jadwalData;
  List<String> _hariList = [];
  String? _selectedHari;
  String? _status;
  TextEditingController _roomNumberController = TextEditingController();
  TextEditingController _linkController = TextEditingController();
  TextEditingController _jamMulaiController = TextEditingController();
  TextEditingController _menitMulaiController = TextEditingController();
  TextEditingController _jamAkhirController = TextEditingController();
  TextEditingController _menitAkhirController = TextEditingController();
  TextEditingController _tanggalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchJadwalData();
    _fetchHariList();
  }

  Future<void> _fetchJadwalData() async {
    var docSnapshot =
        await _firestore.collection('jadwal').doc(widget.docId).get();
    if (docSnapshot.exists) {
      setState(() {
        _jadwalData = docSnapshot.data()!;
        _selectedHari = _jadwalData['hari_id'];
        _status = _jadwalData['status'];
        _roomNumberController.text =
            _jadwalData['room_number']?.toString() ?? '';
        _linkController.text = _jadwalData['link'] ?? '';
        _jamMulaiController.text = _jadwalData['jam_mulai']?.toString() ?? '';
        _menitMulaiController.text =
            _jadwalData['menit_mulai']?.toString() ?? '';
        _jamAkhirController.text = _jadwalData['jam_akhir']?.toString() ?? '';
        _menitAkhirController.text =
            _jadwalData['menit_akhir']?.toString() ?? '';
        _tanggalController.text = DateFormat('yyyy-MM-dd')
            .format((_jadwalData['tanggal'] as Timestamp).toDate());
      });
    }
  }

  Future<void> _fetchHariList() async {
    var snapshot = await _firestore.collection('hari').get();
    setState(() {
      _hariList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> _updateJadwal() async {
    try {
      await _firestore.collection('jadwal').doc(widget.docId).update({
        'hari_id': _selectedHari,
        'status': _status,
        'room_number': _status == 'Offline'
            ? int.tryParse(_roomNumberController.text)
            : null,
        'link': _status == 'Online' ? _linkController.text : null,
        'jam_mulai': int.tryParse(_jamMulaiController.text),
        'menit_mulai': int.tryParse(_menitMulaiController.text),
        'jam_akhir': int.tryParse(_jamAkhirController.text),
        'menit_akhir': int.tryParse(_menitAkhirController.text),
        'tanggal': DateFormat('yyyy-MM-dd').parse(_tanggalController.text),
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Jadwal updated successfully'),
      ));

      Navigator.pop(context);
    } catch (e) {
      print("Error updating Jadwal: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating Jadwal'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Jadwal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hari'),
            Wrap(
              spacing: 8.0,
              children: _hariList.map((hari) {
                return ChoiceChip(
                  label: Text(hari),
                  selected: _selectedHari == hari,
                  onSelected: (selected) {
                    setState(() {
                      _selectedHari = selected ? hari : null;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            Text('Status'),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('Online'),
                    leading: Radio<String>(
                      value: 'Online',
                      groupValue: _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('Offline'),
                    leading: Radio<String>(
                      value: 'Offline',
                      groupValue: _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            if (_status == 'Offline')
              TextField(
                controller: _roomNumberController,
                decoration: InputDecoration(labelText: 'Room Number'),
                keyboardType: TextInputType.number,
              ),
            if (_status == 'Online')
              TextField(
                controller: _linkController,
                decoration: InputDecoration(labelText: 'Link'),
              ),
            TextField(
              controller: _jamMulaiController,
              decoration: InputDecoration(labelText: 'Jam Mulai'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _menitMulaiController,
              decoration: InputDecoration(labelText: 'Menit Mulai'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _jamAkhirController,
              decoration: InputDecoration(labelText: 'Jam Akhir'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _menitAkhirController,
              decoration: InputDecoration(labelText: 'Menit Akhir'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _tanggalController,
              decoration: InputDecoration(labelText: 'Tanggal (yyyy-MM-dd)'),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updateJadwal,
              child: Text('Update Jadwal'),
            ),
          ],
        ),
      ),
    );
  }
}
