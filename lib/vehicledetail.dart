import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import 'records_models.dart';
import 'vehicle.dart';
import 'add_gas_record_page.dart';

class VehicleDetailPage extends StatefulWidget {
  final Car car;

  const VehicleDetailPage({
    super.key, 
    required this.car,
  });

  @override
  _VehicleDetailPageState createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  List<GasRecord> gasRecords = [];
  List<ServiceRecord> serviceRecords = [];
  List<RepairRecord> repairRecords = [];
  List<UpgradeRecord> upgradeRecords = [];
  List<TaxRecord> taxRecords = [];
  bool isLoading = true;
  String? errorMessage;

  late String basicAuth;
  Database? _database;
  late String baseUrl;

  @override
  void initState() {
    super.initState();
    _initDatabase();
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
      fetchAllRecords(baseUrl);
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Login details not found.';
      });
    }
  }

  Future<void> fetchAllRecords(String baseUrl) async {
    try {
      final responses = await Future.wait([
        fetchRecords<GasRecord>(baseUrl, 'gasrecords'),
        fetchRecords<ServiceRecord>(baseUrl, 'servicerecords'),
        fetchRecords<RepairRecord>(baseUrl, 'repairrecords'),
        fetchRecords<UpgradeRecord>(baseUrl, 'upgraderecords'),
        fetchRecords<TaxRecord>(baseUrl, 'taxrecords'),
      ]);

      setState(() {
        gasRecords = responses[0] as List<GasRecord>;
        serviceRecords = responses[1] as List<ServiceRecord>;
        repairRecords = responses[2] as List<RepairRecord>;
        upgradeRecords = responses[3] as List<UpgradeRecord>;
        taxRecords = responses[4] as List<TaxRecord>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load records: ${e.toString()}';
      });
    }
  }

  Future<List<T>> fetchRecords<T>(String baseUrl, String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/vehicle/$endpoint?vehicleId=${widget.car.id}'),
      headers: {'authorization': basicAuth},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => _fromJson<T>(json)).toList();
    }
    throw Exception('Failed to load $endpoint');
  }

  T _fromJson<T>(Map<String, dynamic> json) {
    if (T == GasRecord) {
      return GasRecord.fromJson(json) as T;
    } else if (T == ServiceRecord) {
      return ServiceRecord.fromJson(json) as T;
    } else if (T == RepairRecord) {
      return RepairRecord.fromJson(json) as T;
    } else if (T == UpgradeRecord) {
      return UpgradeRecord.fromJson(json) as T;
    } else if (T == TaxRecord) {
      return TaxRecord.fromJson(json) as T;
    } else {
      throw Exception('Unknown class');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRecords = [
      ...gasRecords.map((r) => RecordItem(record: r, type: 'Gas')),
      ...serviceRecords.map((r) => RecordItem(record: r, type: 'Service')),
      ...repairRecords.map((r) => RecordItem(record: r, type: 'Repair')),
      ...upgradeRecords.map((r) => RecordItem(record: r, type: 'Upgrade')),
      ...taxRecords.map((r) => RecordItem(record: r, type: 'Tax')),
    ]..sort((a, b) => b.record.date.compareTo(a.record.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.car.year} ${widget.car.make} ${widget.car.model}'),
        backgroundColor: Colors.green, // Set AppBar color to green
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : allRecords.isEmpty
                  ? const Center(child: Text('No records found'))
                  : ListView.builder(
                      itemCount: allRecords.length,
                      itemBuilder: (context, index) {
                        return RecordListItem(record: allRecords[index]);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGasRecordPage(vehicleId: widget.car.id.toString())),
          );
          if (result == true) {
            setState(() {
              isLoading = true;
            });
            await fetchAllRecords(baseUrl);
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green, // Set FAB color to green
      ),
    );
  }
}

class RecordListItem extends StatelessWidget {
  final RecordItem record;
  final NumberFormat currencyFormat = NumberFormat.currency(symbol: '\$');

  RecordListItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text(
          DateFormat('MMM d, yyyy').format(record.record.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.record is OdometerRecord)
              Text('Odometer: ${NumberFormat('#,###').format((record.record as OdometerRecord).odometer)} km'),
            if (record.record is GasRecord) ...[
              Text('Fuel: ${(record.record as GasRecord).fuelConsumed.toStringAsFixed(2)}L'),
              Text('Cost: ${currencyFormat.format((record.record as GasRecord).cost)}'),
              Text('Economy: ${(record.record as GasRecord).fuelEconomy.toStringAsFixed(2)} L/100km'),
            ] else if (record.record is OdometerRecord) ...[
              Text('Description: ${(record.record as OdometerRecord).description}'),
              Text('Cost: ${currencyFormat.format((record.record as OdometerRecord).cost)}'),
            ] else if (record.record is TaxRecord) ...[
              Text('Description: ${(record.record as TaxRecord).description}'),
              Text('Cost: ${currencyFormat.format((record.record as TaxRecord).cost)}'),
            ],
            if (record.record.notes != null && record.record.notes!.isNotEmpty)
              Text('Notes: ${record.record.notes}'),
          ],
        ),
        leading: Icon(
          _getIconForRecordType(record.type),
          color: _getColorForRecordType(record.type),
          size: 28,
        ),
        onTap: () {
          // TODO: Implement record detail view
        },
      ),
    );
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
}