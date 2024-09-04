import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  RequestDetailsScreenState createState() => RequestDetailsScreenState();
}

class RequestDetailsScreenState extends State<RequestDetailsScreen> {
  DateTime? _selectedDate;
  String? _selectedUSF;
  String? _selectedSpecialty;
  String? _selectedDoctor;
  List<Map<String, dynamic>> _usfs = [];
  final List<String> _specialties = [
    'Cardiologia',
    'Dermatologia',
    'Neurologia'
  ]; // Exemplo
  final List<String> _doctors = ['Dr. A', 'Dr. B', 'Dra. C']; // Exemplo

  @override
  void initState() {
    super.initState();
    _fetchUSFs(); // Carrega a lista de postos de saúde ao iniciar a tela
  }

  // Função para buscar a lista de postos de saúde
  Future<void> _fetchUSFs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('https://api-agenda-saude-2.up.railway.app/usfs'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final List<Map<String, dynamic>> usfs =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));
      if (mounted) {
        setState(() {
          _usfs = usfs;
        });
      }
    } else {
      // Trate o erro adequadamente
    }
  }

  // Função para aceitar a requisição
  Future<void> _acceptRequest() async {
    if (_selectedDate != null && _selectedUSF != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      final usf = _usfs.firstWhere((usf) => usf['id'] == _selectedUSF);
      String lat = usf['latitude'];
      String long = usf['longitude'];

      final response = await http.post(
        Uri.parse(
            'https://api-agenda-saude-2.up.railway.app/requests/accept/${widget.requestId}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'date': _selectedDate?.toIso8601String(),
          'lat': lat,
          'long': long,
          'doctorName': _selectedDoctor,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Fecha a tela após sucesso
      } else {
        // Trate o erro adequadamente
      }
    }
  }

  // Função para negar a requisição
  Future<void> _denyRequest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.patch(
      Uri.parse(
          'https://api-agenda-saude-2.up.railway.app/requests/deny/${widget.requestId}'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // Fecha a tela após sucesso
    } else {
      // Trate o erro adequadamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Requisição')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: const Text('Escolher Data'),
            ),
            if (_usfs.isNotEmpty)
              DropdownButton<String>(
                hint: const Text('Selecionar Posto de Saúde'),
                value: _selectedUSF,
                items: _usfs.map((usf) {
                  return DropdownMenuItem(
                    value: usf['id'].toString(),
                    child: Text(usf['nome']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUSF = value;
                  });
                },
              ),
            DropdownButton<String>(
              hint: const Text('Selecionar Especialidade'),
              value: _selectedSpecialty,
              items: _specialties.map((specialty) {
                return DropdownMenuItem(
                  value: specialty,
                  child: Text(specialty),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSpecialty = value;
                });
              },
            ),
            DropdownButton<String>(
              hint: const Text('Selecionar Médico'),
              value: _selectedDoctor,
              items: _doctors.map((doctor) {
                return DropdownMenuItem(
                  value: doctor,
                  child: Text(doctor),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDoctor = value;
                });
              },
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _acceptRequest,
                  child: const Text('Aceitar Requisição'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _denyRequest,
                  child: const Text('Negar Requisição'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
