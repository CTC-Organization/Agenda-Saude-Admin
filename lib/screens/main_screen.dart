import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/screens/request_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests(); // Carrega a lista de itens ao iniciar a tela
  }

  // Função para buscar a lista de itens da API
  Future<void> _fetchRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('https://api-agenda-saude-2.up.railway.app/requests'),
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
        });
      }
    } else {
      // Trate o erro adequadamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todas as requisições')),
      body: _requests.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];

                return ListTile(
                  title: Text(
                      "id: ${request['id']} data: ${request['date']} id do paciente: ${request['patient']['id']} num do sus do paciente: ${request['patient']['susNumber']} status: ${request['status']} requisição criada em: ${request['createdAt']}"),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Navega para a nova tela de detalhes
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RequestDetailsScreen(requestId: request['id']),
                        ),
                      );
                    },
                    child: const Text('Visualizar Requisição'),
                  ),
                );
              },
            ),
    );
  }
}
