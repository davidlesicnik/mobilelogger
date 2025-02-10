class Car {
  final int id; // Add the id field
  final int year;
  final String make;
  final String model;
  final String licensePlate;

  // Constructor
  const Car({
    required this.id, // Add the id parameter
    required this.year,
    required this.make,
    required this.model,
    required this.licensePlate,
  });

  // Factory constructor to create a Car from JSON
  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int, // Add the id field
      year: json['year'] as int,
      make: json['make'] as String,
      model: json['model'] as String,
      licensePlate: json['licensePlate'] as String,
    );
  }

  // Method to convert Car to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Add the id field
      'year': year,
      'make': make,
      'model': model,
      'licensePlate': licensePlate,
    };
  }

  // Override toString for better debugging
  @override
  String toString() {
    return 'Car{id: $id, year: $year, make: $make, model: $model, licensePlate: $licensePlate}';
  }

  // Override equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Car &&
        other.id == id && // Add the id field
        other.year == year &&
        other.make == make &&
        other.model == model &&
        other.licensePlate == licensePlate;
  }

  // Override hashCode
  @override
  int get hashCode =>
      id.hashCode ^ // Add the id field
      year.hashCode ^ 
      make.hashCode ^ 
      model.hashCode ^ 
      licensePlate.hashCode;
}