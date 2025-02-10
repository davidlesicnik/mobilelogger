import 'package:intl/intl.dart';

class BaseRecord {
  final String id;
  final DateTime date;
  final String? notes;
  final String tags;
  final List<dynamic> extraFields;
  final List<dynamic> files;

  BaseRecord({
    required this.id,
    required this.date,
    this.notes,
    required this.tags,
    required this.extraFields,
    required this.files,
  });
}

class GasRecord extends BaseRecord {
  final int odometer;
  final double fuelConsumed;
  final double cost;
  final double fuelEconomy;
  final bool isFillToFull;
  final bool missedFuelUp;

  GasRecord({
    required super.id,
    required super.date,
    required this.odometer,
    required this.fuelConsumed,
    required this.cost,
    required this.fuelEconomy,
    required this.isFillToFull,
    required this.missedFuelUp,
    super.notes,
    required super.tags,
    required super.extraFields,
    required super.files,
  });

  factory GasRecord.fromJson(Map<String, dynamic> json) {
    return GasRecord(
      id: json['id'],
      date: DateFormat('d. MM. yyyy').parse(json['date']),
      odometer: int.parse(json['odometer']),
      fuelConsumed: double.parse(json['fuelConsumed'].replaceAll(',', '.')),
      cost: double.parse(json['cost'].replaceAll(',', '.')),
      fuelEconomy: double.parse(json['fuelEconomy'].replaceAll(',', '.')),
      isFillToFull: json['isFillToFull'].toLowerCase() == 'true',
      missedFuelUp: json['missedFuelUp'].toLowerCase() == 'true',
      notes: json['notes'],
      tags: json['tags'] ?? '',
      extraFields: json['extraFields'] ?? [],
      files: json['files'] ?? [],
    );
  }
}

class OdometerRecord extends BaseRecord {
  final int odometer;
  final double cost;
  final String description;

  OdometerRecord({
    required super.id,
    required super.date,
    required this.odometer,
    required this.cost,
    required this.description,
    super.notes,
    required super.tags,
    required super.extraFields,
    required super.files,
  });
}

class ServiceRecord extends OdometerRecord {
  ServiceRecord({
    required super.id,
    required super.date,
    required super.odometer,
    required super.description,
    required super.cost,
    super.notes,
    required super.tags,
    required super.extraFields,
    required super.files,
  });

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'],
      date: DateFormat('d. MM. yyyy').parse(json['date']),
      odometer: int.parse(json['odometer']),
      description: json['description'],
      cost: double.parse(json['cost'].replaceAll(',', '.')),
      notes: json['notes'],
      tags: json['tags'] ?? '',
      extraFields: json['extraFields'] ?? [],
      files: json['files'] ?? [],
    );
  }
}

class RepairRecord extends OdometerRecord {
  RepairRecord({
    required super.id,
    required super.date,
    required super.odometer,
    required super.description,
    required super.cost,
    super.notes,
    required super.tags,
    required super.extraFields,
    required super.files,
  });

  factory RepairRecord.fromJson(Map<String, dynamic> json) {
    return RepairRecord(
      id: json['id'],
      date: DateFormat('d. MM. yyyy').parse(json['date']),
      odometer: int.parse(json['odometer']),
      description: json['description'],
      cost: double.parse(json['cost'].replaceAll(',', '.')),
      notes: json['notes'],
      tags: json['tags'] ?? '',
      extraFields: json['extraFields'] ?? [],
      files: json['files'] ?? [],
    );
  }
}

class UpgradeRecord extends OdometerRecord {
  UpgradeRecord({
    required super.id,
    required super.date,
    required super.odometer,
    required super.description,
    required super.cost,
    super.notes,
    required super.tags,
    required super.extraFields,
    required super.files,
  });

  factory UpgradeRecord.fromJson(Map<String, dynamic> json) {
    return UpgradeRecord(
      id: json['id'],
      date: DateFormat('d. MM. yyyy').parse(json['date']),
      odometer: int.parse(json['odometer']),
      description: json['description'],
      cost: double.parse(json['cost'].replaceAll(',', '.')),
      notes: json['notes'],
      tags: json['tags'] ?? '',
      extraFields: json['extraFields'] ?? [],
      files: json['files'] ?? [],
    );
  }
}

class TaxRecord extends BaseRecord {
  final double cost;
  final String description;

  TaxRecord({
    required super.id,
    required super.date,
    required this.description,
    required this.cost,
    super.notes,
    required super.tags,
    required super.extraFields,
    required super.files,
  });

  factory TaxRecord.fromJson(Map<String, dynamic> json) {
    return TaxRecord(
      id: json['id'],
      date: DateFormat('d. MM. yyyy').parse(json['date']),
      description: json['description'],
      cost: double.parse(json['cost'].replaceAll(',', '.')),
      notes: json['notes'],
      tags: json['tags'] ?? '',
      extraFields: json['extraFields'] ?? [],
      files: json['files'] ?? [],
    );
  }
}

// Helper class for displaying records in the UI
class RecordItem {
  final BaseRecord record;
  final String type;

  RecordItem({required this.record, required this.type});
}