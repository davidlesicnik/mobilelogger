import 'package:flutter/material.dart';
import 'vehicle.dart'; // Import the Car class
import 'vehicledetail.dart'; // Import the VehicleDetailPage

class HomePage extends StatefulWidget {
  final List<Car>? cars;

  const HomePage({super.key, this.cars});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Car> cars = [];

  @override
  void initState() {
    super.initState();
    cars = widget.cars!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
      ),
      body: cars.isEmpty
          ? const Center(child: Text('No vehicles found'))
          : ListView.builder(
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    title: Text(
                      '${car.year} ${car.make} ${car.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'License Plate: ${car.licensePlate}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleDetailPage(
                            car: car,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}