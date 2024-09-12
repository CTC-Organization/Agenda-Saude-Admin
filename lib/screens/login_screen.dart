import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _isLoading = false;

  var logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    String? refreshToken = prefs.getString('refreshToken');
    String? userId = prefs.getString('userId');

    if (accessToken != null && refreshToken != null && userId != null) {
      _refreshSession();
    }
  }

  Future<void> _refreshSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      String? refreshToken = prefs.getString('refreshToken');

      final response = await http.post(
        Uri.parse("${dotenv.env['API_URL']}/auth/refresh-token/$userId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('accessToken') &&
            responseData.containsKey('refreshToken') &&
            responseData.containsKey('userId') &&
            responseData.containsKey('role')) {
          final accessToken = responseData['accessToken'];
          final refreshToken = responseData['refreshToken'];
          final userId = responseData['userId'];
          final role = responseData['role'];

          if (role != 'ADMIN' && role != 'EMPLOYEE') {
            throw Exception('Usuário não autorizado');
          }

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          await prefs.setString('refreshToken', refreshToken);
          await prefs.setString('userId', userId);

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          throw Exception('Tokens not found in the response');
        }
      } else {
        _showError('Falha ao realizar o refresh: Credenciais inválidas');
      }
    } catch (e) {
      _showError('Falha ao realizar o refresh: $e');
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${dotenv.env['API_URL']}/auth/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _senhaController.text,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('accessToken') &&
            responseData.containsKey('refreshToken') &&
            responseData.containsKey('userId') &&
            responseData.containsKey('role')) {
          final accessToken = responseData['accessToken'];
          final refreshToken = responseData['refreshToken'];
          final userId = responseData['userId'];
          final role = responseData['role'];
          logger.d('role: $role');

          if (role != "ADMIN" && role != "EMPLOYEE") {
            throw Exception('Usuário não autorizado');
          }

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          await prefs.setString('refreshToken', refreshToken);
          await prefs.setString('userId', userId);

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          throw Exception('Tokens not found in the response');
        }
      } else {
        _showError('Falha ao realizar o login: Credenciais inválidas');
      }
    } catch (e) {
      logger.d('Error: $e');
      _showError('Falha ao realizar o login: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.deepPurple[800]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.deepPurple[800]),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: TextStyle(color: Colors.deepPurple[800]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.deepPurple[800]),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Login',
                          style: TextStyle(
                              fontSize: 18,
                              color: Color.fromRGBO(200, 200, 200, 1))),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
