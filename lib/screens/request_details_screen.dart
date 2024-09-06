import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:myapp/screens/image_viewer_screen.dart';
import 'package:myapp/screens/pdf_view_screen.dart';
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
  String? _selectedDoctor;
  String? _observation;
  final List<String> _doctors = ['Dr. A', 'Dr. B', 'Dra. C']; // Exemplo
  List<Map<String, dynamic>> _usfs = [];
  Map<String, dynamic>? _requestDetails;
  var logger = Logger();

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
    _fetchUSFs();
  }

  Future<void> _fetchUSFs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('https://api-agenda-saude-2.up.railway.app/usfs'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      final List<Map<String, dynamic>> usfs =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));
      setState(() {
        _usfs = usfs;
      });
    } else {
      // Trate o erro adequadamente
    }
  }

  Future<void> _fetchRequestDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse(
          'https://api-agenda-saude-2.up.railway.app/requests/${widget.requestId}'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      setState(() {
        _requestDetails = jsonDecode(response.body);
      });
    } else {
      // Trate o erro adequadamente
    }
  }

  Future<void> _acceptRequest() async {
    try {
      logger.d(
          "body: ${_selectedDate?.toIso8601String()} $_selectedDoctor $_selectedUSF");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');
      final usf = _usfs
          .firstWhere((usf) => usf['id'].toString() == _selectedUSF.toString());
      logger.d("body 2: $_selectedUSF");

      String lat = usf['latitude'].toString();
      String long = usf['longitude'].toString();

      logger.d(
          "body: $_selectedDate?.toIso8601String() $lat $long $_selectedDoctor");

      final response = await http.patch(
        Uri.parse(
            'https://api-agenda-saude-2.up.railway.app/requests/accept/${widget.requestId}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'date': '${_selectedDate?.toIso8601String()}Z',
          'latitude': lat,
          'longitude': long,
          'doctorName': _selectedDoctor,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        Navigator.pop(context); // Fecha a tela após sucesso
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        logger.d("$response.body");
        throw Exception("");
        // Trate o erro adequadamente
      }
    } catch (e) {
      logger.d('erro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _denyRequest(String observation) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.patch(
      Uri.parse(
          'https://api-agenda-saude-2.up.railway.app/requests/deny/${widget.requestId}'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'observation': observation}),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      Navigator.pop(context); // Fecha a tela após sucesso
    } else {
      // Trate o erro adequadamente
    }
  }

  void _showDenyRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Negar Requisição'),
          content: TextField(
            onChanged: (value) {
              _observation = value;
            },
            decoration:
                const InputDecoration(hintText: 'Digite o motivo (observação)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_observation != null && _observation!.isNotEmpty) {
                  _denyRequest(_observation!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _showAcceptRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aceitar Requisição'),
          content: const Text('Tem certeza?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Desistir'),
            ),
            TextButton(
              onPressed: () {
                _acceptRequest();
                Navigator.pop(context);
              },
              child: const Text('Aceitar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttachments(List<dynamic> attachments) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: attachments.map((attachment) {
        final isImage = attachment['name'].endsWith('.jpg') ||
            attachment['name'].endsWith('.jpeg') ||
            attachment['name'].endsWith('.png');
        final isPdf = attachment['name'].endsWith('.pdf');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isImage)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                              fileName: attachment['name'],
                              imageUrl: attachment['url']),
                        ),
                      );
                    },
                    child: const Text('Ver Imagem'),
                  ),
                if (isPdf)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDFViewerScreen(
                            pdfUrl: attachment['url'],
                            fileName: attachment['name'],
                          ),
                        ),
                      );
                    },
                    child: const Text('Ver PDF'),
                  ),
              ],
            ),
            Text(attachment['name']),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAcceptForm(String status) {
    if (status == "PENDING" || status == "CONFIRMED") {
      return Column(children: [
        const SizedBox(height: 16),
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
                value: "${usf['id']}",
                child: Text(usf['nome_oficial']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUSF = value;
              });
            },
          ),
        DropdownButton<String>(
          hint: const Text('Selecionar Doutor'),
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
              onPressed: _showAcceptRequestDialog,
              child: const Text('Aceitar Requisição'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _showDenyRequestDialog,
              child: const Text('Negar Requisição'),
            ),
          ],
        )
      ]);
    }
    // Retorna um widget vazio se o status não corresponder
    return const Column(
      children: [SizedBox.shrink()],
    );
  }

  Widget _buildAdminDetails(String status, String? date, String? lat,
      String? long, String? doctorName) {
    if (status != "ACCEPTED" &&
        status != "CONFIRMED" &&
        status != "COMPLETED") {
      return const Column(
        children: [SizedBox.shrink()],
      );
    }
    return Column(
      children: [
        Text('Status: $status'),
        Text('Data: $date'),
        Text('Coordenadas: $lat, $long'),
        Text('Doutor: $doctorName'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_requestDetails == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Requisição')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Especialidade: ${_requestDetails!['specialty']}'),
            Text('ID do Paciente: ${_requestDetails!['patientId']}'),
            const SizedBox(height: 16),
            _buildAttachments(_requestDetails!['attachments']),
            _buildAcceptForm(_requestDetails!['status']),
            _buildAdminDetails(
                _requestDetails!['status'],
                _requestDetails!['date'],
                _requestDetails!['latitude'],
                _requestDetails!['longitude'],
                _requestDetails!['doctorName'])
          ],
        ),
      ),
    );
  }
}
