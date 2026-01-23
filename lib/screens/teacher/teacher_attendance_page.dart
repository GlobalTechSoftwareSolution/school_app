import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class TimetableEntry {
  final int? id;
  final String? teacher;
  final int? classId;
  final String? className;
  final String? section;
  final int? subject;
  final String? subjectName;
  final String? dayOfWeek;
  final String? startTime;
  final String? endTime;

  TimetableEntry({
    this.id,
    this.teacher,
    this.classId,
    this.className,
    this.section,
    this.subject,
    this.subjectName,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'],
      teacher: json['teacher'],
      classId: json['class_id'],
      className: json['class_name'],
      section: json['section'],
      subject: json['subject'],
      subjectName: json['subject_name'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}

class ClassInfo {
  final int id;
  final String? className;
  final String? section;

  ClassInfo({required this.id, this.className, this.section});

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'],
      className: json['class_name'],
      section: json['sec'],
    );
  }
}

class StudentInfo {
  final String? email;
  final String? fullname;
  final String? profilePicture;
  final int? classId;

  StudentInfo({this.email, this.fullname, this.profilePicture, this.classId});

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      email: json['email'],
      fullname: json['fullname'],
      profilePicture: json['profile_picture'],
      classId: json['class_id'],
    );
  }
}

class AttendanceRecord {
  final int? id;
  final String? student;
  final String? studentEmail;
  final String? teacher;
  final int? classId;
  final String? className;
  final String? section;
  final int? subject;
  final String? subjectName;
  final String? date;
  final String? status;
  final String? period;
  final String? studentName;
  final String? checkIn;
  final String? checkOut;

  AttendanceRecord({
    this.id,
    this.student,
    this.studentEmail,
    this.teacher,
    this.classId,
    this.className,
    this.section,
    this.subject,
    this.subjectName,
    this.date,
    this.status,
    this.period,
    this.studentName,
    this.checkIn,
    this.checkOut,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      student: json['student'],
      studentEmail: json['student_email'],
      teacher: json['teacher'],
      classId: json['class_id'],
      className: json['class_name'],
      section: json['section'],
      subject: json['subject'],
      subjectName: json['subject_name'],
      date: json['date'],
      status: json['status'],
      period: json['period'],
      studentName: json['student_name'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
    );
  }
}

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  String? teacherEmail;
  String teacherName = "Teacher";

  // Section toggle
  String section = "teacher"; // "teacher" or "student"

  // Date selection
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool showCalendar = false;

  // Class and subject management
  List<ClassInfo> classesList = [];
  int? selectedClass;
  List<TimetableEntry> teacherTimetable = [];
  Map<int, List<Map<String, dynamic>>> classSubjectsMap = {};
  int? selectedSubject;
  String selectedPeriod = '10-11';

  // Students and attendance
  List<StudentInfo> students = [];
  Map<String, String> submittedAttendance = {};
  Map<String, String> pendingAttendance = {};
  List<AttendanceRecord> attendanceRecords = [];
  bool loading = true;

  // Teacher attendance
  List<AttendanceRecord> teacherAttendance = [];
  bool teacherAttendanceMarked = false;

  // Stats
  Map<String, int> attendanceStats = {'present': 0, 'absent': 0, 'total': 0};

  // Messages
  bool showSuccessMessage = false;
  bool showErrorMessage = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  void dispose() {
    // Cancel any pending async operations
    super.dispose();
  }

  Future<void> initializeData() async {
    try {
      await loadTeacherInfo();
      await loadTeacherClasses();
      if (section == "teacher") {
        await loadTeacherAttendance();
      } else {
        await loadStudents();
        await loadStudentAttendance();
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadTeacherInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final name =
          prefs.getString('user_name') ?? email?.split('@')[0] ?? 'Teacher';

      setState(() {
        teacherEmail = email;
        teacherName = name;
      });
    } catch (e) {
      debugPrint('Error loading teacher info: $e');
    }
  }

  Future<void> loadTeacherClasses() async {
    if (teacherEmail == null) return;

    try {
      // Load timetable
      final timetableResponse = await http.get(
        Uri.parse('$apiBaseUrl/timetable/'),
      );
      if (timetableResponse.statusCode != 200) return;

      final timetableData = jsonDecode(timetableResponse.body) as List<dynamic>;
      final timetable = timetableData
          .map((t) => TimetableEntry.fromJson(t))
          .where((t) => t.teacher == teacherEmail)
          .toList();

      // Get unique classes
      final uniqueClassIds = <int>{};
      final subjectsByClass = <int, List<Map<String, dynamic>>>{};

      for (final entry in timetable) {
        if (entry.classId != null) {
          uniqueClassIds.add(entry.classId!);

          if (!subjectsByClass.containsKey(entry.classId!)) {
            subjectsByClass[entry.classId!] = [];
          }

          // Check if subject already exists
          final existingSubject = subjectsByClass[entry.classId!]!.firstWhere(
            (s) => s['id'] == entry.subject,
            orElse: () => <String, dynamic>{},
          );

          if (existingSubject.isEmpty) {
            subjectsByClass[entry.classId!]!.add({
              'id': entry.subject,
              'name': entry.subjectName ?? 'Subject ${entry.subject}',
            });
          }
        }
      }

      // Load class details
      final classesResponse = await http.get(Uri.parse('$apiBaseUrl/classes/'));
      if (classesResponse.statusCode == 200) {
        final classesData = jsonDecode(classesResponse.body) as List<dynamic>;
        final classes = classesData
            .map((c) => ClassInfo.fromJson(c))
            .where((c) => uniqueClassIds.contains(c.id))
            .toList();

        setState(() {
          classesList = classes;
          teacherTimetable = timetable;
          classSubjectsMap = subjectsByClass;
        });

        // Set default class and subject
        if (classes.isNotEmpty && selectedClass == null) {
          setState(() {
            selectedClass = classes[0].id;
          });

          final defaultSubjects = subjectsByClass[classes[0].id];
          if (defaultSubjects != null && defaultSubjects.isNotEmpty) {
            setState(() {
              selectedSubject = defaultSubjects[0]['id'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading teacher classes: $e');
    }
  }

  Future<void> loadStudents() async {
    if (selectedClass == null) return;

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/students/'));
      if (response.statusCode == 200) {
        final studentsData = jsonDecode(response.body) as List<dynamic>;
        final filteredStudents = studentsData
            .map((s) => StudentInfo.fromJson(s))
            .where((s) => s.classId == selectedClass)
            .toList();

        setState(() {
          students = filteredStudents;
        });
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> loadStudentAttendance() async {
    if (selectedClass == null || selectedSubject == null) {
      setState(() {
        attendanceRecords = [];
        submittedAttendance = {};
        attendanceStats = {'present': 0, 'absent': 0, 'total': students.length};
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/student_attendance/?date=$selectedDate&class_id=$selectedClass&subject=$selectedSubject&period=$selectedPeriod',
        ),
      );

      if (response.statusCode == 200) {
        final attendanceData = jsonDecode(response.body) as List<dynamic>;
        final records = attendanceData
            .map((a) => AttendanceRecord.fromJson(a))
            .toList();

        // Create attendance map
        final attendanceMap = <String, String>{};
        for (final record in records) {
          final email = (record.student ?? record.studentEmail ?? '')
              ?.toLowerCase();
          final status = record.status;
          if (email != null && email.isNotEmpty && status != null) {
            attendanceMap[email] = status;
          }
        }

        // Update submitted attendance
        final newSubmittedAttendance = <String, String>{};
        int presentCount = 0;
        int absentCount = 0;

        for (final student in students) {
          if (student.email != null) {
            final email = student.email!.toLowerCase();
            final status = attendanceMap[email] ?? 'Not Marked';
            newSubmittedAttendance[email] = status;

            if (status == 'Present')
              presentCount++;
            else if (status == 'Absent')
              absentCount++;
          }
        }

        setState(() {
          attendanceRecords = records;
          submittedAttendance = newSubmittedAttendance;
          attendanceStats = {
            'present': presentCount,
            'absent': absentCount,
            'total': students.length,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading student attendance: $e');
      setState(() {
        attendanceRecords = [];
        submittedAttendance = {};
        attendanceStats = {'present': 0, 'absent': 0, 'total': students.length};
      });
    }
  }

  Future<void> loadTeacherAttendance() async {
    if (teacherEmail == null) return;

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/attendance/?date=$selectedDate'),
      );
      if (response.statusCode == 200) {
        final attendanceData = jsonDecode(response.body) as List<dynamic>;
        final records = attendanceData
            .map((a) => AttendanceRecord.fromJson(a))
            .where((a) => a.studentEmail == teacherEmail)
            .toList();

        setState(() {
          teacherAttendance = records;
          teacherAttendanceMarked = records.any(
            (r) => r.date == selectedDate && r.status == 'Present',
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading teacher attendance: $e');
    }
  }

  void markAttendance(String? email, String status) {
    if (email == null) return;

    final normalizedEmail = email.toLowerCase();

    setState(() {
      pendingAttendance[normalizedEmail] = status;

      // Update submitted attendance immediately for better UX
      submittedAttendance[normalizedEmail] = status;

      // Update stats
      attendanceStats = calculateStats();
    });
  }

  Map<String, int> calculateStats() {
    int present = 0;
    int absent = 0;

    for (final student in students) {
      if (student.email != null) {
        final email = student.email!.toLowerCase();
        final status =
            submittedAttendance[email] ??
            pendingAttendance[email] ??
            'Not Marked';

        if (status == 'Present')
          present++;
        else if (status == 'Absent')
          absent++;
      }
    }

    return {'present': present, 'absent': absent, 'total': students.length};
  }

  Future<void> submitAttendance() async {
    if (pendingAttendance.isEmpty ||
        teacherEmail == null ||
        selectedClass == null ||
        selectedSubject == null) {
      return;
    }

    try {
      final classInfo = classesList.firstWhere((c) => c.id == selectedClass);
      final subjectInfo = classSubjectsMap[selectedClass]?.firstWhere(
        (s) => s['id'] == selectedSubject,
      );

      final payload = pendingAttendance.entries.map((entry) {
        final student = students.firstWhere(
          (s) => s.email?.toLowerCase() == entry.key,
        );
        return {
          'student': entry.key,
          'teacher': teacherEmail,
          'class_id': selectedClass,
          'date': selectedDate,
          'status': entry.value,
          'subject': selectedSubject,
          'period': selectedPeriod,
          'student_name': student.fullname ?? '',
          'class_name': classInfo.className ?? '',
          'section': classInfo.section ?? '',
          'subject_name': subjectInfo?['name'] ?? '',
          'created_time': DateTime.now().toIso8601String(),
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$apiBaseUrl/student_attendance/bulk_create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 207) {
        setState(() {
          pendingAttendance.clear();
          showSuccessMessage = true;
        });

        // Hide success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => showSuccessMessage = false);
          }
        });

        // Reload attendance data
        await loadStudentAttendance();
      } else {
        throw Exception('Failed to submit attendance');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to submit attendance. Please try again.';
        showErrorMessage = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => showErrorMessage = false);
        }
      });
    }
  }

  Future<void> markTeacherAttendance() async {
    if (teacherEmail == null) return;

    try {
      final payload = {
        'user_email': teacherEmail,
        'date': selectedDate,
        'status': 'Present',
        'check_in': DateFormat('HH:mm').format(DateTime.now()),
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/attendance/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        setState(() => teacherAttendanceMarked = true);
        await loadTeacherAttendance();
      }
    } catch (e) {
      debugPrint('Error marking teacher attendance: $e');
    }
  }

  String getStudentStatus(String? email) {
    if (email == null) return 'Not Marked';

    final normalizedEmail = email.toLowerCase();

    if (pendingAttendance.containsKey(normalizedEmail)) {
      return pendingAttendance[normalizedEmail]!;
    }

    if (submittedAttendance.containsKey(normalizedEmail)) {
      return submittedAttendance[normalizedEmail]!;
    }

    return 'Not Marked';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Attendance Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => section = "teacher"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: section == "teacher"
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: section == "teacher"
                            ? [
                                const BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: section == "teacher"
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Teacher Attendance',
                            style: TextStyle(
                              color: section == "teacher"
                                  ? Colors.blue
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => section = "student"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: section == "student"
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: section == "student"
                            ? [
                                const BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school,
                            color: section == "student"
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Student Attendance',
                            style: TextStyle(
                              color: section == "student"
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date Selection
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(selectedDate),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                          if (section == "teacher") {
                            loadTeacherAttendance();
                          } else {
                            loadStudentAttendance();
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(DateTime.parse(selectedDate)),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final today = DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.now());
                            setState(() => selectedDate = today);
                          },
                          icon: const Icon(Icons.today),
                          label: const Text('Today'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => showCalendar = !showCalendar),
                          icon: Icon(
                            showCalendar
                                ? Icons.calendar_view_day
                                : Icons.calendar_view_month,
                          ),
                          label: Text(
                            showCalendar ? 'Hide Calendar' : 'Show Calendar',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showCalendar) ...[
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime.now(),
                      focusedDay: DateTime.parse(selectedDate),
                      selectedDayPredicate: (day) =>
                          isSameDay(DateTime.parse(selectedDate), day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          selectedDate = DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDay);
                          if (section == "teacher") {
                            loadTeacherAttendance();
                          } else {
                            loadStudentAttendance();
                          }
                        });
                      },
                      calendarStyle: const CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Teacher Attendance Section
          if (section == "teacher") _buildTeacherAttendanceSection(),

          // Student Attendance Section
          if (section == "student") _buildStudentAttendanceSection(),

          // Messages
          if (showSuccessMessage)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Attendance submitted successfully!',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),

          if (showErrorMessage)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeacherAttendanceSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: const Text(
                    'Your Attendance Records',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                if (selectedDate ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now()))
                  ElevatedButton.icon(
                    onPressed: teacherAttendanceMarked
                        ? null
                        : markTeacherAttendance,
                    icon: Icon(
                      teacherAttendanceMarked
                          ? Icons.check
                          : Icons.check_circle,
                    ),
                    label: Text(
                      teacherAttendanceMarked
                          ? "Attendance Marked"
                          : "Mark Attendance",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teacherAttendanceMarked
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (teacherAttendance.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_note, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teacherAttendance.length,
                itemBuilder: (context, index) {
                  final record = teacherAttendance[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attendance Record',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: record.status == 'Present'
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record.status ?? 'Unknown',
                                  style: TextStyle(
                                    color: record.status == 'Present'
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      record.date ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Check In',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      record.checkIn ?? 'Not Recorded',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Check Out',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      record.checkOut ?? 'Not Recorded',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
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
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceSection() {
    String? currentSubjectName;
    if (selectedSubject != null && selectedClass != null) {
      final subjects = classSubjectsMap[selectedClass];
      if (subjects != null) {
        final subject = subjects.firstWhere(
          (s) => s['id'] == selectedSubject,
          orElse: () => <String, dynamic>{},
        );
        currentSubjectName = subject['name'] as String? ?? 'Unknown Subject';
      }
    }

    return Column(
      children: [
        // Class and Subject Selection
        if (classesList.isNotEmpty)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Class',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: selectedClass,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: classesList.map((cls) {
                              return DropdownMenuItem<int>(
                                value: cls.id,
                                child: Text(
                                  '${cls.className} - Section ${cls.section}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedClass = value;
                                selectedSubject = null;
                                students = [];
                                submittedAttendance = {};
                                pendingAttendance = {};
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Subject',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: selectedSubject,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items:
                                selectedClass != null &&
                                    classSubjectsMap[selectedClass] != null
                                ? classSubjectsMap[selectedClass]!.map((
                                    subject,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: subject['id'],
                                      child: Text(subject['name']),
                                    );
                                  }).toList()
                                : [],
                            onChanged: selectedClass != null
                                ? (value) {
                                    setState(() => selectedSubject = value);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Period',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedPeriod,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '10-11',
                                  child: Text('10:00 AM - 11:00 AM'),
                                ),
                                DropdownMenuItem(
                                  value: '11-12',
                                  child: Text('11:00 AM - 12:00 PM'),
                                ),
                                DropdownMenuItem(
                                  value: '12-13',
                                  child: Text('12:00 PM - 01:00 PM'),
                                ),
                                DropdownMenuItem(
                                  value: '13-14',
                                  child: Text('01:00 PM - 02:00 PM'),
                                ),
                                DropdownMenuItem(
                                  value: '14-15',
                                  child: Text('02:00 PM - 03:00 PM'),
                                ),
                                DropdownMenuItem(
                                  value: '15-16',
                                  child: Text('03:00 PM - 04:00 PM'),
                                ),
                                DropdownMenuItem(
                                  value: '16-17',
                                  child: Text('04:00 PM - 05:00 PM'),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => selectedPeriod = value ?? '10-11',
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
          ),

        if (selectedClass != null && selectedSubject != null) ...[
          const SizedBox(height: 20),
          // Stats and Class Info
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Students of ${classesList.firstWhere((c) => c.id == selectedClass!).className} - Section ${classesList.firstWhere((c) => c.id == selectedClass!).section}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Managing attendance for $currentSubjectName on ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(selectedDate))} (${selectedPeriod})',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (pendingAttendance.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: submitAttendance,
                            icon: const Icon(Icons.save),
                            label: const Text('Submit Attendance'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard('Total', students.length, Colors.blue),
                      _buildStatCard(
                        'Present',
                        attendanceStats['present'] ?? 0,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Absent',
                        attendanceStats['absent'] ?? 0,
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Students Grid
          if (students.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final status = getStudentStatus(student.email);
                final isSubmitted = submittedAttendance.containsKey(
                  student.email?.toLowerCase(),
                );

                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                student.fullname?.isNotEmpty == true
                                    ? student.fullname![0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.fullname ?? 'Unnamed Student',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    student.email ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: getStatusColor(status).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                  color: getStatusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isSubmitted) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.green,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    markAttendance(student.email, 'Present'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'Present'
                                      ? Colors.green
                                      : Colors.grey[200],
                                  foregroundColor: status == 'Present'
                                      ? Colors.white
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text(
                                  'Present',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    markAttendance(student.email, 'Absent'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'Absent'
                                      ? Colors.red
                                      : Colors.grey[200],
                                  foregroundColor: status == 'Absent'
                                      ? Colors.white
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text(
                                  'Absent',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No students found in this class',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ] else ...[
          const SizedBox(height: 20),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.info, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Please select a class and subject to manage attendance',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
