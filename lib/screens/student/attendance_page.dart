import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceRecord {
  final int id;
  final String studentName;
  final String date;
  final String status;
  final String? markedByRole;
  final String? remarks;
  final String? section;
  final int? classId;
  final String? className;
  final String? subjectName;
  final String? teacherName;
  final String? createdTime;

  AttendanceRecord({
    required this.id,
    required this.studentName,
    required this.date,
    required this.status,
    this.markedByRole,
    this.remarks,
    this.section,
    this.classId,
    this.className,
    this.subjectName,
    this.teacherName,
    this.createdTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      studentName: json['student_name'] ?? json['student'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'Unknown',
      markedByRole: json['teacher_name'] ?? json['marked_by_role'],
      remarks: json['remarks'],
      section: json['section'] ?? json['sec'],
      classId: json['class_id'],
      className: json['class_name'],
      subjectName: json['subject_name'],
      teacherName: json['teacher_name'],
      createdTime: json['created_time'],
    );
  }
}

class ClassDetails {
  final int id;
  final String? className;
  final String? sec;

  ClassDetails({required this.id, this.className, this.sec});

  factory ClassDetails.fromJson(Map<String, dynamic> json) {
    return ClassDetails(
      id: json['id'] ?? 0,
      className: json['class_name'],
      sec: json['sec'],
    );
  }
}

class StudentData {
  final String fullname;
  final int? classId;
  final String? className;
  final String? section;
  final String? email;

  StudentData({
    required this.fullname,
    this.classId,
    this.className,
    this.section,
    this.email,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      fullname: json['fullname'] ?? '',
      classId: json['class_id'],
      className: json['class_name'],
      section: json['section'],
      email: json['email'],
    );
  }
}

class AttendancePage extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const AttendancePage({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<AttendanceRecord> attendanceData = [];
  bool loading = false;
  String error = "";
  StudentData? studentInfo;
  DateTime selectedDate = DateTime.now();
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/'; // Actual API base URL

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    fetchAttendance();
  }

  Future<StudentData?> fetchStudentDetails(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/students/?email=${Uri.encodeComponent(email)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final studentData = data is List ? data[0] : data;
        return StudentData.fromJson(studentData);
      }
    } catch (e) {
      debugPrint('Error fetching student details: $e');
    }
    return null;
  }

  Future<Map<int, ClassDetails>> fetchClasses() async {
    try {
      final response = await http.get(Uri.parse('$apiBase/classes/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final classMap = <int, ClassDetails>{};
        for (final item in data) {
          final classDetails = ClassDetails.fromJson(item);
          classMap[classDetails.id] = classDetails;
        }
        return classMap;
      }
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
    return {};
  }

  Future<List<AttendanceRecord>> fetchAttendanceData(
    String email,
    StudentData studentData,
    Map<int, ClassDetails> classMap,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/student_attendance/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final rawAttendance = data
            .map((item) => AttendanceRecord.fromJson(item))
            .toList();

        final filteredAttendance = rawAttendance
            .where((record) {
              final recordEmail =
                  (record.studentName.isNotEmpty ? record.studentName : email)
                      .toLowerCase()
                      .trim();
              return recordEmail == email.toLowerCase().trim();
            })
            .map((record) {
              final classDetails = record.classId != null
                  ? classMap[record.classId]
                  : null;
              return AttendanceRecord(
                id: record.id,
                studentName: record.studentName.isNotEmpty
                    ? record.studentName
                    : studentData.fullname,
                date: record.date,
                status: record.status,
                markedByRole:
                    record.teacherName ?? record.markedByRole ?? 'Unknown',
                remarks: record.remarks ?? '',
                section:
                    record.section ??
                    classDetails?.sec ??
                    studentData.section ??
                    'N/A',
                classId: record.classId,
                className:
                    record.className ??
                    classDetails?.className ??
                    studentData.className ??
                    'Unknown',
                subjectName: record.subjectName ?? '',
                teacherName: record.teacherName ?? '',
                createdTime: record.createdTime ?? '',
              );
            })
            .toList();

        return filteredAttendance;
      }
    } catch (e) {
      debugPrint('Error fetching attendance data: $e');
    }
    return [];
  }

  Future<void> fetchAttendance() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final studentData = await fetchStudentDetails(widget.userEmail);
      if (studentData == null) {
        setState(() {
          error = 'No student data found for your account.';
        });
        return;
      }

      setState(() {
        studentInfo = studentData;
      });

      final classMap = await fetchClasses();
      final attendanceRecords = await fetchAttendanceData(
        widget.userEmail,
        studentData,
        classMap,
      );

      setState(() {
        attendanceData = attendanceRecords;
        if (attendanceRecords.isEmpty) {
          error = 'No attendance records found for your account.';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Failed to fetch attendance data. Please try again later.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  int get presentCount =>
      attendanceData.where((att) => att.status == 'Present').length;
  int get absentCount =>
      attendanceData.where((att) => att.status == 'Absent').length;
  int get lateCount =>
      attendanceData.where((att) => att.status == 'Late').length;
  int get totalCount => attendanceData.length;
  String get attendancePercentage => totalCount > 0
      ? ((presentCount / totalCount) * 100).toStringAsFixed(1)
      : '0';

  List<AttendanceRecord> get dayAttendance {
    final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    return attendanceData
        .where((att) => att.date == selectedDateString)
        .toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Late':
        return Colors.yellow;
      case 'Absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatCreatedTime(String? createdTime) {
    if (createdTime == null || createdTime.isEmpty) return 'N/A';

    try {
      final parts = createdTime.split(' ');
      if (parts.length >= 2) {
        final time = parts[1];
        final timeParts = time.split(':');
        if (timeParts.length >= 2) {
          return '${timeParts[0]}:${timeParts[1]}';
        }
      }
      return createdTime;
    } catch (e) {
      return createdTime;
    }
  }

  String formatDisplayDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Map<DateTime, List<String>> get _attendanceEvents {
    final events = <DateTime, List<String>>{};
    for (final record in attendanceData) {
      try {
        final date = DateTime.parse(record.date);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        events[normalizedDate] = [record.status];
      } catch (e) {
        // Ignore invalid dates
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Student Attendance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Header
            if (studentInfo != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '${studentInfo!.className ?? 'Unknown'} - ${studentInfo!.section ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Statistics Cards
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard('$presentCount', 'Present', Colors.green),
                _buildStatCard('$absentCount', 'Absent', Colors.red),
                _buildStatCard('$lateCount', 'Late', Colors.yellow),
                _buildStatCard(
                  '$attendancePercentage%',
                  'Percentage',
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Calendar and Selected Date
            Column(
              children: [
                // Calendar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select a date to view attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TableCalendar(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2030),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          return isSameDay(selectedDate, day);
                        },
                        eventLoader: (day) {
                          return _attendanceEvents[day] ?? [];
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(selectedDate, selectedDay)) {
                            setState(() {
                              selectedDate = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isNotEmpty) {
                              final status = events.first as String;
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Selected Date Details
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Date: ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (dayAttendance.isNotEmpty)
                        ...dayAttendance.map(
                          (attendance) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      attendance.className ?? 'Unknown',
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
                                        color: getStatusColor(
                                          attendance.status,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: getStatusColor(
                                            attendance.status,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        attendance.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: getStatusColor(
                                            attendance.status,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Section ${attendance.section}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (attendance.createdTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Marked at: ${formatCreatedTime(attendance.createdTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No attendance record available for this date.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Attendance History
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Showing ${attendanceData.length} records',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else if (error.isNotEmpty)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchAttendance,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  else if (attendanceData.isEmpty)
                    const Center(
                      child: Text(
                        'No attendance records found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    SizedBox(
                      height: 400, // Fixed height for the list
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio: 2,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: attendanceData.length,
                        itemBuilder: (context, index) {
                          final record = attendanceData[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        record.className ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(
                                          record.status,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: getStatusColor(record.status),
                                        ),
                                      ),
                                      child: Text(
                                        record.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: getStatusColor(record.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatDisplayDate(record.date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Section ${record.section}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (record.subjectName?.isNotEmpty == true)
                                  Text(
                                    'Subject: ${record.subjectName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                if (record.teacherName?.isNotEmpty == true)
                                  Text(
                                    'Teacher: ${record.teacherName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                if (record.createdTime?.isNotEmpty == true)
                                  Text(
                                    'Marked at: ${formatCreatedTime(record.createdTime)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                if (record.remarks?.isNotEmpty == true)
                                  Text(
                                    'Remarks: ${record.remarks}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
