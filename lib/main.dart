import 'package:flutter/material.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class Vehicle {
  final int id;
  final int year;
  final String make;
  final String model;
  final String licensePlate;

  Vehicle({
    required this.id,
    required this.year,
    required this.make,
    required this.model,
    required this.licensePlate,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      year: json['year'],
      make: json['make'],
      model: json['model'],
      licensePlate: json['licensePlate'],
    );
  }
}