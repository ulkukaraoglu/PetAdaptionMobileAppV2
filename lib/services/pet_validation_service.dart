import 'dart:convert';
import 'package:http/http.dart' as http;

class PetValidationService {
  // API anahtarlarınızı buraya ekleyin
  static const String dogApiKey = 'live_p7aXNVnSIWIPDufZGNO8I4mMGTHoEZR7hjfTJnnxSrlTKmNe5qXmW5gwZigh5Rca';
  static const String catApiKey = 'live_tmWHW7R0qo6ogi4MPhFFSduCJcAP6ixDMO5WVA6p99pRscFRlgV9ovMsOYUXAzR8';

  Future<List<String>> getDogBreeds() async {
    final response = await http.get(
      Uri.parse('https://api.thedogapi.com/v1/breeds'),
      headers: {'x-api-key': dogApiKey},
    );

    if (response.statusCode == 200) {
      final List<dynamic> breeds = json.decode(response.body);
      return breeds.map((breed) => breed['name'].toString().toLowerCase()).toList();
    } else {
      throw Exception('Failed to load dog breeds');
    }
  }

  Future<List<String>> getCatBreeds() async {
    final response = await http.get(
      Uri.parse('https://api.thecatapi.com/v1/breeds'),
      headers: {'x-api-key': catApiKey},
    );

    if (response.statusCode == 200) {
      final List<dynamic> breeds = json.decode(response.body);
      return breeds.map((breed) => breed['name'].toString().toLowerCase()).toList();
    } else {
      throw Exception('Failed to load cat breeds');
    }
  }

  Future<bool> validatePetBreed(String type, String breed) async {
    try {
      final breedLower = breed.toLowerCase();
      
      if (type.toLowerCase() == 'dog' || type.toLowerCase() == 'köpek') {
        final dogBreeds = await getDogBreeds();
        return dogBreeds.any((dogBreed) => 
          dogBreed.toLowerCase().contains(breedLower) || 
          breedLower.contains(dogBreed.toLowerCase())
        );
      } 
      else if (type.toLowerCase() == 'cat' || type.toLowerCase() == 'kedi') {
        final catBreeds = await getCatBreeds();
        return catBreeds.any((catBreed) => 
          catBreed.toLowerCase().contains(breedLower) || 
          breedLower.contains(catBreed.toLowerCase())
        );
      }
      
      return false; // Eğer tür köpek veya kedi değilse
    } catch (e) {
      print('Validation error: $e');
      return true; // API hatası durumunda doğrulama yapılamadığı için true dönüyoruz
    }
  }

  String getNormalizedType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType == 'dog' || lowerType == 'köpek') {
      return 'Köpek';
    } else if (lowerType == 'cat' || lowerType == 'kedi') {
      return 'Kedi';
    }
    return type;
  }
} 