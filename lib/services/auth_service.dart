import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  Future<User> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('https://nestjs-copy-production.up.railway.app/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: {'email': email, 'senha': senha},
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception("Falha ao realizar o login: 3");
    }
  }
}
