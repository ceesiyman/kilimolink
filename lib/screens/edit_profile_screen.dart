import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../model/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService apiService = ApiService();
  final bool useRealApi = false;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _locationController;
  late TextEditingController _roleController;
  File? _selectedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
    _locationController = TextEditingController(text: widget.user.location);
    _roleController = TextEditingController(text: widget.user.role);
    _imageUrl = widget.user.imageUrl; // Initial image URL from user data
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    String finalImageUrl = _imageUrl ?? '';
    if (_selectedImage != null) {
      finalImageUrl = useRealApi
          ? await apiService.uploadUserImageFromApi(_selectedImage!)
          : await apiService.uploadUserImage(_selectedImage!);
    }

    final success = useRealApi
        ? await apiService.updateUserProfileFromApi(
            _nameController.text,
            _usernameController.text,
            finalImageUrl,
            _locationController.text,
            _roleController.text,
          )
        : await apiService.updateUserProfile(
            _nameController.text,
            _usernameController.text,
            finalImageUrl,
            _locationController.text,
            _roleController.text,
          );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image preview and selection
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print('Error loading image: $exception');
                              },
                            )
                          : null,
                ),
                child: (_selectedImage == null && (_imageUrl == null || _imageUrl!.isEmpty))
                    ? Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'Gallery',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'Camera',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _roleController,
                decoration: InputDecoration(labelText: 'Role'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}