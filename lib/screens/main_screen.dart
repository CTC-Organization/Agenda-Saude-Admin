import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      Uri.parse('https://nestjs-copy-production.up.railway.app/requests'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      final List<Map<String, dynamic>> requests =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));
      if (mounted) {
        setState(() {
          // Atualiza a lista de itens com os dados recebidos da API
          _requests = requests;
        });
      }
    } else {
      // Trate o erro adequadamente
    }
  }

  // Função para aceitar uma requisição com o ID do request clicado
  Future<void> _acceptRequest(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.patch(
      Uri.parse(
          "https://nestjs-copy-production.up.railway.app/requests/accept/$id"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      // Atualiza a lista de itens após uma requisição bem-sucedida
      _fetchRequests();
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
              child:
                  CircularProgressIndicator()) // Exibe um indicador de carregamento enquanto a lista é carregada
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                final status = request['status'];
                final isPendingOrConfirmed =
                    status == 'PENDING' || status == 'CONFIRMED';

                return ListTile(
                  title: Text(
                      "id: ${request['id']} data: ${request['date']} id do paciente: ${request['patient']['id']} num do sus do paciente: ${request['patient']['susNumber']} status: ${request['status']}"), // Exibe os detalhes do request
                  trailing: ElevatedButton(
                    onPressed: isPendingOrConfirmed
                        ? () {
                            _acceptRequest(request[
                                'id']); // Envia o ID do request na requisição
                          }
                        : null, // Desabilita o botão se o status não for "PENDING" ou "CONFIRMED"
                    child: const Text('Aceitar Requisição'),
                  ),
                );
              },
            ),
    );
  }
}
