import '../models/city.dart';

class CityUtils {
  static String getCityNameFromPlate(String plateCode) {
    final city = City.cities.firstWhere(
      (c) => c.plateCode.toString() == plateCode,
      orElse: () => City(plateCode: 0, name: 'Bilinmiyor'),
    );
    return city.name;
  }
}
