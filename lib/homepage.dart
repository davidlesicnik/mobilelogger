import 'package:flutter/material.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  final List<dynamic>? vehiclesData;

  const HomePage({super.key, this.vehiclesData});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Vehicle> vehicles = [];

  @override
  void initState() {
    super.initState();
    vehicles =
        widget.vehiclesData!.map((data) => Vehicle.fromJson(data)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles found'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    title: Text(
                      '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'License Plate: ${vehicle.licensePlate}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      // Handle tap on vehicle
                    },
                  ),
                );
              },
            ),
    );
  }
}