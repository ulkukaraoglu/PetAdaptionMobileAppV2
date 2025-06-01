import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/pet.dart';
import '../models/city.dart';
import '../services/pet_validation_service.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({Key? key}) : super(key: key);

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isUrgent = false;
  int? _selectedCityPlateCode;
  List<XFile>? _imageFiles;
  bool _isLoading = false;
  bool _isValidating = false;
  String? _breedError;
  final _validationService = PetValidationService();

  // Renk tanımlamaları
  final Color primaryOrange = Color(0xFFFF8C00);
  final Color darkGrey = Color(0xFF333333);
  final Color modalBackground = Color(0xFF333333).withOpacity(0.95);

  @override
  void initState() {
    super.initState();
    _typeController.addListener(_onTypeChanged);
    _breedController.addListener(_onBreedChanged);
  }

  @override
  void dispose() {
    _typeController.removeListener(_onTypeChanged);
    _breedController.removeListener(_onBreedChanged);
    _nameController.dispose();
    _typeController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTypeChanged() {
    if (_breedController.text.isNotEmpty) {
      _validateBreed();
    }
  }

  void _onBreedChanged() {
    if (_breedController.text.isNotEmpty && _typeController.text.isNotEmpty) {
      _validateBreed();
    }
  }

  Future<void> _validateBreed() async {
    if (_typeController.text.isEmpty || _breedController.text.isEmpty) return;

    setState(() {
      _isValidating = true;
      _breedError = null;
    });

    try {
      final isValid = await _validationService.validatePetBreed(
        _typeController.text,
        _breedController.text,
      );

      setState(() {
        _isValidating = false;
        if (!isValid) {
          _breedError = 'Girilen cins, seçilen türle uyuşmuyor';
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görsel seçilirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _selectedImage != null &&
        _selectedCityPlateCode != null) {
      
      // Tür ve cins son kontrol
      if (_breedError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lütfen geçerli bir tür ve cins kombinasyonu girin'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Normalize type (köpek/kedi)
        final normalizedType = _validationService.getNormalizedType(_typeController.text);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('pet_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        final city = City.cities
            .firstWhere((c) => c.plateCode == _selectedCityPlateCode);

        final pet = Pet(
          id: '',
          name: _nameController.text,
          type: normalizedType,
          breed: _breedController.text,
          age: int.parse(_ageController.text),
          location: city.name,
          description: _descriptionController.text,
          imageUrl: imageUrl,
          isUrgent: _isUrgent,
          createdAt: DateTime.now(),
          uid: FirebaseAuth.instance.currentUser!.uid,
        );

        await FirebaseFirestore.instance.collection('pets').add({
          'name': pet.name,
          'type': pet.type,
          'breed': pet.breed,
          'age': pet.age,
          'location': city.plateCode,
          'description': pet.description,
          'imageUrl': pet.imageUrl,
          'isUrgent': pet.isUrgent,
          'createdAt': Timestamp.fromDate(pet.createdAt),
          'uid': pet.uid,
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlan eklenirken bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir fotoğraf seçin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: modalBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Yeni İlan Ekle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'İsim',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir isim girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _typeController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tür (köpek, kedi vb.)',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir tür girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedCityPlateCode,
                  dropdownColor: darkGrey,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Şehir',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  items: City.cities.map((City city) {
                    return DropdownMenuItem<int>(
                      value: city.plateCode,
                      child: Text(city.name),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedCityPlateCode = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Lütfen bir şehir seçin';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 8),
              _buildBreedField(),
              SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Yaş',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir yaş girin';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Lütfen geçerli bir yaş girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir açıklama girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text(
                  'Acil Bakım İhtiyacı',
                  style: TextStyle(color: Colors.white),
                ),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
                activeColor: primaryOrange,
                inactiveTrackColor: Colors.white24,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'İlanı Yayınla',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fotoğraf Ekle',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildBreedField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _breedController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Cins',
            labelStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryOrange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            suffixIcon: _isValidating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  )
                : _breedError == null && _breedController.text.isNotEmpty
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen bir cins girin';
            }
            if (_breedError != null) {
              return _breedError;
            }
            return null;
          },
        ),
        if (_breedError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12),
            child: Text(
              _breedError!,
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            ),
          ),
      ],
    );
  }

  // Tür TextField'ı için validator
  String? _validateType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen bir tür girin';
    }
    return null;
  }
}
