import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class AdminProfileData {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String joinDate;
  final String address;
  final String profilePicture;

  AdminProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.joinDate,
    required this.address,
    required this.profilePicture,
  });

  AdminProfileData copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? department,
    String? joinDate,
    String? address,
    String? profilePicture,
  }) {
    return AdminProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      department: department ?? this.department,
      joinDate: joinDate ?? this.joinDate,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';
  final ImagePicker _picker = ImagePicker();

  AdminProfileData? _profileData;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String _errorMessage = '';
  File? _selectedImage;
  bool _showSuccessMessage = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null || email.isEmpty) {
        throw Exception('No admin email found. Please log in again.');
      }

      // Try admin endpoint first, fallback to users endpoint
      var response = await http.get(
        Uri.parse('$apiBaseUrl/admins/$email/'),
        headers: {'Content-Type': 'application/json'},
      );

      // If admin endpoint fails, try users endpoint
      if (response.statusCode != 200) {
        response = await http.get(
          Uri.parse('$apiBaseUrl/users/$email/'),
          headers: {'Content-Type': 'application/json'},
        );
      }

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Format join date
        String joinDate = '';
        if (data['user_details']?['created_at'] != null) {
          try {
            final dt = DateTime.parse(data['user_details']['created_at']);
            joinDate =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          } catch (e) {
            joinDate = data['user_details']['created_at'].toString().split(
              ' ',
            )[0];
          }
        }

        final profileData = AdminProfileData(
          name:
              data['fullname'] ??
              data['user_details']?['email']?.split('@')[0] ??
              '',
          email: data['email'] ?? data['user_details']?['email'] ?? '',
          phone: data['phone'] ?? '',
          role: data['user_details']?['role'] ?? 'Admin',
          department: data['department'] ?? 'School Administration',
          joinDate: joinDate,
          address: data['office_address'] ?? '',
          profilePicture: data['profile_picture'] ?? '',
        );

        setState(() {
          _profileData = profileData;
          _nameController.text = profileData.name;
          _phoneController.text = profileData.phone;
          _departmentController.text = profileData.department;
          _addressController.text = profileData.address;
        });
      } else {
        throw Exception(
          'Failed to load admin profile. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadProfilePicture();
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', isError: true);
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null || email.isEmpty) {
        throw Exception('No admin email found. Please log in again.');
      }

      // Validate file size (max 5MB)
      final fileSize = await _selectedImage!.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image size should be less than 5MB');
      }

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$apiBaseUrl/admins/$email/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          _selectedImage!.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _profileData = _profileData?.copyWith(
            profilePicture:
                data['profile_picture'] ?? _profileData!.profilePicture,
          );
          _selectedImage = null;
        });
        _showSnackBar('Profile picture updated successfully!');
      } else {
        throw Exception('Failed to upload profile picture');
      }
    } catch (e) {
      _showSnackBar('Error uploading profile picture: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null || email.isEmpty) {
        throw Exception('No admin email found. Please log in again.');
      }

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$apiBaseUrl/admins/$email/'),
      );

      request.fields['fullname'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['office_address'] = _addressController.text;
      request.fields['department'] = _departmentController.text;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _profileData = _profileData?.copyWith(
            name: data['fullname'] ?? _nameController.text,
            phone: data['phone'] ?? _phoneController.text,
            address: data['office_address'] ?? _addressController.text,
            department: data['department'] ?? _departmentController.text,
          );
          _isEditing = false;
          _showSuccessMessage = true;
        });

        // Auto-hide success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccessMessage = false;
            });
          }
        });

        _showSnackBar('Profile updated successfully!');
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      _showSnackBar('Error saving profile: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profileData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success message
              if (_showSuccessMessage)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Profile updated successfully!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_profileData!.profilePicture.isNotEmpty
                                        ? NetworkImage(
                                            _profileData!.profilePicture,
                                          )
                                        : const NetworkImage(
                                            'https://via.placeholder.com/120x120/cccccc/666666?text=No+Image',
                                          ))
                                    as ImageProvider,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: InkWell(
                                onTap: _pickImage,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text('Change Profile Picture'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Profile Information Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: _profileData!.email,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: _profileData!.role,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(Icons.work),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _departmentController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: _profileData!.joinDate,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Join Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        enabled: _isEditing,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
