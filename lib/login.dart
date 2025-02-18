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
  final _formKey = GlobalKey<FormState>();
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16.0),
                Text('Logging in...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final response = await http.get(
        Uri.parse('$url/api/vehicles'),
        headers: <String, String>{
          'authorization': basicAuth,
        },
      );

      Navigator.of(context).pop(); // Close the progress dialog

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
      Navigator.of(context).pop(); // Close the progress dialog
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String validatorMessage,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorMessage;
        }
        return null;
      },
      obscureText: obscureText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to LubeLogger instance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildTextFormField(
                            controller: _usernameController,
                            labelText: 'Username',
                            validatorMessage: 'Please enter your username',
                          ),
                          SizedBox(height: 16.0),
                          _buildTextFormField(
                            controller: _passwordController,
                            labelText: 'Password',
                            validatorMessage: 'Please enter your password',
                            obscureText: true,
                          ),
                          SizedBox(height: 16.0),
                          _buildTextFormField(
                            controller: _urlController,
                            labelText: 'URL',
                            validatorMessage: 'Please enter the URL',
                          ),
                          SizedBox(height: 16.0),
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
                        ],
                      ),
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _loginFuture = _login();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      ),
                      child: Text('Login'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
