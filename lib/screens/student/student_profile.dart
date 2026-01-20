import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Student {
  final String email;
  final String? parentName;
  final String fullname;
  final String? studentId;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? admissionDate;
  final String? profilePicture;
  final String? residentialAddress;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactNo;
  final String? nationality;
  final String? fatherName;
  final String? motherName;
  final String? bloodGroup;
  final String? classId;
  final String? parent;
  final String? section;

  Student({
    required this.email,
    this.parentName,
    required this.fullname,
    this.studentId,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.admissionDate,
    this.profilePicture,
    this.residentialAddress,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactNo,
    this.nationality,
    this.fatherName,
    this.motherName,
    this.bloodGroup,
    this.classId,
    this.parent,
    this.section,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      email: json['email'] ?? '',
      parentName: json['parent_name'],
      fullname: json['fullname'] ?? '',
      studentId: json['student_id'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      admissionDate: json['admission_date'],
      profilePicture: json['profile_picture'],
      residentialAddress: json['residential_address'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      emergencyContactNo: json['emergency_contact_no'],
      nationality: json['nationality'],
      fatherName: json['father_name'],
      motherName: json['mother_name'],
      bloodGroup: json['blood_group'],
      classId: json['class_id'],
      parent: json['parent'],
      section: json['section'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'parent_name': parentName,
      'fullname': fullname,
      'student_id': studentId,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'admission_date': admissionDate,
      'profile_picture': profilePicture,
      'residential_address': residentialAddress,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_relationship': emergencyContactRelationship,
      'emergency_contact_no': emergencyContactNo,
      'nationality': nationality,
      'father_name': fatherName,
      'mother_name': motherName,
      'blood_group': bloodGroup,
      'class_id': classId,
      'parent': parent,
      'section': section,
    };
  }
}

class ClassInfo {
  final int id;
  final String className;
  final String sec;

  ClassInfo({required this.id, required this.className, required this.sec});

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] ?? 0,
      className: json['class_name'] ?? '',
      sec: json['sec'] ?? '',
    );
  }
}

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with SingleTickerProviderStateMixin {
  Student? student;
  Student? originalStudent;
  ClassInfo? classInfo;
  String error = '';
  bool isSaving = false;
  bool showSuccessPopup = false;
  File? profileFile;
  String? previewUrl;
  bool isEditing = false;
  Map<String, String> validationErrors = {};
  bool isLoading = true;
  late TabController _tabController;

  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/students/';
  final String classesApiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/classes/';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchStudent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> getLoggedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = prefs.getString('userInfo');
      final userData = prefs.getString('userData');
      final email = prefs.getString('user_email');

      if (userInfo != null) {
        final parsed = json.decode(userInfo);
        return parsed['email'] ?? email;
      }
      if (userData != null) {
        final parsed = json.decode(userData);
        return parsed['email'] ?? email;
      }
      return email;
    } catch (e) {
      return null;
    }
  }

  bool validateForm() {
    validationErrors.clear();

    if (student?.fullname?.trim().isEmpty ?? true) {
      validationErrors['fullname'] = 'Full name is required';
    }

    if (student?.phone != null && student!.phone!.isNotEmpty) {
      final phoneRegex = RegExp(r'^[\+]?[1-9][\d]{0,15}$');
      if (!phoneRegex.hasMatch(student!.phone!.replaceAll(RegExp(r'\s'), ''))) {
        validationErrors['phone'] = 'Please enter a valid phone number';
      }
    }

    if (student?.emergencyContactNo != null &&
        student!.emergencyContactNo!.isNotEmpty) {
      final phoneRegex = RegExp(r'^[\+]?[1-9][\d]{0,15}$');
      if (!phoneRegex.hasMatch(
        student!.emergencyContactNo!.replaceAll(RegExp(r'\s'), ''),
      )) {
        validationErrors['emergency_contact_no'] =
            'Please enter a valid emergency contact number';
      }
    }

    if (student?.email != null && student!.email.isNotEmpty) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(student!.email)) {
        validationErrors['email'] = 'Please enter a valid email address';
      }
    }

    setState(() {});
    return validationErrors.isEmpty;
  }

  Future<void> fetchStudent() async {
    final email = await getLoggedEmail();
    if (email == null) {
      setState(() {
        error = 'Student email not found in localStorage';
        isLoading = false;
      });
      return;
    }

    try {
      setState(() => isLoading = true);

      final response = await http.get(Uri.parse('$apiBase$email/'));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch student');
      }

      final data = json.decode(response.body);
      final studentData = data is List ? data[0] : data;

      setState(() => student = Student.fromJson(studentData));
      originalStudent = Student.fromJson(studentData);

      // Fetch class information if class_id exists
      if (studentData['class_id'] != null) {
        try {
          final classResponse = await http.get(
            Uri.parse('$classesApiBase${studentData['class_id']}/'),
          );
          if (classResponse.statusCode == 200) {
            final classData = json.decode(classResponse.body);
            setState(() => classInfo = ClassInfo.fromJson(classData));
          }
        } catch (e) {
          // Silently fail if class info can't be fetched
        }
      }

      if (studentData['profile_picture'] != null) {
        previewUrl = studentData['profile_picture'].startsWith('http')
            ? studentData['profile_picture']
            : 'https://school.globaltechsoftwaresolutions.cloud/api${studentData['profile_picture']}';
      }
    } catch (e) {
      setState(() => error = 'An error occurred while loading profile');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleFileChange() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Validate file size (5MB max)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          setState(() => error = 'File size must be less than 5MB');
          return;
        }

        setState(() {
          profileFile = file;
          previewUrl = file.path;
          error = '';
        });
      }
    } catch (e) {
      setState(() => error = 'Error selecting image');
    }
  }

  bool hasChanges() {
    if (student == null || originalStudent == null) return false;
    if (profileFile != null) return true;
    return json.encode(student!.toJson()) !=
        json.encode(originalStudent!.toJson());
  }

  Future<void> handleSave() async {
    if (student == null || !validateForm()) return;

    setState(() => isSaving = true);

    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$apiBase${student!.email}/'),
      );

      // Add profile picture if selected
      if (profileFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profileFile!.path,
          ),
        );
      }

      // Add only changed fields
      if (student!.fullname != originalStudent?.fullname) {
        request.fields['fullname'] = student!.fullname;
      }
      if (student!.phone != originalStudent?.phone) {
        request.fields['phone'] = student!.phone ?? '';
      }
      if (student!.dateOfBirth != originalStudent?.dateOfBirth) {
        request.fields['date_of_birth'] = student!.dateOfBirth ?? '';
      }
      if (student!.gender != originalStudent?.gender) {
        request.fields['gender'] = student!.gender ?? '';
      }
      if (student!.nationality != originalStudent?.nationality) {
        request.fields['nationality'] = student!.nationality ?? '';
      }
      if (student!.bloodGroup != originalStudent?.bloodGroup) {
        request.fields['blood_group'] = student!.bloodGroup ?? '';
      }
      if (student!.fatherName != originalStudent?.fatherName) {
        request.fields['father_name'] = student!.fatherName ?? '';
      }
      if (student!.motherName != originalStudent?.motherName) {
        request.fields['mother_name'] = student!.motherName ?? '';
      }
      if (student!.residentialAddress != originalStudent?.residentialAddress) {
        request.fields['residential_address'] =
            student!.residentialAddress ?? '';
      }
      if (student!.emergencyContactName !=
          originalStudent?.emergencyContactName) {
        request.fields['emergency_contact_name'] =
            student!.emergencyContactName ?? '';
      }
      if (student!.emergencyContactRelationship !=
          originalStudent?.emergencyContactRelationship) {
        request.fields['emergency_contact_relationship'] =
            student!.emergencyContactRelationship ?? '';
      }
      if (student!.emergencyContactNo != originalStudent?.emergencyContactNo) {
        request.fields['emergency_contact_no'] =
            student!.emergencyContactNo ?? '';
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final statusCode = response.statusCode;

      if (statusCode != 200 && statusCode != 201) {
        throw Exception('Failed to update student: $statusCode');
      }

      final updatedData = json.decode(responseData);
      setState(() {
        student = Student.fromJson(updatedData);
        originalStudent = Student.fromJson(updatedData);
      });

      if (profileFile != null && updatedData['profile_picture'] != null) {
        previewUrl = updatedData['profile_picture'].startsWith('http')
            ? updatedData['profile_picture']
            : 'https://school.globaltechsoftwaresolutions.cloud/api${updatedData['profile_picture']}';
      }

      setState(() {
        showSuccessPopup = true;
        isEditing = false;
        profileFile = null;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => showSuccessPopup = false);
        }
      });
    } catch (e) {
      setState(() => error = 'An error occurred while saving');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void handleCancel() {
    setState(() {
      isEditing = false;
      profileFile = null;
      validationErrors.clear();
      if (originalStudent != null) {
        student = Student.fromJson(originalStudent!.toJson());
        if (originalStudent!.profilePicture != null) {
          previewUrl = originalStudent!.profilePicture!.startsWith('http')
              ? originalStudent!.profilePicture!
              : 'https://school.globaltechsoftwaresolutions.cloud/api${originalStudent!.profilePicture!}';
        } else {
          previewUrl = null;
        }
      }
    });
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: Colors.grey[50],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading student profile...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (student == null) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Profile Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unable to load student profile.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: fetchStudent,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.blue[50]!],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Profile',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your personal information and settings',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            if (error.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Success Popup
            if (showSuccessPopup) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Profile updated successfully!',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Single Column Layout
            Column(
              children: [
                // Profile Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[600]!, Colors.blue[700]!],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.white,
                                  backgroundImage: previewUrl != null
                                      ? (previewUrl!.startsWith('http')
                                            ? NetworkImage(previewUrl!)
                                            : FileImage(File(previewUrl!))
                                                  as ImageProvider)
                                      : null,
                                  child: previewUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 48,
                                          color: Colors.blue,
                                        )
                                      : null,
                                ),
                                if (isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: handleFileChange,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              student!.fullname.isNotEmpty
                                  ? student!.fullname
                                  : 'Unnamed Student',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student!.email,
                              style: TextStyle(
                                color: Colors.blue[100],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ID: ${student!.studentId ?? 'Not assigned'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile Stats
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildProfileField(
                              'Class',
                              classInfo?.className ??
                                  student!.classId ??
                                  'Not assigned',
                            ),
                            _buildProfileField(
                              'Section',
                              classInfo?.sec ??
                                  student!.section ??
                                  'Not assigned',
                            ),
                            _buildProfileField(
                              'Admission Date',
                              formatDate(student!.admissionDate),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            if (!isEditing) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      setState(() => isEditing = true),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: isSaving || !hasChanges()
                                          ? null
                                          : handleSave,
                                      icon: isSaving
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.save),
                                      label: Text(
                                        isSaving ? 'Saving...' : 'Save Changes',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: isSaving ? null : handleCancel,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        side: const BorderSide(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main Content Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Personal Information'),
                            Tab(text: 'Family Details'),
                            Tab(text: 'Emergency Contact'),
                          ],
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                        ),
                      ),

                      // Tab Content
                      SizedBox(
                        height: 600, // Fixed height for tabs
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Personal Information Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Personal Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildFormGrid([
                                    _buildTextField(
                                      'Full Name *',
                                      'fullname',
                                      student!.fullname,
                                      validationErrors['fullname'],
                                    ),
                                    _buildReadOnlyField(
                                      'Student ID',
                                      student!.studentId ?? 'Not assigned',
                                    ),
                                    _buildTextField(
                                      'Email Address',
                                      'email',
                                      student!.email,
                                      validationErrors['email'],
                                    ),
                                    _buildTextField(
                                      'Phone Number',
                                      'phone',
                                      student!.phone ?? '',
                                      validationErrors['phone'],
                                    ),
                                    _buildDateField(
                                      'Date of Birth',
                                      'date_of_birth',
                                      student!.dateOfBirth,
                                    ),
                                    _buildDropdownField(
                                      'Gender',
                                      'gender',
                                      student!.gender ?? '',
                                      ['Male', 'Female', 'Other'],
                                    ),
                                    _buildTextField(
                                      'Nationality',
                                      'nationality',
                                      student!.nationality ?? '',
                                    ),
                                    _buildTextField(
                                      'Blood Group',
                                      'blood_group',
                                      student!.bloodGroup ?? '',
                                    ),
                                    _buildReadOnlyField(
                                      'Section',
                                      classInfo?.sec ??
                                          student!.section ??
                                          'Not assigned',
                                    ),
                                  ]),
                                  const SizedBox(height: 24),
                                  _buildTextAreaField(
                                    'Residential Address',
                                    'residential_address',
                                    student!.residentialAddress ?? '',
                                  ),
                                ],
                              ),
                            ),

                            // Family Details Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Family Information',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildFormGrid([
                                    _buildTextField(
                                      "Father's Name",
                                      'father_name',
                                      student!.fatherName ?? '',
                                    ),
                                    _buildTextField(
                                      "Mother's Name",
                                      'mother_name',
                                      student!.motherName ?? '',
                                    ),
                                    _buildTextField(
                                      'Parent/Guardian Name',
                                      'parent_name',
                                      student!.parentName ?? '',
                                    ),
                                    _buildTextField(
                                      'Parent Contact',
                                      'parent',
                                      student!.parent ?? '',
                                    ),
                                  ]),
                                ],
                              ),
                            ),

                            // Emergency Contact Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Emergency Contact',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildFormGrid([
                                    _buildTextField(
                                      'Contact Name',
                                      'emergency_contact_name',
                                      student!.emergencyContactName ?? '',
                                    ),
                                    _buildTextField(
                                      'Relationship',
                                      'emergency_contact_relationship',
                                      student!.emergencyContactRelationship ??
                                          '',
                                    ),
                                    _buildTextField(
                                      'Contact Number',
                                      'emergency_contact_no',
                                      student!.emergencyContactNo ?? '',
                                      validationErrors['emergency_contact_no'],
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormGrid(List<Widget> children) {
    // Simple single column layout like a div
    return Column(
      children: children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTextField(
    String label,
    String name,
    String value, [
    String? error,
  ]) {
    return SizedBox(
      height: error != null ? 90 : 70, // Fixed height to prevent overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextFormField(
              initialValue: value,
              readOnly: !isEditing,
              onChanged: (newValue) {
                setState(() {
                  switch (name) {
                    case 'fullname':
                      student = student!.copyWith(fullname: newValue);
                      break;
                    case 'email':
                      student = student!.copyWith(email: newValue);
                      break;
                    case 'phone':
                      student = student!.copyWith(phone: newValue);
                      break;
                    case 'nationality':
                      student = student!.copyWith(nationality: newValue);
                      break;
                    case 'blood_group':
                      student = student!.copyWith(bloodGroup: newValue);
                      break;
                    case 'father_name':
                      student = student!.copyWith(fatherName: newValue);
                      break;
                    case 'mother_name':
                      student = student!.copyWith(motherName: newValue);
                      break;
                    case 'parent_name':
                      student = student!.copyWith(parentName: newValue);
                      break;
                    case 'parent':
                      student = student!.copyWith(parent: newValue);
                      break;
                    case 'emergency_contact_name':
                      student = student!.copyWith(
                        emergencyContactName: newValue,
                      );
                      break;
                    case 'emergency_contact_relationship':
                      student = student!.copyWith(
                        emergencyContactRelationship: newValue,
                      );
                      break;
                    case 'emergency_contact_no':
                      student = student!.copyWith(emergencyContactNo: newValue);
                      break;
                    case 'residential_address':
                      student = student!.copyWith(residentialAddress: newValue);
                      break;
                  }
                });
                if (validationErrors[name] != null) {
                  setState(() => validationErrors.remove(name));
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: error != null ? Colors.red : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: error != null ? Colors.red : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: error != null ? Colors.red : Colors.blue,
                  ),
                ),
                filled: !isEditing,
                fillColor: isEditing ? Colors.white : Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String name, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value ?? '',
          readOnly: !isEditing,
          onTap: isEditing
              ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: value != null && value.isNotEmpty
                        ? DateTime.parse(value)
                        : DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final formattedDate =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    setState(() {
                      student = student!.copyWith(dateOfBirth: formattedDate);
                    });
                  }
                }
              : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            filled: !isEditing,
            fillColor: isEditing ? Colors.white : Colors.grey[50],
            suffixIcon: isEditing ? const Icon(Icons.calendar_today) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String name,
    String value,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: isEditing ? Colors.white : Colors.grey[50],
          ),
          child: isEditing
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: value.isNotEmpty ? value : null,
                    hint: const Text('Select option'),
                    items: options.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        switch (name) {
                          case 'gender':
                            student = student!.copyWith(gender: newValue);
                            break;
                        }
                      });
                    },
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    value.isNotEmpty ? value : 'Not specified',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(String label, String name, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          readOnly: !isEditing,
          maxLines: 3,
          onChanged: (newValue) {
            setState(() {
              student = student!.copyWith(residentialAddress: newValue);
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            filled: !isEditing,
            fillColor: isEditing ? Colors.white : Colors.grey[50],
          ),
        ),
      ],
    );
  }
}

// Extension to copy Student object
extension StudentCopyWith on Student {
  Student copyWith({
    String? email,
    String? parentName,
    String? fullname,
    String? studentId,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? admissionDate,
    String? profilePicture,
    String? residentialAddress,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactNo,
    String? nationality,
    String? fatherName,
    String? motherName,
    String? bloodGroup,
    String? classId,
    String? parent,
    String? section,
  }) {
    return Student(
      email: email ?? this.email,
      parentName: parentName ?? this.parentName,
      fullname: fullname ?? this.fullname,
      studentId: studentId ?? this.studentId,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      admissionDate: admissionDate ?? this.admissionDate,
      profilePicture: profilePicture ?? this.profilePicture,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactNo: emergencyContactNo ?? this.emergencyContactNo,
      nationality: nationality ?? this.nationality,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      classId: classId ?? this.classId,
      parent: parent ?? this.parent,
      section: section ?? this.section,
    );
  }
}
