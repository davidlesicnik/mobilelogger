import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'vehicle.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import 'records_models.dart';

class AddExpensePage extends StatefulWidget {
  final Car car;

  const AddExpensePage({super.key, required this.car});

  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _odometerController = TextEditingController();
  final _fuelConsumedController = TextEditingController();
  bool _isFillToFull = false;
  bool _missedFuelUp = false;
  late String baseUrl;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'Gas'; // Set default category to 'Gas'
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    // Load the base URL from the login details
    final Database database = await openDatabase(
      path_helper.join(await getDatabasesPath(), 'login_database.db'),
    );
    final List<Map<String, dynamic>> maps = await database.query('login');
    if (maps.isNotEmpty) {
      final login = maps.first;
      baseUrl = login['url'];
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _getSubmitUrl();
    final body = _buildRequestBody();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        _showFeedbackDialog('Success', 'Record saved successfully.');
      } else {
        _showFeedbackDialog('Error', 'Failed to save record: ${response.body}');
      }
    } catch (e) {
      _showFeedbackDialog('Error', 'Failed to save record: $e');
    }
  }

  void _showFeedbackDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (title == 'Success') {
                  Navigator.of(context).pop();
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getSubmitUrl() {
    switch (_selectedCategory) {
      case 'Gas':
        return '$baseUrl/api/vehicle/gasrecords/add';
      case 'Service':
        return '$baseUrl/api/vehicle/servicerecords/add';
      case 'Repair':
        return '$baseUrl/api/vehicle/repairrecords/add';
      case 'Upgrade':
        return '$baseUrl/api/vehicle/upgraderecords/add';
      case 'Tax':
        return '$baseUrl/api/vehicle/taxrecords/add';
      default:
        throw Exception('Invalid category');
    }
  }

  Map<String, dynamic> _buildRequestBody() {
    final body = {
      'vehicleId': widget.car.id,
      'date': DateTime.now().toIso8601String(),
      'odometer': _odometerController.text,
      'cost': _costController.text,
      'notes': _descriptionController.text,
      'tags': '',
      'extraFields': [],
      'files': [],
    };

    if (_selectedCategory == 'Gas') {
      body.addAll({
        'fuelConsumed': _fuelConsumedController.text,
        'isFillToFull': _isFillToFull,
        'missedFuelUp': _missedFuelUp,
      });
    }

    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Expense for ${widget.car.year} ${widget.car.make} ${widget.car.model}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Select Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedCategory != null ? _getBackgroundColorForRecord(_selectedCategory!) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Gas', 'Service', 'Repair', 'Upgrade', 'Tax'].map((category) {
                    return Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            _getIconForRecordType(category),
                            color: _selectedCategory == category ? _getColorForRecordType(category) : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                        if (_selectedCategory == category)
                          Text(
                            category,
                            style: TextStyle(
                              color: _getColorForRecordType(category),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              if (_selectedCategory != null) ..._buildCategoryFields(),
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a cost' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              if (_selectedCategory == 'Gas')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          title: Text('Fill to Full'),
                          value: _isFillToFull,
                          onChanged: (value) {
                            setState(() {
                              _isFillToFull = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          title: Text('Missed Refuel'),
                          value: _missedFuelUp,
                          onChanged: (value) {
                            setState(() {
                              _missedFuelUp = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryFields() {
    switch (_selectedCategory) {
      case 'Gas':
        return [
          TextFormField(
            controller: _odometerController,
            decoration: InputDecoration(labelText: 'Odometer'),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Please enter the odometer reading' : null,
          ),
          TextFormField(
            controller: _fuelConsumedController,
            decoration: InputDecoration(labelText: 'Amount refueled (L)'),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Please enter the fuel consumed' : null,
          ),
        ];
      case 'Service':
      case 'Repair':
      case 'Upgrade':
        return [
          TextFormField(
            controller: _odometerController,
            decoration: InputDecoration(labelText: 'Odometer'),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Please enter the odometer reading' : null,
          ),
        ];
      case 'Tax':
        return [];
      default:
        return [];
    }
  }

  IconData _getIconForRecordType(String type) {
    switch (type) {
      case 'Gas':
        return Icons.local_gas_station;
      case 'Service':
        return Icons.build;
      case 'Repair':
        return Icons.car_repair;
      case 'Upgrade':
        return Icons.upgrade;
      case 'Tax':
        return Icons.receipt_long;
      default:
        return Icons.note;
    }
  }

  Color _getColorForRecordType(String type) {
    switch (type) {
      case 'Gas':
        return Colors.green;
      case 'Service':
        return Colors.blue;
      case 'Repair':
        return Colors.red;
      case 'Upgrade':
        return Colors.purple;
      case 'Tax':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getBackgroundColorForRecord(String type) {
    switch (type) {
      case 'Gas':
        return Colors.green[100]!;
      case 'Service':
        return Colors.blue[100]!;
      case 'Repair':
        return Colors.red[100]!;
      case 'Upgrade':
        return const Color.fromARGB(255, 235, 210, 240);
      case 'Tax':
        return const Color.fromARGB(255, 252, 230, 198);
      default:
        return Colors.grey[200]!;
    }
  }
}
