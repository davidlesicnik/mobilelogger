import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import 'package:intl/intl.dart';

class AddGasRecordPage extends StatefulWidget {
  final String vehicleId;

  const AddGasRecordPage({super.key, required this.vehicleId});

  @override
  AddGasRecordPageState createState() => AddGasRecordPageState();
}

class AddGasRecordPageState extends State<AddGasRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _fuelConsumedController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  bool _isFillToFull = true; // Preselect "Filled To Full" by default
  bool _missedFuelUp = false;
  late String basicAuth;
  late String baseUrl;
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Prefill with today's date
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

      if (!mounted) return;

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

  void _formatPOSInput(TextEditingController controller, String value) {
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      controller.text = '';
      return;
    }

    int number = int.parse(digitsOnly);
    String formatted = (number / 100).toStringAsFixed(2);

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String validatorMessage,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      validator: (value) => (value == null || value.isEmpty) ? validatorMessage : null,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Refueling Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextFormField(
                              controller: _dateController,
                              labelText: 'Date',
                              validatorMessage: 'Please enter a date',
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_today),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            _buildTextFormField(
                              controller: _odometerController,
                              labelText: 'Odometer',
                              validatorMessage: 'Please enter the odometer reading',
                              keyboardType: TextInputType.number, // Set numeric keyboard
                            ),
                            SizedBox(height: 16.0),
                            _buildTextFormField(
                              controller: _fuelConsumedController,
                              labelText: 'Fuel added',
                              validatorMessage: 'Please enter the fuel added',
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _formatPOSInput(_fuelConsumedController, value),
                            ),
                            SizedBox(height: 16.0),
                            _buildTextFormField(
                              controller: _costController,
                              labelText: 'Cost',
                              validatorMessage: 'Please enter the cost',
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _formatPOSInput(_costController, value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    SwitchListTile(
                      title: Text('Filled To Full'),
                      value: _isFillToFull,
                      onChanged: (bool value) {
                        setState(() {
                          _isFillToFull = value;
                        });
                      },
                      activeColor: Color(0xFF77DD77), // Pastel green color for the thumb
                      activeTrackColor: Color(0xFFD4F1D4), // Light steel blue color for the track
                    ),
                    SizedBox(height: 8.0),
                    SwitchListTile(
                      title: Text('Missed Fuel Up'),
                      value: _missedFuelUp,
                      onChanged: (bool value) {
                        setState(() {
                          _missedFuelUp = value;
                        });
                      },
                      activeColor: Color(0xFF77DD77), // Pastel green color for the thumb
                      activeTrackColor: Color(0xFFD4F1D4), // Light steel blue color for the track
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Color(0xFFA3D9A5), width: 2),
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(color: Colors.green),
                      ),
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
