import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TimetableEntry {
  final String? teacher;
  final String? className;
  final String? section;
  final String? dayOfWeek;
  final String? subjectName;
  final String? startTime;
  final String? endTime;
  final String? roomNumber;
  final String? duration;

  TimetableEntry({
    this.teacher,
    this.className,
    this.section,
    this.dayOfWeek,
    this.subjectName,
    this.startTime,
    this.endTime,
    this.roomNumber,
    this.duration,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      teacher: json['teacher'],
      className: json['class_name'],
      section: json['section'],
      dayOfWeek: json['day_of_week'],
      subjectName: json['subject_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      roomNumber: json['room_number'],
      duration: json['duration'],
    );
  }
}

class ClassInfo {
  final String className;
  final String section;
  final String? subject;
  final String? startTime;
  final String? roomNumber;

  ClassInfo({
    required this.className,
    required this.section,
    this.subject,
    this.startTime,
    this.roomNumber,
  });
}

class LeaveRecord {
  final String? status;
  final String? startDate;
  final String? endDate;
  final String? applicant;
  final String? reason;
  final String? email;

  LeaveRecord({
    this.status,
    this.startDate,
    this.endDate,
    this.applicant,
    this.reason,
    this.email,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      status: json['status'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      applicant: json['applicant'],
      reason: json['reason'],
      email: json['email'],
    );
  }
}

class TeacherAttendanceRecord {
  final String? email;
  final String? status;

  TeacherAttendanceRecord({this.email, this.status});

  factory TeacherAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceRecord(
      email: json['email'],
      status: json['status'],
    );
  }
}

class TeacherDashboard extends StatefulWidget {
  final Function(String)? onNavigate;

  const TeacherDashboard({super.key, this.onNavigate});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  String? teacherEmail;
  String teacherName = "Teacher";
  List<TimetableEntry> todayTimetable = [];
  List<ClassInfo> classes = [];
  List<LeaveRecord> recentLeaves = [];
  List<TimetableEntry> upcomingClasses = [];
  int teacherAttendancePercentage = 0;
  bool loading = true;
  int activeStats = 0;

  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();
    // Stats animation
    Future.delayed(Duration.zero, () {
      _startStatsAnimation();
    });
  }

  void _startStatsAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          activeStats = (activeStats + 1) % 4;
        });
        _startStatsAnimation();
      }
    });
  }

  Future<void> fetchTeacherInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final name =
          prefs.getString('user_name') ?? email?.split('@')[0] ?? 'Teacher';

      if (mounted) {
        setState(() {
          teacherEmail = email;
          teacherName = name;
        });
      }

      if (email != null) {
        await fetchDashboardData();
      }
    } catch (e) {
      debugPrint('Error loading teacher info: $e');
    }
  }

  Future<void> fetchDashboardData() async {
    if (teacherEmail == null) return;

    setState(() => loading = true);

    try {
      // Fetch all dashboard data
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/timetable/')),
        http.get(Uri.parse('$apiBaseUrl/grades/')),
        http.get(Uri.parse('$apiBaseUrl/leaves/')),
        http.get(Uri.parse('$apiBaseUrl/attendance/')),
        http.get(Uri.parse('$apiBaseUrl/students/')),
      ]);

      // Check response status codes
      for (int i = 0; i < responses.length; i++) {
        if (responses[i].statusCode != 200) {
          throw Exception(
            'API request failed for endpoint ${i + 1} with status ${responses[i].statusCode}',
          );
        }
      }

      // Parse responses
      final timetableData = jsonDecode(responses[0].body) as List<dynamic>;
      final leavesData = jsonDecode(responses[2].body) as List<dynamic>;
      final teacherAttendanceData =
          jsonDecode(responses[3].body) as List<dynamic>;

      // Filter teacher's timetable by email
      final timetable = timetableData
          .map((t) => TimetableEntry.fromJson(t))
          .where((t) => t.teacher == teacherEmail)
          .toList();

      // Get today's weekday name
      final today = DateTime.now().toString().split(' ')[0]; // Get date part
      final todayWeekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final todayName = weekdays[todayWeekday - 1];
      final todaySchedule = timetable
          .where((t) => t.dayOfWeek == todayName)
          .toList();

      // Get upcoming classes (next 2 days)
      final days = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
      ];
      final todayIndex = DateTime.now().weekday % 7;
      final upcomingDays = [days[(todayIndex) % 7], days[(todayIndex + 1) % 7]];
      final upcomingSchedule = timetable
          .where(
            (t) => t.dayOfWeek != null && upcomingDays.contains(t.dayOfWeek),
          )
          .take(3)
          .toList();

      // Create unique class list
      final uniqueClasses = <ClassInfo>[];
      for (final entry in timetable) {
        final existing = uniqueClasses.firstWhere(
          (c) => c.className == entry.className && c.section == entry.section,
          orElse: () => ClassInfo(className: '', section: ''),
        );

        if (existing.className.isEmpty) {
          uniqueClasses.add(
            ClassInfo(
              className: entry.className ?? '',
              section: entry.section ?? '',
              subject: entry.subjectName,
              startTime: entry.startTime,
              roomNumber: entry.roomNumber,
            ),
          );
        }
      }

      // Get recent approved leaves
      final recent = leavesData
          .map((l) => LeaveRecord.fromJson(l))
          .where((l) => l.status == "Approved")
          .take(4)
          .toList();

      // Calculate teacher attendance
      final teacherAttendanceRecords = teacherAttendanceData
          .map((a) => TeacherAttendanceRecord.fromJson(a))
          .where((a) => a.email == teacherEmail)
          .toList();

      final totalAttendanceDays = teacherAttendanceRecords.length;
      final presentDays = teacherAttendanceRecords
          .where((a) => a.status == "Present")
          .length;

      final attendancePercentage = totalAttendanceDays > 0
          ? ((presentDays / totalAttendanceDays) * 100).round()
          : 0;

      if (mounted) {
        setState(() {
          todayTimetable = todaySchedule;
          upcomingClasses = upcomingSchedule;
          classes = uniqueClasses;
          recentLeaves = recent;
          teacherAttendancePercentage = attendancePercentage;
        });
      }
    } catch (error) {
      debugPrint('Error loading teacher dashboard: $error');
      // Set empty states when API fails
      if (mounted) {
        setState(() {
          todayTimetable = [];
          upcomingClasses = [];
          classes = [];
          recentLeaves = [];
          teacherAttendancePercentage = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get stats => [
    {
      'label': 'Classes Assigned',
      'value': classes.length.toString(),
      'icon': Icons.book,
      'color': Colors.blue.value,
      'description': 'Total classes you teach',
    },
    {
      'label': 'Today\'s Classes',
      'value': todayTimetable.length.toString(),
      'icon': Icons.access_time,
      'color': Colors.orange.value,
      'description': 'Scheduled for today',
    },
    {
      'label': 'Teacher Attendance',
      'value': '$teacherAttendancePercentage%',
      'icon': Icons.check_circle,
      'color': Colors.purple.value,
      'description': 'Your attendance percentage',
    },
  ];

  List<Map<String, dynamic>> get quickActions => [
    {
      'label': 'Manage Grades',
      'menuItem': 'Marks',
      'icon': Icons.bar_chart,
      'color': Colors.blue.value,
    },
    {
      'label': 'View Students',
      'menuItem': 'Monthly Report',
      'icon': Icons.people,
      'color': Colors.green.value,
    },
    {
      'label': 'Mark Attendance',
      'menuItem': 'Attendance',
      'icon': Icons.check_circle,
      'color': Colors.orange.value,
    },
    {
      'label': 'Create Assignment',
      'menuItem': 'Assignments',
      'icon': Icons.assignment,
      'color': Colors.purple.value,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your dashboard...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${teacherName.split(" ")[0]}! 👋',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Here\'s your overview for ${DateTime.now().toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Statistics Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 768
                ? 3
                : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: stats.asMap().entries.map((entry) {
              final stat = entry.value;
              final isActive = entry.key == activeStats;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                  border: isActive
                      ? Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 2,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(stat['color']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        stat['icon'],
                        size: 24,
                        color: Color(stat['color']),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stat['value'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['label'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['description'],
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Main Content Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 768;
              return isLargeScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildTodaySchedule(),
                              const SizedBox(height: 24),
                              _buildYourClasses(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _buildUpcomingClasses(),
                              const SizedBox(height: 24),
                              _buildRecentLeaves(),
                              const SizedBox(height: 24),
                              _buildQuickActions(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildTodaySchedule(),
                        const SizedBox(height: 24),
                        _buildYourClasses(),
                        const SizedBox(height: 24),
                        _buildUpcomingClasses(),
                        const SizedBox(height: 24),
                        _buildRecentLeaves(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.access_time, size: 24, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Today\'s Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateTime.now().toLocal().toString().split(' ')[0],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (todayTimetable.isNotEmpty)
            ...todayTimetable.map(
              (classItem) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classItem.subjectName ?? 'No Subject',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${classItem.className ?? 'No Class'} ${classItem.section != null ? '• ${classItem.section}' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Room: ${classItem.roomNumber ?? 'Not assigned'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${classItem.startTime?.substring(0, 5) ?? 'N/A'} - ${classItem.endTime?.substring(0, 5) ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          classItem.duration ?? '1 hour',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Classes Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enjoy your free day!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYourClasses() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.people, size: 24, color: Colors.green),
              const SizedBox(width: 12),
              const Text(
                'Your Classes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${classes.length} classes',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: classes
                .map(
                  (cls) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cls.className,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Section: ${cls.section}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (cls.subject != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Subject: ${cls.subject}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (cls.startTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Time: ${cls.startTime}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (cls.roomNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Room No: ${cls.roomNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClasses() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.calendar_today, size: 24, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Upcoming Classes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (upcomingClasses.isNotEmpty)
            ...upcomingClasses.map(
              (classItem) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          classItem.subjectName ?? 'No Subject',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            classItem.dayOfWeek ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${classItem.className ?? 'No Class'} • ${classItem.startTime?.substring(0, 5) ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No upcoming classes',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentLeaves() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.check_circle, size: 24, color: Colors.purple),
              const SizedBox(width: 12),
              const Text(
                'Recent Approved Leaves',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (recentLeaves.isNotEmpty)
            ...recentLeaves.map(
              (leave) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  border: Border.all(color: Colors.purple[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          leave.applicant ?? 'Student',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      leave.reason ?? 'No reason provided',
                      style: TextStyle(fontSize: 12, color: Colors.purple[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${leave.startDate ?? 'N/A'} to ${leave.endDate ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.purple[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No recent leaves',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: quickActions
                .map(
                  (action) => GestureDetector(
                    onTap: () {
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(action['menuItem']);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action['icon'], size: 24, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            action['label'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
