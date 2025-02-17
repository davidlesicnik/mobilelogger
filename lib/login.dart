import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path_helper;
import 'package:sqflite/sqflite.dart';
import 'homepage.dart';
import 'vehicle.dart'; // Import the Car class

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _rememberMe = false;
  Database? _database;
  Future<void>? _loginFuture;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      path_helper.join(await getDatabasesPath(), 'login_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE login(id INTEGER PRIMARY KEY, username TEXT, password TEXT, url TEXT)',
        );
      },
      version: 1,
    );

    await _loadSavedLogin();
  }

  Future<void> _loadSavedLogin() async {
    if (_database == null) return;

    final List<Map<String, dynamic>> maps = await _database!.query('login');
    if (maps.isNotEmpty) {
      final login = maps.first;
      _usernameController.text = login['username'];
      _passwordController.text = login['password'];
      _urlController.text = login['url'];
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveLogin(String username, String password, String url) async {
    if (_database != null && _rememberMe) {
      // First, delete any existing login data
      await _database!.delete('login');

      // Then insert the new login data
      await _database!.insert(
        'login',
        {'username': username, 'password': password, 'url': url},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _login() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final String url = _urlController.text.trim();

    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    try {
      final response = await http.get(
        Uri.parse('$url/api/vehicles'),
        headers: <String, String>{
          'authorization': basicAuth,
        },
      );

      if (response.statusCode == 200) {
        if (_rememberMe) {
          await _saveLogin(username, password, url);
        }

        final List<dynamic> vehiclesData = json.decode(response.body);
        final List<Car> cars =
            vehiclesData.map((data) => Car.fromJson(data)).toList();

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => HomePage(cars: cars),
          ),
        );
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Login Failed'),
            content: const Text('Invalid username, password, or URL.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Error'),
          content: Text('An error occurred: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(labelText: 'URL'),
            ),
            Row(
              children: <Widget>[
                Checkbox(
                  value: _rememberMe,
                  onChanged: (bool? value) {
                    setState(() {
                      _rememberMe = value!;
                    });
                  },
                ),
                Text('Remember Me'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loginFuture = _login();
                });
              },
              child: Text('Login'),
            ),
            if (_loginFuture != null)
              FutureBuilder<void>(
                future: _loginFuture,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else {
                    return Container();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
