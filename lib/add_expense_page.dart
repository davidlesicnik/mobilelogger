import 'package:flutter/material.dart';
import 'vehicle.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'Gas'; // Set default category to 'Gas'
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
                Row(
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
                        title: Text('Missed Fuel Up'),
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
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle saving the expense
                    }
                  },
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
