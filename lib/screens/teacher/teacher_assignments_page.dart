import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Data Models
class Student {
  final int id;
  final String? email;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final int classId;
  final String? className;
  final String section;
  final String studentSection;
  final String studentId;
  final String? phone;
  final String? address;
  final String? enrollmentDate;
  final String? dateOfBirth;
  final String? gender;
  final String? parentName;
  final String? parentPhone;
  final String? bloodGroup;
  final String? nationality;
  final String? previousSchool;
  final String? academicYear;
  final String? rollNumber;

  Student({
    required this.id,
    this.email,
    this.name,
    this.firstName,
    this.lastName,
    this.fullName,
    required this.classId,
    this.className,
    required this.section,
    required this.studentSection,
    required this.studentId,
    this.phone,
    this.address,
    this.enrollmentDate,
    this.dateOfBirth,
    this.gender,
    this.parentName,
    this.parentPhone,
    this.bloodGroup,
    this.nationality,
    this.previousSchool,
    this.academicYear,
    this.rollNumber,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      email: json['email'],
      name: json['name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
      classId: json['class_id'] ?? 0,
      className: json['class_name'],
      section: json['section'] ?? '',
      studentSection: json['student_section'] ?? '',
      studentId: json['student_id'] ?? '',
      phone: json['phone'],
      address: json['address'],
      enrollmentDate: json['enrollment_date'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      bloodGroup: json['blood_group'],
      nationality: json['nationality'],
      previousSchool: json['previous_school'],
      academicYear: json['academic_year'],
      rollNumber: json['roll_number'],
    );
  }
}

class Assignment {
  final int id;
  final String title;
  final String description;
  final String subjectName;
  final int classId;
  final String className;
  final String section;
  final String dueDate;
  final String? attachment;
  final String createdAt;
  final String? status;
  final String? assignedBy;
  final String? sec;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectName,
    required this.classId,
    required this.className,
    required this.section,
    required this.dueDate,
    this.attachment,
    required this.createdAt,
    this.status,
    this.assignedBy,
    this.sec,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subjectName: json['subject_name'] ?? '',
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? '',
      section: json['sec'] ?? json['section'] ?? '',
      dueDate: json['due_date'] ?? '',
      attachment: json['attachment'],
      createdAt: json['created_at'] ?? '',
      status: json['status'],
      assignedBy: json['assigned_by'],
      sec: json['sec'] ?? json['section'],
    );
  }
}

class Submission {
  final int id;
  final int? assignmentId;
  final String? studentId;
  final String? studentName;
  final String? submissionDate;
  final String? fileAttachment;
  final String? grade;
  final String? feedback;
  final String? submittedAt;
  final bool? isLate;
  final String? studentEmail;
  final String? student;
  final int? assignment;
  final String? submissionFile;
  final String? subjectName;

  Submission({
    required this.id,
    this.assignmentId,
    this.studentId,
    this.studentName,
    this.submissionDate,
    this.fileAttachment,
    this.grade,
    this.feedback,
    this.submittedAt,
    this.isLate,
    this.studentEmail,
    this.student,
    this.assignment,
    this.submissionFile,
    this.subjectName,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] ?? 0,
      assignmentId: json['assignment'] ?? json['assignment_id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      submissionDate: json['submission_date'] ?? json['submitted_at'],
      fileAttachment: json['file_attachment'] ?? json['submission_file'],
      grade: json['grade'],
      feedback: json['feedback'],
      submittedAt: json['submitted_at'] ?? json['submission_date'],
      isLate: json['is_late'] ?? false,
      studentEmail: json['student_email'],
      student: json['student'],
      assignment: json['assignment'] ?? json['assignment_id'],
      submissionFile: json['submission_file'] ?? json['file_attachment'],
      subjectName: json['subject_name'],
    );
  }
}

class Class {
  final int id;
  final String className;
  final String? section;

  Class({required this.id, required this.className, this.section});

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      id: json['id'] ?? 0,
      className: json['class_name'] ?? '',
      section: json['section'] ?? json['sec'],
    );
  }
}

class Subject {
  final int id;
  final String subjectName;

  Subject({required this.id, required this.subjectName});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      subjectName: json['subject_name'] ?? '',
    );
  }
}

class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  // API Configuration
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  // Data Lists
  List<Assignment> assignments = [];
  List<Submission> submittedAssignments = [];
  List<Student> studentsData = [];
  List<Class> classesData = [];
  List<Student> teacherStudents = [];
  List<Subject> teacherSubjects = [];

  // UI State
  bool isLoading = true;
  String error = "";
  bool showForm = false;
  String searchTerm = "";
  String statusFilter = "all";
  String classFilter = "all";
  String subjectFilter = "all";
  int? expandedAssignment;
  bool showSuccessPopup = false;
  bool showErrorPopup = false;
  String popupMessage = "";
  bool isSubmitting = false;
  int? selectedAssignmentId;
  bool loadingSubmittedAssignments = false;
  bool showSubmittedAssignments = false;
  String viewMode =
      'assignments'; // 'assignments' | 'total' | 'pending' | 'completed' | 'overdue'
  List<Student> filteredStudents = [];
  bool loadingStudents = false;
  String currentAssignmentTitle = "";
  Map<String, dynamic>? currentAssignmentClass;
  int? currentAssignmentId;

  // Form Data
  final Map<String, dynamic> newAssignment = {
    'title': '',
    'subject': '',
    'class_name': '',
    'section': '',
    'due_date': '',
    'description': '',
  };

  // Student submissions organized by student email
  Map<String, List<Submission>> studentSubmissions = {};

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _fetchTeacherData();
    await _fetchAssignments();
    await _fetchAllSubmissions();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherEmail = prefs.getString('user_email');

      if (teacherEmail == null) {
        setState(() => error = "No teacher email found in local storage.");
        return;
      }

      // Fetch teacher's details to get subject_list
      final teacherResponse = await http.get(
        Uri.parse('$apiBaseUrl/teachers/?email=$teacherEmail'),
      );
      if (teacherResponse.statusCode == 200) {
        final teachers = json.decode(teacherResponse.body) as List;
        if (teachers.isNotEmpty) {
          final teacher = teachers[0];
          final subjectsList = teacher['subject_list'] as List?;
          if (subjectsList != null) {
            setState(() {
              teacherSubjects = subjectsList
                  .map((s) => Subject.fromJson(s))
                  .toList();
            });
          }
        }
      }

      // Fetch all classes
      final classesResponse = await http.get(Uri.parse('$apiBaseUrl/classes/'));
      if (classesResponse.statusCode == 200) {
        final classes = json.decode(classesResponse.body) as List;
        setState(() {
          classesData = classes.map((c) => Class.fromJson(c)).toList();
        });
      }

      // Fetch all students
      final studentsResponse = await http.get(
        Uri.parse('$apiBaseUrl/students/'),
      );
      if (studentsResponse.statusCode == 200) {
        final students = json.decode(studentsResponse.body) as List;
        setState(() {
          studentsData = students.map((s) => Student.fromJson(s)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching teacher data: $e');
      _showPopup('error', "Failed to load teacher information.");
    }
  }

  Future<void> _fetchAssignments() async {
    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final teacherEmail = prefs.getString('user_email');

      if (teacherEmail == null) {
        setState(() => error = "No teacher email found in local storage.");
        return;
      }

      final response = await http.get(Uri.parse('$apiBaseUrl/assignments/'));

      if (response.statusCode == 200) {
        final allAssignments = json.decode(response.body) as List;
        final teacherAssignments = allAssignments
            .map((item) => Assignment.fromJson(item))
            .where((assignment) => assignment.assignedBy == teacherEmail)
            .toList();

        setState(() {
          assignments = teacherAssignments;
          error = "";
        });
      } else {
        setState(() => error = "Failed to fetch assignments.");
      }
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      setState(() => error = "Failed to fetch assignments.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAllSubmissions() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/submitted_assignments/'),
      );
      if (response.statusCode == 200) {
        final allSubmissions = json.decode(response.body) as List;
        final submissions = allSubmissions
            .map((s) => Submission.fromJson(s))
            .toList();

        // Organize submissions by student email
        final submissionsByStudent = <String, List<Submission>>{};
        for (final submission in submissions) {
          final email = submission.studentEmail ?? submission.student ?? '';
          if (email.isNotEmpty) {
            if (!submissionsByStudent.containsKey(email)) {
              submissionsByStudent[email] = [];
            }
            submissionsByStudent[email]!.add(submission);
          }
        }

        setState(() {
          studentSubmissions = submissionsByStudent;
        });
      }
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
      _showPopup('error', "Failed to load submission data.");
    }
  }

  Future<List<Student>> _getTeacherStudents() async {
    try {
      setState(() => loadingStudents = true);

      final prefs = await SharedPreferences.getInstance();
      final teacherEmail = prefs.getString('user_email');

      if (teacherEmail == null) return [];

      // Get teacher's assignments to know which classes they teach
      final assignmentsResponse = await http.get(
        Uri.parse('$apiBaseUrl/assignments/'),
      );
      if (assignmentsResponse.statusCode != 200) return [];

      final allAssignments = json.decode(assignmentsResponse.body) as List;
      final teacherAssignments = allAssignments
          .map((item) => Assignment.fromJson(item))
          .where((assignment) => assignment.assignedBy == teacherEmail)
          .toList();

      // Extract unique classes taught by this teacher from assignments
      final teacherClassesSet = <String>{};
      for (final assignment in teacherAssignments) {
        if (assignment.className.isNotEmpty && assignment.section.isNotEmpty) {
          teacherClassesSet.add(
            '${assignment.className}-${assignment.section}',
          );
        }
      }

      // Filter students based on teacher's classes
      final filtered = studentsData.where((student) {
        final studentClass = classesData.firstWhere(
          (cls) => cls.id == student.classId,
          orElse: () => Class(id: 0, className: ''),
        );

        if (studentClass.id == 0) {
          return student.className != null &&
              student.section.isNotEmpty &&
              teacherClassesSet.contains(
                '${student.className}-${student.section}',
              );
        }

        final classKey =
            '${studentClass.className}-${studentClass.section ?? studentClass.className}';
        return teacherClassesSet.contains(classKey);
      }).toList();

      setState(() => teacherStudents = filtered);
      return filtered;
    } catch (e) {
      debugPrint('Error getting teacher students: $e');
      _showPopup('error', "Failed to load students data.");
      return [];
    } finally {
      setState(() => loadingStudents = false);
    }
  }

  void _showPopup(String type, String message) {
    setState(() {
      popupMessage = message;
      if (type == 'success') {
        showSuccessPopup = true;
        showErrorPopup = false;
      } else {
        showErrorPopup = true;
        showSuccessPopup = false;
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          showSuccessPopup = false;
          showErrorPopup = false;
        });
      }
    });
  }

  Map<String, int> _getAssignmentStats(Assignment assignment) {
    final dueDate = DateTime.parse(assignment.dueDate);
    final now = DateTime.now();
    final isOverdue = now.isAfter(dueDate);

    // Filter students by class and section
    final classStudents = studentsData.where((student) {
      final studentClass = classesData.firstWhere(
        (cls) => cls.id == student.classId,
        orElse: () => Class(id: 0, className: ''),
      );

      if (studentClass.id == 0) {
        return student.className == assignment.className &&
            (student.section == assignment.sec ||
                student.studentSection == assignment.sec);
      }

      return studentClass.className == assignment.className &&
          (studentClass.section == assignment.sec ||
              studentClass.className == assignment.sec);
    }).toList();

    int completed = 0;
    int pending = 0;
    int overdue = 0;

    for (final student in classStudents) {
      final email = student.email ?? '';
      final submissions = studentSubmissions[email] ?? [];
      final submission = submissions.firstWhere(
        (s) => s.assignmentId == assignment.id || s.assignment == assignment.id,
        orElse: () => Submission(id: 0),
      );

      if (submission.id != 0) {
        final submissionDate = DateTime.parse(
          submission.submissionDate ?? submission.submittedAt ?? '',
        );
        final submittedLate =
            submissionDate.isAfter(dueDate) || submission.isLate == true;
        if (submittedLate) {
          overdue++;
        } else {
          completed++;
        }
      } else {
        if (isOverdue) {
          overdue++;
        } else {
          pending++;
        }
      }
    }

    return {
      'total': classStudents.length,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
    };
  }

  void _handleCardClick(String cardType) async {
    setState(() => viewMode = cardType);

    // Get teacher's students first
    final teacherStudentsList = await _getTeacherStudents();

    if (teacherStudentsList.isEmpty) {
      _showPopup('error', "No students found for your classes.");
      return;
    }

    // Fetch all submitted assignments
    try {
      final submittedResponse = await http.get(
        Uri.parse('$apiBaseUrl/submitted_assignments/'),
      );
      if (submittedResponse.statusCode != 200) {
        _showPopup('error', "Failed to filter students.");
        return;
      }

      final allSubmissions = json.decode(submittedResponse.body) as List;
      final submissions = allSubmissions
          .map((s) => Submission.fromJson(s))
          .toList();

      // Update student submissions state
      final submissionsByStudent = <String, List<Submission>>{};
      for (final submission in submissions) {
        final email = submission.studentEmail ?? submission.student ?? '';
        if (email.isNotEmpty) {
          if (!submissionsByStudent.containsKey(email)) {
            submissionsByStudent[email] = [];
          }
          submissionsByStudent[email]!.add(submission);
        }
      }

      setState(() => studentSubmissions = submissionsByStudent);

      // Filter students based on logic
      List<Student> filteredStudentsList = [];

      switch (cardType) {
        case 'total':
          filteredStudentsList = teacherStudentsList;
          break;
        case 'pending':
          filteredStudentsList = teacherStudentsList.where((student) {
            final hasSubmission = submissions.any(
              (submission) =>
                  submission.studentEmail == student.email ||
                  submission.student == student.email,
            );
            return !hasSubmission;
          }).toList();
          break;
        case 'completed':
          filteredStudentsList = teacherStudentsList.where((student) {
            final hasSubmission = submissions.any(
              (submission) =>
                  submission.studentEmail == student.email ||
                  submission.student == student.email,
            );
            return hasSubmission;
          }).toList();
          break;
        case 'overdue':
          filteredStudentsList = teacherStudentsList.where((student) {
            final studentSubmissions = submissions
                .where(
                  (submission) =>
                      (submission.studentEmail == student.email ||
                          submission.student == student.email) &&
                      submission.isLate == true,
                )
                .toList();
            return studentSubmissions.isNotEmpty;
          }).toList();
          break;
      }

      setState(() => this.filteredStudents = filteredStudentsList);
    } catch (e) {
      debugPrint("Error filtering students: $e");
      _showPopup('error', "Failed to filter students.");
    }
  }

  void _handleAssignmentCardClick(
    String cardType,
    Assignment assignment,
  ) async {
    setState(() {
      viewMode = cardType;
      currentAssignmentId = assignment.id;
      currentAssignmentTitle = assignment.title;
      currentAssignmentClass = {
        'class_name': assignment.className,
        'section': assignment.sec,
      };
      loadingStudents = true;
    });

    try {
      final dueDate = DateTime.parse(assignment.dueDate);
      final now = DateTime.now();
      final isDeadlinePassed = now.isAfter(dueDate);

      // Get students for this assignment's class
      final classStudents = studentsData.where((student) {
        final studentClass = classesData.firstWhere(
          (cls) => cls.id == student.classId,
          orElse: () => Class(id: 0, className: ''),
        );

        if (studentClass.id == 0) {
          return student.className == assignment.className &&
              (student.section == assignment.sec ||
                  student.studentSection == assignment.sec);
        }

        return studentClass.className == assignment.className &&
            (studentClass.section == assignment.sec ||
                studentClass.className == assignment.sec);
      }).toList();

      // Refresh submissions for this assignment specifically
      final response = await http.get(
        Uri.parse('$apiBaseUrl/submitted_assignments/'),
      );
      if (response.statusCode != 200) {
        _showPopup('error', "Failed to load assignment student details.");
        return;
      }

      final allSubmissions = json.decode(response.body) as List;
      final assignmentSubmissions = allSubmissions
          .map((s) => Submission.fromJson(s))
          .where(
            (s) =>
                s.assignmentId == assignment.id ||
                s.assignment == assignment.id,
          )
          .toList();

      // Create email map for efficiency
      final submissionMap = <String, Submission>{};
      for (final s in assignmentSubmissions) {
        final email = (s.studentEmail ?? s.student ?? '').toLowerCase();
        if (email.isNotEmpty) submissionMap[email] = s;
      }

      // Update global submissions state
      setState(() {
        final next = Map<String, List<Submission>>.from(studentSubmissions);
        for (final sub in assignmentSubmissions) {
          final email = (sub.studentEmail ?? sub.student ?? '').toLowerCase();
          if (email.isNotEmpty) {
            final list = next[email] ?? [];
            if (!list.any((item) => item.id == sub.id)) {
              next[email] = [...list, sub];
            }
          }
        }
        studentSubmissions = next;
      });

      // Filter students based on logic
      List<Student> filtered = [];

      switch (cardType) {
        case 'total':
          filtered = classStudents;
          break;
        case 'completed':
          filtered = classStudents.where((s) {
            final sub = submissionMap[s.email?.toLowerCase() ?? ''];
            if (sub == null) return false;
            final subDate = DateTime.parse(
              sub.submissionDate ?? sub.submittedAt ?? '',
            );
            return subDate.isBefore(dueDate) && sub.isLate != true;
          }).toList();
          break;
        case 'overdue':
          filtered = classStudents.where((s) {
            final sub = submissionMap[s.email?.toLowerCase() ?? ''];
            if (sub != null) {
              final subDate = DateTime.parse(
                sub.submissionDate ?? sub.submittedAt ?? '',
              );
              return subDate.isAfter(dueDate) || sub.isLate == true;
            }
            return isDeadlinePassed;
          }).toList();
          break;
        case 'pending':
          filtered = classStudents.where((s) {
            final sub = submissionMap[s.email?.toLowerCase() ?? ''];
            return sub == null && !isDeadlinePassed;
          }).toList();
          break;
      }

      setState(() => filteredStudents = filtered);
    } catch (e) {
      debugPrint("Error filtering assignment students: $e");
      _showPopup('error', "Failed to load assignment student details.");
    } finally {
      setState(() => loadingStudents = false);
    }
  }

  Future<void> _handleAddAssignment() async {
    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherEmail = prefs.getString('user_email');

      if (teacherEmail == null) {
        _showPopup('error', "Teacher email not found.");
        return;
      }

      // Prepare assignment data
      final assignmentData = {
        'title': newAssignment['title'],
        'description': newAssignment['description'],
        'class_name': newAssignment['class_name'],
        'section': newAssignment['section'],
        'due_date': newAssignment['due_date'],
        'subject': int.tryParse(newAssignment['subject'].toString()) ?? 0,
        'assigned_by': teacherEmail,
        'attachment': null,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/assignments/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(assignmentData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showPopup('success', "Assignment added successfully!");
        setState(() {
          showForm = false;
          newAssignment['title'] = '';
          newAssignment['subject'] = '';
          newAssignment['class_name'] = '';
          newAssignment['section'] = '';
          newAssignment['due_date'] = '';
          newAssignment['description'] = '';
        });
        await _fetchAssignments();
      } else {
        _showPopup(
          'error',
          "Failed to add assignment. Please check the form data.",
        );
      }
    } catch (e) {
      debugPrint('Error adding assignment: $e');
      _showPopup(
        'error',
        "Failed to add assignment. Please check the form data.",
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  // Calculate statistics
  Map<String, int> get stats {
    return {
      'totalAssignments': assignments.length,
      'pending': assignments.where((item) => item.status == "Pending").length,
      'completed': assignments
          .where((item) => item.status == "Completed")
          .length,
      'overdue': assignments.where((item) {
        if (item.dueDate.isEmpty) return false;
        return DateTime.parse(item.dueDate).isBefore(DateTime.now()) &&
            item.status != "Completed";
      }).length,
    };
  }

  // Get unique classes and subjects for filters
  List<String> get uniqueClasses =>
      assignments.map((item) => item.className).toSet().toList();
  List<String> get uniqueSubjects =>
      assignments.map((item) => item.subjectName).toSet().toList();

  // Filter assignments
  List<Assignment> get filteredAssignments {
    return assignments.where((item) {
      final matchesSearch =
          item.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          item.description.toLowerCase().contains(searchTerm.toLowerCase()) ||
          item.className.toLowerCase().contains(searchTerm.toLowerCase());

      final matchesStatus =
          statusFilter == "all" || item.status == statusFilter;
      final matchesClass =
          classFilter == "all" || item.className == classFilter;
      final matchesSubject =
          subjectFilter == "all" || item.subjectName == subjectFilter;

      return matchesSearch && matchesStatus && matchesClass && matchesSubject;
    }).toList()..sort(
      (a, b) => DateTime.parse(b.dueDate).compareTo(DateTime.parse(a.dueDate)),
    );
  }

  IconData _getStatusIcon(String? status, String? dueDate) {
    final isOverdue = _isAssignmentOverdue(dueDate, status);

    if (isOverdue) return Icons.error;

    switch (status) {
      case "Completed":
        return Icons.check_circle;
      case "Pending":
        return Icons.schedule;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(String? status, String? dueDate) {
    final isOverdue = _isAssignmentOverdue(dueDate, status);

    if (isOverdue) return Colors.red.shade50;

    switch (status) {
      case "Completed":
        return Colors.green.shade50;
      case "Pending":
        return Colors.yellow.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  bool _isAssignmentOverdue(String? dueDate, String? status) {
    if (dueDate == null || dueDate.isEmpty) return false;
    final date = DateTime.parse(dueDate);
    date.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    return date.isBefore(DateTime.now()) && status != "Completed";
  }

  Future<void> _fetchSubmittedAssignments(int assignmentId) async {
    try {
      setState(() {
        loadingSubmittedAssignments = true;
        selectedAssignmentId = assignmentId;
      });

      // Get assignment title
      final assignment = assignments.firstWhere((a) => a.id == assignmentId);
      setState(() => currentAssignmentTitle = assignment.title);

      final response = await http.get(
        Uri.parse('$apiBaseUrl/submitted_assignments/'),
      );

      if (response.statusCode == 200) {
        final allSubmissions = json.decode(response.body) as List;

        // Filter by assignment ID (handle different possible field names)
        final assignmentSubmissions = allSubmissions
            .where((item) {
              final itemAssignmentId =
                  item['assignment'] ??
                  item['assignment_id'] ??
                  item['assignmentId'];
              return itemAssignmentId == assignmentId;
            })
            .map((item) => Submission.fromJson(item))
            .toList();

        setState(() {
          submittedAssignments = assignmentSubmissions;
          showSubmittedAssignments = true;
        });
      } else {
        _showPopup('error', "Failed to fetch submitted assignments.");
      }
    } catch (e) {
      debugPrint('Error fetching submitted assignments: $e');
      _showPopup('error', "Failed to fetch submitted assignments.");
    } finally {
      setState(() => loadingSubmittedAssignments = false);
    }
  }

  Map<String, dynamic> _getStudentClass(String studentEmail) {
    final student = studentsData.firstWhere(
      (s) => s.email == studentEmail,
      orElse: () => Student(
        id: 0,
        classId: 0,
        section: '',
        studentSection: '',
        studentId: '',
      ),
    );

    if (student.id == 0)
      return {'class_id': null, 'class_name': 'Unknown', 'section': ''};

    final classInfo = classesData.firstWhere(
      (cls) => cls.id == student.classId,
      orElse: () => Class(id: student.classId, className: 'Unknown'),
    );

    return {
      'class_id': classInfo.id,
      'class_name': classInfo.className,
      'section': classInfo.section ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading assignments...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                isLoading = true;
                error = '';
                _initializePage();
              }),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success/Error Popups
          if (showSuccessPopup || showErrorPopup)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: showSuccessPopup
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: showSuccessPopup
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      showSuccessPopup ? Icons.check_circle : Icons.error,
                      color: showSuccessPopup ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        popupMessage,
                        style: TextStyle(
                          color: showSuccessPopup
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        showSuccessPopup = false;
                        showErrorPopup = false;
                      }),
                      icon: Icon(
                        Icons.close,
                        color: showSuccessPopup ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewMode == 'assignments'
                          ? 'Assignments'
                          : viewMode == 'total'
                          ? 'All Students'
                          : viewMode == 'pending'
                          ? 'Pending Students'
                          : viewMode == 'completed'
                          ? 'Completed Students'
                          : 'Overdue Students',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewMode == 'assignments'
                          ? 'Create and manage assignments for your students'
                          : viewMode == 'total'
                          ? 'Students in the specific class for this assignment'
                          : viewMode == 'pending'
                          ? 'Students in this assignment\'s class who haven\'t submitted'
                          : viewMode == 'completed'
                          ? 'Students in this assignment\'s class who have submitted'
                          : 'Students in this assignment\'s class with late submissions',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (viewMode == 'assignments')
                ElevatedButton.icon(
                  onPressed: () => setState(() => showForm = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Assignment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Main Content
          Flexible(
            child: viewMode == 'assignments'
                ? _buildAssignmentsView()
                : _buildStudentsView(),
          ),

          // Create Assignment Modal
          if (showForm) _buildCreateAssignmentModal(),

          // Submitted Assignments Modal
          if (showSubmittedAssignments) _buildSubmittedAssignmentsModal(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsView() {
    return Column(
      children: [
        // Overall Statistics Cards
        Row(
          children: [
            _buildStatCard(
              'All Students',
              teacherStudents.length,
              Icons.people,
              Colors.blue,
              'In your classes',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Global Pending',
              stats['pending']!,
              Icons.schedule,
              Colors.yellow,
              'Total pending',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Global Done',
              stats['completed']!,
              Icons.check_circle,
              Colors.green,
              'Total completed',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Global Overdue',
              stats['overdue']!,
              Icons.error,
              Colors.red,
              'Total overdue',
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search assignments...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => searchTerm = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: statusFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'Completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => statusFilter = value ?? 'all'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: classFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Classes'),
                    ),
                    ...uniqueClasses.map(
                      (className) => DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => classFilter = value ?? 'all'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: subjectFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Subjects'),
                    ),
                    ...uniqueSubjects.map(
                      (subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => subjectFilter = value ?? 'all'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Assignments Grid
        Expanded(
          child: filteredAssignments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No assignments found',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 500,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: filteredAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = filteredAssignments[index];
                    final stats = _getAssignmentStats(assignment);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(
                                    assignment.status,
                                    assignment.dueDate,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    assignment.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      assignment.status,
                                      assignment.dueDate,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _isAssignmentOverdue(
                                          assignment.dueDate,
                                          assignment.status,
                                        )
                                        ? 'Overdue'
                                        : assignment.status ?? 'Active',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Subject and Class
                            Text(
                              '${assignment.subjectName} • ${assignment.className} - ${assignment.sec}',
                            ),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(assignment.dueDate))}',
                            ),

                            const SizedBox(height: 16),

                            // Interactive Stats
                            Row(
                              children: [
                                _buildMiniStat(
                                  'All',
                                  stats['total']!,
                                  Colors.blue,
                                  () => _handleAssignmentCardClick(
                                    'total',
                                    assignment,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildMiniStat(
                                  'Done',
                                  stats['completed']!,
                                  Colors.green,
                                  () => _handleAssignmentCardClick(
                                    'completed',
                                    assignment,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildMiniStat(
                                  'Pending',
                                  stats['pending']!,
                                  Colors.yellow,
                                  () => _handleAssignmentCardClick(
                                    'pending',
                                    assignment,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildMiniStat(
                                  'Late',
                                  stats['overdue']!,
                                  Colors.red,
                                  () => _handleAssignmentCardClick(
                                    'overdue',
                                    assignment,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _fetchSubmittedAssignments(assignment.id),
                                  icon: const Icon(Icons.file_present),
                                  label: const Text('Details'),
                                ),
                                IconButton(
                                  onPressed: () => setState(
                                    () => expandedAssignment =
                                        expandedAssignment == assignment.id
                                        ? null
                                        : assignment.id,
                                  ),
                                  icon: Icon(
                                    expandedAssignment == assignment.id
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ),
                              ],
                            ),

                            // Expanded Details
                            if (expandedAssignment == assignment.id) ...[
                              const Divider(),
                              Text(
                                'Created: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(assignment.createdAt))}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                assignment.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentsView() {
    final viewTitle = viewMode == 'total'
        ? 'All Students'
        : viewMode == 'pending'
        ? 'Pending Students'
        : viewMode == 'completed'
        ? 'Completed Students'
        : 'Overdue Students';

    final viewDescription = viewMode == 'total'
        ? 'Students in the specific class for this assignment'
        : viewMode == 'pending'
        ? 'Students in this assignment\'s class who haven\'t submitted'
        : viewMode == 'completed'
        ? 'Students in this assignment\'s class who have submitted'
        : 'Students in this assignment\'s class with late submissions';

    final icon = viewMode == 'total'
        ? Icons.people
        : viewMode == 'pending'
        ? Icons.schedule
        : viewMode == 'completed'
        ? Icons.check_circle
        : Icons.error;

    final bgColor = viewMode == 'total'
        ? Colors.blue.shade50
        : viewMode == 'pending'
        ? Colors.yellow.shade50
        : viewMode == 'completed'
        ? Colors.green.shade50
        : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(viewDescription, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => viewMode = 'assignments'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Assignments'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (loadingStudents)
            const Center(child: CircularProgressIndicator())
          else if (filteredStudents.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No students found'),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final classInfo = _getStudentClass(student.email ?? '');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              (student.firstName ?? student.name ?? 'U')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.fullName ??
                                      student.name ??
                                      'Unknown Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(student.email ?? 'No email'),
                                Text(
                                  '${classInfo['class_name']} - ${classInfo['section']}',
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: viewMode == 'pending'
                                  ? Colors.yellow.shade100
                                  : viewMode == 'completed'
                                  ? Colors.green.shade100
                                  : viewMode == 'overdue'
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              viewMode == 'pending'
                                  ? 'Pending'
                                  : viewMode == 'completed'
                                  ? 'Completed'
                                  : viewMode == 'overdue'
                                  ? 'Overdue'
                                  : 'Active',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateAssignmentModal() {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Create New Assignment',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => showForm = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => newAssignment['title'] = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Subject ID *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => newAssignment['subject'] = value,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Class Name *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => newAssignment['class_name'] = value,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Section *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => newAssignment['section'] = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Due Date *',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  newAssignment['due_date'] = DateFormat(
                    'yyyy-MM-dd',
                  ).format(date);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (value) => newAssignment['description'] = value,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => showForm = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _handleAddAssignment,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Assignment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedAssignmentsModal() {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Submitted Assignments',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {
                    showSubmittedAssignments = false;
                    submittedAssignments = [];
                    selectedAssignmentId = null;
                  }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${currentAssignmentTitle} • ${submittedAssignments.length} submissions',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: loadingSubmittedAssignments
                  ? const Center(child: CircularProgressIndicator())
                  : submittedAssignments.isEmpty
                  ? const Center(child: Text('No submissions found'))
                  : ListView.builder(
                      itemCount: submittedAssignments.length,
                      itemBuilder: (context, index) {
                        final submission = submittedAssignments[index];
                        final classInfo = _getStudentClass(
                          submission.studentEmail ?? '',
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      submission.studentName ??
                                          'Unknown Student',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: submission.isLate == true
                                            ? Colors.red.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        submission.isLate == true
                                            ? 'Late'
                                            : 'On Time',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(submission.studentEmail ?? ''),
                                Text(
                                  '${classInfo['class_name']} - ${classInfo['section']}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Submitted: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(submission.submissionDate ?? ''))}',
                                ),
                                if (submission.grade != null)
                                  Text('Grade: ${submission.grade}'),
                                if (submission.feedback != null &&
                                    submission.feedback!.isNotEmpty)
                                  Text('Feedback: ${submission.feedback}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    int value,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
