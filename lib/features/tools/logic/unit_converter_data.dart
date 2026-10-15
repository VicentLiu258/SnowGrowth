enum UnitCategory { length, weight, temperature, area, volume, speed, data }

class UnitConverterData {
  static const Map<UnitCategory, List<String>> units = {
    UnitCategory.length: [
      'Meter',
      'Kilometer',
      'Centimeter',
      'Millimeter',
      'Mile',
      'Yard',
      'Foot',
      'Inch',
    ],
    UnitCategory.weight: [
      'Kilogram',
      'Gram',
      'Milligram',
      'MetricTon',
      'Pound',
      'Ounce',
    ],
    UnitCategory.temperature: ['Celsius', 'Fahrenheit', 'Kelvin'],
    UnitCategory.area: ['SqMeter', 'SqKilometer', 'Hectare', 'Acre', 'SqFoot'],
    UnitCategory.volume: ['Liter', 'Milliliter', 'CubicMeter', 'GallonUS'],
    UnitCategory.speed: ['MPS', 'KMPH', 'MPH', 'Knot'],
    UnitCategory.data: ['Byte', 'Kilobyte', 'Megabyte', 'Gigabyte', 'Terabyte'],
  };

  static const Map<UnitCategory, Map<String, double>> rates = {
    UnitCategory.length: {
      'Meter': 1,
      'Kilometer': 1000,
      'Centimeter': 0.01,
      'Millimeter': 0.001,
      'Mile': 1609.344,
      'Yard': 0.9144,
      'Foot': 0.3048,
      'Inch': 0.0254,
    },
    UnitCategory.weight: {
      'Kilogram': 1,
      'Gram': 0.001,
      'Milligram': 0.000001,
      'MetricTon': 1000,
      'Pound': 0.453592,
      'Ounce': 0.0283495,
    },
    UnitCategory.area: {
      'SqMeter': 1,
      'SqKilometer': 1000000,
      'Hectare': 10000,
      'Acre': 4046.856,
      'SqFoot': 0.092903,
    },
    UnitCategory.volume: {
      'Liter': 1,
      'Milliliter': 0.001,
      'CubicMeter': 1000,
      'GallonUS': 3.785411,
    },
    UnitCategory.speed: {
      'MPS': 1,
      'KMPH': 1 / 3.6,
      'MPH': 0.44704,
      'Knot': 0.514444,
    },
    UnitCategory.data: {
      'Byte': 1,
      'Kilobyte': 1024,
      'Megabyte': 1048576,
      'Gigabyte': 1073741824,
      'Terabyte': 1099511627776,
    },
  };

  static String defaultFromUnit(UnitCategory category) {
    return units[category]!.first;
  }

  static String defaultToUnit(UnitCategory category) {
    if (category == UnitCategory.length) {
      return 'Foot';
    }
    final categoryUnits = units[category]!;
    return categoryUnits.length > 1 ? categoryUnits[1] : categoryUnits.first;
  }

  static String categoryLabel(UnitCategory category) {
    return category.name[0].toUpperCase() + category.name.substring(1);
  }

  static double convert(
    double value,
    String from,
    String to,
    UnitCategory category,
  ) {
    if (category == UnitCategory.temperature) {
      return _convertTemperature(value, from, to);
    }

    final categoryRates = rates[category];
    if (categoryRates == null ||
        !categoryRates.containsKey(from) ||
        !categoryRates.containsKey(to)) {
      return value;
    }

    return (value * categoryRates[from]!) / categoryRates[to]!;
  }

  static double _convertTemperature(double value, String from, String to) {
    double celsius;
    if (from == 'Celsius') {
      celsius = value;
    } else if (from == 'Fahrenheit') {
      celsius = (value - 32) * 5 / 9;
    } else {
      celsius = value - 273.15;
    }

    if (to == 'Celsius') return celsius;
    if (to == 'Fahrenheit') return (celsius * 9 / 5) + 32;
    return celsius + 273.15;
  }
}
