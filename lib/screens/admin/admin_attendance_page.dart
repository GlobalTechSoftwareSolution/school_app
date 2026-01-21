import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Data Models
class Student {
  final int id;
  final String email;
  final String fullname;
  final String studentId;
  final int classId;
  final String? profilePicture;

  Student({
    required this.id,
    required this.email,
    required this.fullname,
    required this.studentId,
    required this.classId,
    this.profilePicture,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      email: json['email'],
      fullname: json['fullname'],
      studentId: json['student_id'],
      classId: json['class_id'],
      profilePicture: json['profile_picture'],
    );
  }
}

class Teacher {
  final int id;
  final String email;
  final String fullname;
  final String? profilePicture;

  Teacher({
    required this.id,
    required this.email,
    required this.fullname,
    this.profilePicture,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      email: json['email'],
      fullname: json['fullname'],
      profilePicture: json['profile_picture'],
    );
  }
}

class Principal {
  final int id;
  final String email;
  final String fullname;
  final String? profilePicture;

  Principal({
    required this.id,
    required this.email,
    required this.fullname,
    this.profilePicture,
  });

  factory Principal.fromJson(Map<String, dynamic> json) {
    return Principal(
      id: json['id'],
      email: json['email'],
      fullname: json['fullname'],
      profilePicture: json['profile_picture'],
    );
  }
}

class Admin {
  final int id;
  final String email;
  final String fullname;
  final String? profilePicture;

  Admin({
    required this.id,
    required this.email,
    required this.fullname,
    this.profilePicture,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'],
      email: json['email'],
      fullname: json['fullname'],
      profilePicture: json['profile_picture'],
    );
  }
}

class ClassData {
  final int id;
  final String className;
  final String? sec;
  final int? classId;
  final String? classTeacherName;

  ClassData({
    required this.id,
    required this.className,
    this.sec,
    this.classId,
    this.classTeacherName,
  });

  factory ClassData.fromJson(Map<String, dynamic> json) {
    return ClassData(
      id: json['id'],
      className: json['class_name'],
      sec: json['sec'],
      classId: json['class_id'],
      classTeacherName: json['class_teacher_name'],
    );
  }
}

class AttendanceRecord {
  final int id;
  final String userEmail;
  final String? userName;
  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String? role;
  final String? profilePicture;

  AttendanceRecord({
    required this.id,
    required this.userEmail,
    this.userName,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.role,
    this.profilePicture,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      userEmail: json['user_email'],
      userName: json['user_name'],
      date: json['date'],
      status: json['status'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      role: json['role'],
      profilePicture: json['profile_picture'],
    );
  }
}

class StudentAttendanceRecord {
  final int id;
  final String student;
  final String? studentName;
  final int? classId;
  final String? className;
  final String? section;
  final String date;
  final String status;
  final String? createdTime;
  final String? checkIn;
  final String? checkOut;

  StudentAttendanceRecord({
    required this.id,
    required this.student,
    this.studentName,
    this.classId,
    this.className,
    this.section,
    required this.date,
    required this.status,
    this.createdTime,
    this.checkIn,
    this.checkOut,
  });

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'],
      classId: json['class_id'],
      className: json['class_name'],
      section: json['section'],
      date: json['date'],
      status: json['status'],
      createdTime: json['created_time'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
    );
  }
}

class MergedAttendanceRecord {
  final int id;
  final String? fullname;
  final String? email;
  final String? studentId;
  final int? classId;
  final String? className;
  final String? section;
  final String? classTeacher;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? profilePicture;
  final String? userName;
  final String? userEmail;
  final String? role;

  MergedAttendanceRecord({
    required this.id,
    this.fullname,
    this.email,
    this.studentId,
    this.classId,
    this.className,
    this.section,
    this.classTeacher,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.profilePicture,
    this.userName,
    this.userEmail,
    this.role,
  });
}

class AdminAttendancePage extends StatefulWidget {
  const AdminAttendancePage({super.key});

  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  final String apiBase = 'https://school.globaltechsoftwaresolutions.cloud/api';

  // State variables
  List<Student> students = [];
  List<Teacher> teachers = [];
  Principal? principal;
  Admin? admin;
  List<ClassData> classes = [];
  List<AttendanceRecord> attendance = [];
  List<StudentAttendanceRecord> studentAttendance = [];
  String selectedClassId = "";
  bool loading = true;
  String mode = "students";
  late String adminEmail;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    adminEmail = prefs.getString('user_email') ?? '';
    selectedDate = DateTime.now();
    await loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBase/students/')),
        http.get(Uri.parse('$apiBase/teachers/')),
        http.get(Uri.parse('$apiBase/classes/')),
        http.get(Uri.parse('$apiBase/student_attendance/')),
        http.get(Uri.parse('$apiBase/attendance/')),
      ]);

      // Parse students
      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body) as List;
        students = data.map((json) => Student.fromJson(json)).toList();
      }

      // Parse teachers
      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body) as List;
        teachers = data.map((json) => Teacher.fromJson(json)).toList();
      }

      // Parse classes
      if (responses[2].statusCode == 200) {
        final data = jsonDecode(responses[2].body) as List;
        classes = data.map((json) => ClassData.fromJson(json)).toList();
      }

      // Parse student attendance
      if (responses[3].statusCode == 200) {
        final data = jsonDecode(responses[3].body) as List;
        studentAttendance = data
            .map((json) => StudentAttendanceRecord.fromJson(json))
            .toList();
      }

      // Parse general attendance
      if (responses[4].statusCode == 200) {
        final data = jsonDecode(responses[4].body) as List;
        attendance = data
            .map((json) => AttendanceRecord.fromJson(json))
            .toList();
      }

      // Try to fetch principal and admin (may not exist)
      try {
        final principalResponse = await http.get(
          Uri.parse('$apiBase/principal/'),
        );
        if (principalResponse.statusCode == 200) {
          final data = jsonDecode(principalResponse.body);
          principal = Principal.fromJson(data is List ? data[0] : data);
        }
      } catch (e) {
        // Principal API may not exist, ignore
      }

      try {
        final adminResponse = await http.get(Uri.parse('$apiBase/admin/'));
        if (adminResponse.statusCode == 200) {
          final data = jsonDecode(adminResponse.body);
          admin = Admin.fromJson(data is List ? data[0] : data);
        }
      } catch (e) {
        // Admin API may not exist, ignore
      }
    } catch (e) {
      // Handle errors
    }

    setState(() => loading = false);
  }

  List<MergedAttendanceRecord> getMergedAttendance() {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    return studentAttendance
        .map((att) {
          final student = students.firstWhere(
            (s) => s.email == att.student,
            orElse: () => Student(
              id: 0,
              email: '',
              fullname: '',
              studentId: '',
              classId: 0,
            ),
          );

          final classId = att.classId ?? student.classId;
          final cls = classes.firstWhere(
            (c) => c.id == classId,
            orElse: () => ClassData(id: 0, className: ''),
          );

          return MergedAttendanceRecord(
            id: att.id,
            fullname: att.studentName ?? student.fullname,
            email: att.student,
            studentId: student.studentId,
            classId: classId,
            className: att.className ?? cls.className,
            section: att.section ?? cls.sec,
            classTeacher: cls.classTeacherName ?? "Not Assigned",
            date: att.date,
            checkIn: att.checkIn,
            checkOut: att.checkOut,
            status: att.status,
            profilePicture: student.profilePicture,
          );
        })
        .where((item) => item.date.split('T')[0] == dateStr)
        .toList();
  }

  List<MergedAttendanceRecord> get filteredStudentAttendance {
    if (selectedClassId.isEmpty) return [];
    final classId = int.tryParse(selectedClassId);
    return getMergedAttendance().where((i) => i.classId == classId).toList();
  }

  List<MergedAttendanceRecord> get teacherAttendance {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return attendance
        .where((a) => a.role?.toLowerCase() == "teacher")
        .where((a) => a.date.split('T')[0] == dateStr)
        .map((a) {
          final teacher = teachers.firstWhere(
            (t) => t.email == a.userEmail,
            orElse: () => Teacher(id: 0, email: '', fullname: ''),
          );
          return MergedAttendanceRecord(
            id: a.id,
            userName: teacher.fullname,
            userEmail: a.userEmail,
            date: a.date,
            checkIn: a.checkIn,
            checkOut: a.checkOut,
            status: a.status,
            profilePicture: teacher.profilePicture,
            role: a.role,
          );
        })
        .toList();
  }

  List<MergedAttendanceRecord> get principalAttendance {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return attendance
        .where((a) => a.role?.toLowerCase() == "principal")
        .where((a) => a.date.split('T')[0] == dateStr)
        .map(
          (a) => MergedAttendanceRecord(
            id: a.id,
            userName: principal?.fullname ?? a.userName,
            userEmail: a.userEmail,
            date: a.date,
            checkIn: a.checkIn,
            checkOut: a.checkOut,
            status: a.status,
            profilePicture: principal?.profilePicture,
            role: a.role,
          ),
        )
        .toList();
  }

  List<MergedAttendanceRecord> get adminAttendance {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return attendance
        .where((a) => a.userEmail == adminEmail)
        .where((a) => a.date.split('T')[0] == dateStr)
        .map(
          (a) => MergedAttendanceRecord(
            id: a.id,
            userName: admin?.fullname ?? a.userName,
            userEmail: a.userEmail,
            date: a.date,
            checkIn: a.checkIn,
            checkOut: a.checkOut,
            status: a.status,
            profilePicture: admin?.profilePicture,
            role: a.role,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with date picker
            Row(
              children: [
                const Text(
                  'Select Date:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Selection Cards
            Row(
              children: [
                _buildModeCard(
                  'students',
                  'Students',
                  Icons.school,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildModeCard(
                  'teachers',
                  'Teachers',
                  Icons.person,
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildModeCard(
                  'principal',
                  'Principal',
                  Icons.account_circle,
                  Colors.purple,
                ),
                const SizedBox(width: 8),
                _buildModeCard(
                  'admin',
                  'Admin',
                  Icons.admin_panel_settings,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Area - Wrapped in Expanded to constrain height
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(String key, String label, IconData icon, Color color) {
    final isSelected = mode == key;
    final recordCount = _getRecordCount(key);

    return Flexible(
      child: InkWell(
        onTap: () => setState(() => mode = key),
        child: Card(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          elevation: isSelected ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(icon, size: 32, color: isSelected ? color : Colors.grey),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.black,
                  ),
                ),
                Text(
                  '$recordCount records',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? color : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getRecordCount(String key) {
    switch (key) {
      case 'students':
        return filteredStudentAttendance.length;
      case 'teachers':
        return teacherAttendance.length;
      case 'principal':
        return principalAttendance.length;
      case 'admin':
        return adminAttendance.length;
      default:
        return 0;
    }
  }

  Widget _buildContent() {
    switch (mode) {
      case 'students':
        return _buildStudentsContent();
      case 'teachers':
        return _buildTeachersContent();
      case 'principal':
        return _buildPrincipalContent();
      case 'admin':
        return _buildAdminContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStudentsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Attendance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Select a class to view student attendance records'),
          const SizedBox(height: 16),

          // Class Selector
          DropdownButtonFormField<String>(
            value: selectedClassId.isEmpty ? null : selectedClassId,
            decoration: const InputDecoration(
              labelText: 'Select Class',
              border: OutlineInputBorder(),
            ),
            items: classes.map((cls) {
              return DropdownMenuItem<String>(
                value: cls.id.toString(),
                child: Text('${cls.className} - ${cls.sec ?? 'N/A'}'),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedClassId = value ?? ''),
          ),
          const SizedBox(height: 16),

          // Attendance List
          selectedClassId.isEmpty
              ? const Center(child: Text('Please select a class'))
              : filteredStudentAttendance.isEmpty
              ? const Center(child: Text('No attendance records found'))
              : _buildAttendanceTable(
                  filteredStudentAttendance,
                  includeClass: true,
                ),
        ],
      ),
    );
  }

  Widget _buildTeachersContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teacher Attendance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Attendance records for teaching staff'),
          const SizedBox(height: 16),
          teacherAttendance.isEmpty
              ? const Center(child: Text('No teacher attendance records found'))
              : _buildAttendanceTable(teacherAttendance, includeClass: false),
        ],
      ),
    );
  }

  Widget _buildPrincipalContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Principal Attendance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Attendance records for principal'),
          const SizedBox(height: 16),
          principalAttendance.isEmpty
              ? const Center(
                  child: Text('No principal attendance records found'),
                )
              : _buildAttendanceTable(principalAttendance, includeClass: false),
        ],
      ),
    );
  }

  Widget _buildAdminContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Attendance',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Your attendance records ($adminEmail)'),
          const SizedBox(height: 16),
          adminAttendance.isEmpty
              ? const Center(child: Text('No admin attendance records found'))
              : _buildAttendanceTable(adminAttendance, includeClass: false),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(
    List<MergedAttendanceRecord> data, {
    required bool includeClass,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Photo')),
          const DataColumn(label: Text('Name')),
          const DataColumn(label: Text('Email')),
          if (includeClass) const DataColumn(label: Text('Class')),
          if (includeClass) const DataColumn(label: Text('Section')),
          const DataColumn(label: Text('Status')),
          const DataColumn(label: Text('Check In')),
          const DataColumn(label: Text('Check Out')),
        ],
        rows: data.map((record) {
          return DataRow(
            cells: [
              DataCell(
                _buildProfileImage(
                  record.profilePicture,
                  record.fullname ?? record.userName ?? 'Unknown',
                ),
              ),
              DataCell(Text(record.fullname ?? record.userName ?? 'Unknown')),
              DataCell(Text(record.email ?? record.userEmail ?? 'N/A')),
              if (includeClass) DataCell(Text(record.className ?? 'N/A')),
              if (includeClass) DataCell(Text(record.section ?? 'N/A')),
              DataCell(_buildStatusChip(record.status)),
              DataCell(Text(record.checkIn ?? 'Not checked in')),
              DataCell(Text(record.checkOut ?? 'Not checked out')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileImage(String? profilePicture, String name) {
    if (profilePicture != null && profilePicture.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage('$apiBase$profilePicture'),
        radius: 20,
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'present':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'absent':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'late':
        color = Colors.yellow;
        icon = Icons.access_time;
        break;
      case 'halfday':
        color = Colors.orange;
        icon = Icons.timelapse;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
      avatar: Icon(icon, color: color, size: 16),
    );
  }
}
