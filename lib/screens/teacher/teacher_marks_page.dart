import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Data Models
class Teacher {
  final int id;
  final String email;
  final bool isClassTeacher;
  final String firstName;
  final String lastName;
  final List<dynamic>? subjects;

  Teacher({
    required this.id,
    required this.email,
    required this.isClassTeacher,
    required this.firstName,
    required this.lastName,
    this.subjects,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      email: json['email'] ?? '',
      isClassTeacher: json['is_class_teacher'] ?? false,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      subjects: json['subjects'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class Subject {
  final int id;
  final String subjectName;
  final String? teacherEmail;

  Subject({required this.id, required this.subjectName, this.teacherEmail});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      subjectName: json['subject_name'] ?? '',
      teacherEmail: json['teacher_email'],
    );
  }
}

class ClassData {
  final int id;
  final String className;
  final String sec;
  final String? classTeacher;
  final String? classTeacherEmail;
  final dynamic classTeacherId;

  ClassData({
    required this.id,
    required this.className,
    required this.sec,
    this.classTeacher,
    this.classTeacherEmail,
    this.classTeacherId,
  });

  factory ClassData.fromJson(Map<String, dynamic> json) {
    return ClassData(
      id: json['id'],
      className: json['class_name'] ?? '',
      sec: json['sec'] ?? '',
      classTeacher: json['class_teacher'],
      classTeacherEmail: json['class_teacher_email'],
      classTeacherId: json['class_teacher_id'],
    );
  }

  String get fullClassName => '$className-$sec';
}

class Student {
  final int id;
  final String email;
  final String name;
  final String firstName;
  final String lastName;
  final String fullName;
  final int classId;
  final String section;
  final String studentSection;
  final String studentId;
  final String? phone;
  final String? address;
  final String? enrollmentDate;
  final String? dateOfBirth;
  final String? gender;
  final dynamic parent;
  final String? parentName;
  final String? parentPhone;
  final String? bloodGroup;
  final String? nationality;
  final String? previousSchool;
  final String? academicYear;
  final String? profileImage;
  final String? profilePicture;
  final String? image;
  final String? avatar;

  Student({
    required this.id,
    required this.email,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.classId,
    required this.section,
    required this.studentSection,
    required this.studentId,
    this.phone,
    this.address,
    this.enrollmentDate,
    this.dateOfBirth,
    this.gender,
    this.parent,
    this.parentName,
    this.parentPhone,
    this.bloodGroup,
    this.nationality,
    this.previousSchool,
    this.academicYear,
    this.profileImage,
    this.profilePicture,
    this.image,
    this.avatar,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName:
          json['full_name'] ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      classId: json['class_id'] ?? 0,
      section: json['section'] ?? '',
      studentSection: json['student_section'] ?? '',
      studentId: json['student_id'] ?? '',
      phone: json['phone'],
      address: json['address'],
      enrollmentDate: json['enrollment_date'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      parent: json['parent'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      bloodGroup: json['blood_group'],
      nationality: json['nationality'],
      previousSchool: json['previous_school'],
      academicYear: json['academic_year'],
      profileImage: json['profile_image'],
      profilePicture: json['profile_picture'],
      image: json['image'],
      avatar: json['avatar'],
    );
  }

  String? getProfileImageUrl(String apiBase) {
    final imageSources = [profileImage, profilePicture, image, avatar];

    for (final source in imageSources) {
      if (source != null && source.isNotEmpty) {
        if (source.startsWith('http://') || source.startsWith('https://')) {
          return source;
        }
        if (source.startsWith('/')) {
          return '$apiBase${source.substring(1)}';
        }
        return '$apiBase/media/$source';
      }
    }
    return null;
  }

  String getInitials() {
    try {
      final firstInitial = firstName.isNotEmpty
          ? firstName[0].toUpperCase()
          : '';
      final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

      if (firstInitial.isNotEmpty) {
        return lastInitial.isNotEmpty
            ? '$firstInitial$lastInitial'
            : firstInitial;
      }

      if (email.isNotEmpty) {
        return email[0].toUpperCase();
      }

      return 'ST';
    } catch (e) {
      return 'ST';
    }
  }
}

class Grade {
  final int id;
  final String student;
  final String subjectName;
  final double marksObtained;
  final double totalMarks;
  final String examType;
  final String teacher;
  final String? teacherEmail;
  final int? subjectId;

  Grade({
    required this.id,
    required this.student,
    required this.subjectName,
    required this.marksObtained,
    required this.totalMarks,
    required this.examType,
    required this.teacher,
    this.teacherEmail,
    this.subjectId,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      student: json['student'] ?? '',
      subjectName: json['subject_name'] ?? '',
      marksObtained: (json['marks_obtained'] ?? 0).toDouble(),
      totalMarks: (json['total_marks'] ?? 0).toDouble(),
      examType: json['exam_type'] ?? '',
      teacher: json['teacher'] ?? '',
      teacherEmail: json['teacher_email'],
      subjectId: json['subject_id'],
    );
  }

  double get percentage => (marksObtained / totalMarks) * 100;
}

class TimetableItem {
  final int id;
  final String teacher;
  final int classId;
  final String? subject;
  final String? subjectName;
  final int? subjectId;

  TimetableItem({
    required this.id,
    required this.teacher,
    required this.classId,
    this.subject,
    this.subjectName,
    this.subjectId,
  });

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      id: json['id'],
      teacher: json['teacher'] ?? '',
      classId: json['class_id'] ?? 0,
      subject: json['subject'],
      subjectName: json['subject_name'],
      subjectId: json['subject_id'],
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
  });

  Color get color {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

class OverallStats {
  final int totalClasses;
  final int totalStudents;
  final double averagePercentage;
  final TopPerformer topPerformer;
  final int subjectsGraded;

  OverallStats({
    required this.totalClasses,
    required this.totalStudents,
    required this.averagePercentage,
    required this.topPerformer,
    required this.subjectsGraded,
  });
}

class TopPerformer {
  final String name;
  final double percentage;

  TopPerformer({required this.name, required this.percentage});
}

class TeacherMarksPage extends StatefulWidget {
  const TeacherMarksPage({super.key});

  @override
  State<TeacherMarksPage> createState() => _TeacherMarksPageState();
}

class _TeacherMarksPageState extends State<TeacherMarksPage> {
  final String apiBase = 'https://school.globaltechsoftwaresolutions.cloud/api';

  // State variables
  String? teacherEmail;
  Teacher? teacherRecord;
  List<TimetableItem> timetable = [];
  List<ClassData> classes = [];
  List<Student> students = [];
  List<Grade> grades = [];
  List<Subject> subjects = [];
  bool loading = true;
  Map<int, double> editingMarks = {};
  Map<int, bool> savingMarks = {};
  Map<String, bool> expandedSections = {};
  String searchTerm = '';
  int? showStudentDetails;
  int? selectedClassId;
  String? selectedSectionName;

  // Reports
  String reportType = 'quarterly';
  bool showSendModal = false;
  int? modalClassId;
  String? modalSection;
  List<int> selectedStudentsForSend = [];
  Map<int, String> parentOverrides = {};
  bool sending = false;
  Map<int, bool> sendingIndividual = {};

  // Notifications
  List<NotificationModel> notifications = [];

  // Stats
  OverallStats overallStats = OverallStats(
    totalClasses: 0,
    totalStudents: 0,
    averagePercentage: 0.0,
    topPerformer: TopPerformer(name: '', percentage: 0.0),
    subjectsGraded: 0,
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTeacherEmail();
    if (teacherEmail != null) {
      await _loadAllData();
    }
  }

  Future<void> _loadTeacherEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = prefs.getString('userInfo');
      final userData = prefs.getString('userData');

      if (userInfo != null) {
        final info = jsonDecode(userInfo);
        if (info['email'] != null) {
          setState(() => teacherEmail = info['email']);
          return;
        }
      }

      if (userData != null) {
        final data = jsonDecode(userData);
        if (data['email'] != null) {
          setState(() => teacherEmail = data['email']);
          return;
        }
      }
    } catch (e) {
      print('Error loading teacher email: $e');
    }
  }

  Future<void> _loadAllData() async {
    if (teacherEmail == null) {
      _addNotification('Error', 'Teacher email not found', 'error');
      setState(() => loading = false);
      return;
    }

    setState(() => loading = true);

    try {
      // Add timeout to prevent hanging
      final responses = await Future.wait([
        http
            .get(Uri.parse('$apiBase/timetable/'))
            .timeout(const Duration(seconds: 10)),
        http
            .get(Uri.parse('$apiBase/classes/'))
            .timeout(const Duration(seconds: 10)),
        http
            .get(Uri.parse('$apiBase/students/'))
            .timeout(const Duration(seconds: 10)),
        http
            .get(Uri.parse('$apiBase/grades/'))
            .timeout(const Duration(seconds: 10)),
        http
            .get(Uri.parse('$apiBase/teachers/'))
            .timeout(const Duration(seconds: 10)),
        http
            .get(Uri.parse('$apiBase/subjects/'))
            .timeout(const Duration(seconds: 10)),
      ], eagerError: true);

      // Check if all responses are successful
      for (int i = 0; i < responses.length; i++) {
        if (responses[i].statusCode != 200) {
          throw Exception(
            'API call $i failed with status ${responses[i].statusCode}',
          );
        }
      }

      final timetableData = jsonDecode(responses[0].body);
      final classesData = jsonDecode(responses[1].body);
      final studentsData = jsonDecode(responses[2].body);
      final gradesData = jsonDecode(responses[3].body);
      final teachersData = jsonDecode(responses[4].body);
      final subjectsData = jsonDecode(responses[5].body);

      setState(() {
        timetable = (timetableData as List)
            .map((e) => TimetableItem.fromJson(e))
            .toList();
        classes = (classesData as List)
            .map((e) => ClassData.fromJson(e))
            .toList();
        students = (studentsData as List)
            .map((e) => Student.fromJson(e))
            .toList();
        grades = (gradesData as List).map((e) => Grade.fromJson(e)).toList();
        subjects = (subjectsData as List)
            .map((e) => Subject.fromJson(e))
            .toList();

        teacherRecord = (teachersData as List)
            .map((e) => Teacher.fromJson(e))
            .firstWhere(
              (t) => t.email.toLowerCase() == teacherEmail!.toLowerCase(),
              orElse: () => Teacher(
                id: 0,
                email: '',
                isClassTeacher: false,
                firstName: '',
                lastName: '',
              ),
            );
      });

      _calculateStats();
      _addNotification('Success', 'Data loaded successfully', 'success');
    } on TimeoutException catch (e) {
      print('Request timeout: $e');
      _addNotification(
        'Timeout',
        'Server is taking too long to respond',
        'error',
      );
    } catch (e) {
      print('Failed to fetch data: $e');
      _addNotification(
        'Error',
        'Failed to load data: ${e.toString().substring(0, 50)}...',
        'error',
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _calculateStats() {
    final studentEmails = students.map((s) => s.email).toSet();
    final percentages = studentEmails
        .map((email) => _calculateStudentAverage(email))
        .toList();

    final validPercentages = percentages.where((p) => p > 0).toList();
    final avgPercentage = validPercentages.isEmpty
        ? 0.0
        : validPercentages.reduce((a, b) => a + b) / validPercentages.length;

    String topPerformerName = 'N/A';
    double topPercentage = 0.0;

    if (validPercentages.isNotEmpty) {
      final maxIndex = validPercentages.indexOf(
        validPercentages.reduce((a, b) => a > b ? a : b),
      );
      final topStudentEmail = studentEmails.elementAt(maxIndex);
      final topStudent = students.firstWhere((s) => s.email == topStudentEmail);
      topPerformerName = topStudent.fullName;
      topPercentage = validPercentages[maxIndex];
    }

    setState(() {
      overallStats = OverallStats(
        totalClasses: classes.length,
        totalStudents: students.length,
        averagePercentage: double.parse(avgPercentage.toStringAsFixed(1)),
        topPerformer: TopPerformer(
          name: topPerformerName,
          percentage: double.parse(topPercentage.toStringAsFixed(1)),
        ),
        subjectsGraded: grades.map((g) => g.subjectName).toSet().length,
      );
    });
  }

  List<Grade> _gradesForStudent(String studentEmail) {
    if (studentEmail.isEmpty || grades.isEmpty) return [];
    return grades
        .where((g) => g.student.toLowerCase() == studentEmail.toLowerCase())
        .toList();
  }

  bool _filterByReportType(Grade grade) {
    if (grade.examType.isEmpty) return false;
    final et = grade.examType.toLowerCase();
    if (reportType == 'quarterly') {
      return et == 'quiz' || et == 'quarterly';
    }
    if (reportType == 'annual') {
      return et == 'final' || et == 'annual';
    }
    return true;
  }

  double _calculateStudentAverage(String email) {
    final studentGrades = _gradesForStudent(
      email,
    ).where(_filterByReportType).toList();
    if (studentGrades.isEmpty) return 0.0;

    final totalPercentage = studentGrades.fold<double>(
      0,
      (sum, grade) => sum + grade.percentage,
    );
    return double.parse(
      (totalPercentage / studentGrades.length).toStringAsFixed(1),
    );
  }

  List<Grade> _generateReportForStudent(String email) {
    return _gradesForStudent(email).where(_filterByReportType).toList();
  }

  String _getGradeBadge(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green[800]!;
    if (percentage >= 80) return Colors.green[600]!;
    if (percentage >= 70) return Colors.blue[600]!;
    if (percentage >= 60) return Colors.yellow[700]!;
    if (percentage >= 50) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  Color _getGradeBgColor(double percentage) {
    if (percentage >= 90) return Colors.green[50]!;
    if (percentage >= 80) return Colors.green[50]!;
    if (percentage >= 70) return Colors.blue[50]!;
    if (percentage >= 60) return Colors.yellow[50]!;
    if (percentage >= 50) return Colors.orange[50]!;
    return Colors.red[50]!;
  }

  void _addNotification(String title, String message, String type) {
    final id = DateTime.now().millisecondsSinceEpoch;
    final notification = NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    setState(() {
      notifications.insert(0, notification);
      if (notifications.length > 5) {
        notifications.removeLast();
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        notifications.removeWhere((n) => n.id == id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Marks Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAllData,
              ),
            ],
          ),
        ),

        // Stats Summary
        _buildStatsSummary(),

        // Report Type Selector
        _buildReportTypeSelector(),

        // Search Bar
        _buildSearchBar(),

        // Students List - Scrollable
        Flexible(child: _buildStudentsList()),
      ],
    );
  }

  Widget _buildStatsSummary() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Classes',
                  overallStats.totalClasses.toString(),
                  Icons.class_,
                ),
                _buildStatCard(
                  'Students',
                  overallStats.totalStudents.toString(),
                  Icons.people,
                ),
                _buildStatCard(
                  'Avg %',
                  '${overallStats.averagePercentage}%',
                  Icons.percent,
                ),
                _buildStatCard(
                  'Subjects',
                  overallStats.subjectsGraded.toString(),
                  Icons.book,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Top Performer: ${overallStats.topPerformer.name} (${overallStats.topPerformer.percentage}%)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Report Type:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: reportType,
            items: const [
              DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
              DropdownMenuItem(value: 'annual', child: Text('Annual')),
            ],
            onChanged: (value) {
              setState(() => reportType = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search students...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() => searchTerm = value);
        },
      ),
    );
  }

  Widget _buildStudentsList() {
    List<Student> filteredStudents = students;

    if (searchTerm.isNotEmpty) {
      filteredStudents = students.where((student) {
        final searchLower = searchTerm.toLowerCase();
        return student.fullName.toLowerCase().contains(searchLower) ||
            student.email.toLowerCase().contains(searchLower) ||
            student.studentId.toLowerCase().contains(searchLower);
      }).toList();
    }

    if (filteredStudents.isEmpty) {
      return const Center(child: Text('No students found'));
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final average = _calculateStudentAverage(student.email);
        final reportGrades = _generateReportForStudent(student.email);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: _buildStudentAvatar(student),
            title: Text(student.fullName),
            subtitle: Text('${student.studentId} • ${student.email}'),
            trailing: _buildGradeIndicator(average),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Average: ${average.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeBgColor(average),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getGradeColor(average)),
                          ),
                          child: Text(
                            _getGradeBadge(average),
                            style: TextStyle(
                              color: _getGradeColor(average),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Subject Grades:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...reportGrades
                        .map((grade) => _buildGradeRow(grade))
                        .toList(),
                    if (reportGrades.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No grades recorded for this report type'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentAvatar(Student student) {
    final imageUrl = student.getProfileImageUrl(apiBase);

    if (imageUrl != null) {
      return CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 20);
    } else {
      return CircleAvatar(
        backgroundColor: Colors.blue,
        radius: 20,
        child: Text(
          student.getInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildGradeIndicator(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getGradeBgColor(percentage),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getGradeColor(percentage)),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          color: _getGradeColor(percentage),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGradeRow(Grade grade) {
    final percentage = grade.percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${grade.marksObtained}/${grade.totalMarks} marks • ${grade.examType}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getGradeBgColor(percentage),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getGradeColor(percentage)),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}% (${_getGradeBadge(percentage)})',
              style: TextStyle(
                color: _getGradeColor(percentage),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
