import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;

class AddGasRecordPage extends StatefulWidget {
  final String vehicleId;

  const AddGasRecordPage({super.key, required this.vehicleId});

  @override
  _AddGasRecordPageState createState() => _AddGasRecordPageState();
}

class _AddGasRecordPageState extends State<AddGasRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _fuelConsumedController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  bool _isFillToFull = false;
  bool _missedFuelUp = false;
  late String basicAuth;
  late String baseUrl;
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _odometerController.dispose();
    _fuelConsumedController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      path_helper.join(await getDatabasesPath(), 'login_database.db'),
    );

    await _loadLoginDetails();
  }

  Future<void> _loadLoginDetails() async {
    if (_database == null) return;

    final List<Map<String, dynamic>> maps = await _database!.query('login');
    if (maps.isNotEmpty) {
      final login = maps.first;
      final String username = login['username'];
      final String password = login['password'];
      baseUrl = login['url'];

      // Ensure the URL includes the scheme
      if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
        baseUrl = 'https://$baseUrl';
      }

      basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    } else {
      // Handle error
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String date = _dateController.text;
      final String odometer = _odometerController.text;
      final String fuelConsumed = _fuelConsumedController.text;
      final String cost = _costController.text;

      final Map<String, dynamic> gasRecord = {
        'date': date,
        'odometer': odometer,
        'fuelConsumed': fuelConsumed,
        'cost': cost,
        'isFillToFull': _isFillToFull,
        'missedFuelUp': _missedFuelUp,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/vehicle/gasrecords/add?vehicleId=${widget.vehicleId}'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': basicAuth,
        },
        body: json.encode(gasRecord),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gas record added successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add gas record')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Gas Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _odometerController,
                decoration: InputDecoration(labelText: 'Odometer'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the odometer reading';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fuelConsumedController,
                decoration: InputDecoration(labelText: 'Fuel added'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the fuel added';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(labelText: 'Cost'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the cost';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: Text('Filled To Full'),
                value: _isFillToFull,
                onChanged: (bool value) {
                  setState(() {
                    _isFillToFull = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Missed Fuel Up'),
                value: _missedFuelUp,
                onChanged: (bool value) {
                  setState(() {
                    _missedFuelUp = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
