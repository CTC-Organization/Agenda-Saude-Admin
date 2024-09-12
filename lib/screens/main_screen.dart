import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:myapp/screens/request_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  var logger = Logger();
  bool sortAscending = true; // Variável para armazenar a ordem de classificação
  String? _selectedStatus; // Variável para armazenar o status selecionado

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

  final List<String> _statusOptions = [
    'Todos',
    'PENDING',
    'DENIED',
    'ACCEPTED',
    'CONFIRMED',
    'CANCELLED'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequests(); // Carrega a lista de itens ao iniciar a tela
  }

  // Função para buscar a lista de itens da API
  Future<void> _fetchRequests() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse("${dotenv.env['API_URL']}/requests"),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final List<Map<String, dynamic>> requests =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));
        if (mounted) {
          setState(() {
            _requests = requests;
            _filteredRequests = requests; // Inicialmente exibe todas
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        throw Exception('Erro no login');
      }
    } catch (e) {
      logger.d('Erro no login: $e');
    }
  }

  // Função para ordenar os dados
  void _sortRequests() {
    setState(() {
      sortAscending = !sortAscending;
      _filteredRequests.sort((a, b) {
        DateTime dateA = DateTime.parse(a['createdAt']);
        DateTime dateB = DateTime.parse(b['createdAt']);
        return sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    });
  }

  // Função para filtrar os requests com base no status selecionado
  void _filterRequests(String? status) {
    setState(() {
      if (status == 'Todos' || status == null) {
        _filteredRequests = _requests; // Exibe todas as requisições
      } else {
        _filteredRequests = _requests
            .where((request) => request['status'] == status)
            .toList(); // Filtra pelo status selecionado
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas as requisições'),
        backgroundColor: Colors.deepPurple, // Cor personalizada no AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtro de status
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filtrar por status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedStatus,
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newStatus) {
                  setState(() {
                    _selectedStatus = newStatus;
                    _filterRequests(newStatus); // Aplica o filtro
                  });
                },
              ),
            ),
            Expanded(
              child: _filteredRequests.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            sortColumnIndex: 5, // Índice da coluna 'createdAt'
                            sortAscending:
                                sortAscending, // Define se está ordenando de forma ascendente
                            columns: [
                              const DataColumn(label: Text('ID')),
                              const DataColumn(label: Text('Data')),
                              const DataColumn(label: Text('ID do Paciente')),
                              const DataColumn(
                                  label: Text('NIS (número do SUS)')),
                              const DataColumn(label: Text('Status')),
                              DataColumn(
                                label: const Text('Criado em'),
                                onSort: (int columnIndex, bool ascending) {
                                  _sortRequests(); // Chama a função para ordenar quando a coluna for clicada
                                },
                              ),
                              const DataColumn(label: Text('Ação')),
                            ],
                            rows: _filteredRequests.map((request) {
                              return DataRow(cells: [
                                DataCell(Text(request['id'].toString())),
                                DataCell(Text(formatDate(request['date']))),
                                DataCell(
                                    Text(request['patient']['id'].toString())),
                                DataCell(Text(request['patient']['susNumber']
                                    .toString())),
                                DataCell(Text(request['status'])),
                                DataCell(
                                    Text(formatDate(request['createdAt']))),
                                DataCell(
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .deepPurple, // Cor de fundo do botão
                                      foregroundColor:
                                          Colors.white, // Cor do texto do botão
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RequestDetailsScreen(
                                                  requestId: request['id']),
                                        ),
                                      );
                                    },
                                    child: const Text('Visualizar Requisição'),
                                  ),
                                )
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
