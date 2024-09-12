import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:myapp/screens/image_viewer_screen.dart';
import 'package:myapp/screens/pdf_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      Uri.parse("$dotenv.env['API_URL']/usfs"),
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
      Uri.parse("$dotenv.env['API_URL']/requests/${widget.requestId}"),
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

  String formatDate(String? isoDate) {
    if (isoDate == null) {
      return 'N/A';
    }

    try {
      // Verifica o formato da data no log
      logger.d("isoDate: $isoDate");

      // Parse a data no formato UTC
      final DateTime date = DateTime.parse(isoDate).toLocal();
      logger.d("date: $date");

      // Define o formato para data e hora
      final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

      logger.d("dateFormat: $dateFormat");

      final DateFormat dayFormat = DateFormat('EEEE', 'pt_BR');
      logger.d("dayFormat: $dayFormat");

      // Retorna a data formatada
      return '${dayFormat.format(date)}, ${dateFormat.format(date)}';
    } catch (e) {
      logger.e("Error parsing date: $e");
      return 'N/A';
    }
  }

  int calculateAge(String? birthDate) {
    if (birthDate == null) {
      return -1; // Valor indicando que a idade não pode ser calculada
    }

    try {
      // Parse a data de nascimento no formato UTC
      final DateTime birthDateTime = DateTime.parse(birthDate).toLocal();
      final DateTime now = DateTime.now();

      // Calcula a diferença em anos
      int age = now.year - birthDateTime.year;
      if (now.month < birthDateTime.month ||
          (now.month == birthDateTime.month && now.day < birthDateTime.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return -1; // Valor indicando que a idade não pode ser calculada
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
        Uri.parse("$dotenv.env['API_URL']/requests/accept/${widget.requestId}"),
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
      Uri.parse("$dotenv.env['API_URL']/requests/deny/${widget.requestId}"),
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
    if (status == "PENDING") {
      return Column(children: [
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );

            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Text(_selectedDate == null
              ? 'Escolher Data'
              : 'Data escolhida: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedUSF,
          items: _usfs.map((usf) {
            return DropdownMenuItem<String>(
              value: usf['id'].toString(),
              child: Text(usf['nome_oficial']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUSF = value;
            });
          },
          decoration: const InputDecoration(labelText: 'Selecione a USF'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedDoctor,
          items: _doctors.map((doctor) {
            return DropdownMenuItem<String>(
              value: doctor,
              child: Text(doctor),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDoctor = value;
            });
          },
          decoration: const InputDecoration(labelText: 'Selecione o Médico'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_selectedDate != null &&
                _selectedUSF != null &&
                _selectedDoctor != null) {
              _showAcceptRequestDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preencha todos os campos')),
              );
            }
          },
          child: const Text('Aceitar Requisição'),
        ),
      ]);
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Requisição'),
      ),
      body: _requestDetails == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_requestDetails!['status'] == "COMPLETED" ||
                      _requestDetails!['status'] == "CONFIRMED" ||
                      _requestDetails!['status'] == "ACCEPTED")
                    Text(
                      'Data: ${formatDate(_requestDetails!['date'])}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  Text(
                    'Data de requisição: ${formatDate(_requestDetails!['createdAt'])}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Status: ${_requestDetails!['status']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Especialidade: ${_requestDetails!['specialty']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'NIS: ${_requestDetails!['patient']['susNumber']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Nome: ${_requestDetails!['patient']['user']['name']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Idade: ${calculateAge(_requestDetails!['patient']['user']['birthDate'])}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_requestDetails!['status'] != "CANCELLED")
                    _buildAttachments(_requestDetails!['attachments']),
                  const SizedBox(height: 16),
                  _buildAcceptForm(_requestDetails!['status']),
                  const SizedBox(height: 16),
                  if (_requestDetails!['status'] == "PENDING")
                    ElevatedButton(
                      onPressed: _showDenyRequestDialog,
                      child: const Text('Negar Requisição'),
                    ),
                ],
              ),
            ),
    );
  }
}
