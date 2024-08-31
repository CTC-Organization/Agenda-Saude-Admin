import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _checkLoggedIn(); // Verifica se o usuário está logado ao iniciar a tela
  }

  Future<void> _checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    String? refreshToken = prefs.getString('refreshToken');

    if (accessToken != null && refreshToken != null) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://nestjs-copy-production.up.railway.app/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _senhaController.text,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('accessToken') &&
            responseData.containsKey('refreshToken')) {
          final accessToken = responseData['accessToken'];
          final refreshToken = responseData['refreshToken'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          await prefs.setString('refreshToken', refreshToken);

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          throw Exception('Tokens not found in the response');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao realizar o login 1')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        logger.d('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao realizar o login 2: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
