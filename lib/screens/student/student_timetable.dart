import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class Student {
  final int id;
  final String email;
  final String? fullname;
  final int? classId;
  final String? rollNumber;
  final String? section;
  final String? profilePicture;

  Student({
    required this.id,
    required this.email,
    this.fullname,
    this.classId,
    this.rollNumber,
    this.section,
    this.profilePicture,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullname: json['fullname'],
      classId: json['class_id'],
      rollNumber: json['roll_number'],
      section: json['section'],
      profilePicture: json['profile_picture'],
    );
  }
}

class ClassInfo {
  final int id;
  final String className;
  final String sec;
  final String? classTeacherName;
  final String? classTeacherEmail;

  ClassInfo({
    required this.id,
    required this.className,
    required this.sec,
    this.classTeacherName,
    this.classTeacherEmail,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] ?? 0,
      className: json['class_name'] ?? '',
      sec: json['sec'] ?? '',
      classTeacherName: json['class_teacher_name'],
      classTeacherEmail: json['class_teacher_email'],
    );
  }
}

class Timetable {
  final int id;
  final String subjectName;
  final String teacherName;
  final String className;
  final String section;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String roomNumber;
  final int? classId;
  final String? subjectCode;
  final Color subjectColor;

  Timetable({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    required this.className,
    required this.section,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
    this.classId,
    this.subjectCode,
    required this.subjectColor,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) {
    // Generate color based on subject name hash
    final colors = [
      Colors.blue[100]!,
      Colors.green[100]!,
      Colors.yellow[100]!,
      Colors.red[100]!,
      Colors.purple[100]!,
      Colors.pink[100]!,
      Colors.indigo[100]!,
      Colors.grey[100]!,
    ];
    final colorIndex =
        json['subject_name']?.hashCode.abs() ?? 0 % colors.length;

    return Timetable(
      id: json['id'] ?? 0,
      subjectName: json['subject_name'] ?? '',
      teacherName: json['teacher_name'] ?? '',
      className: json['class_name'] ?? '',
      section: json['section'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      roomNumber: json['room_number'] ?? '',
      classId: json['class_id'],
      subjectCode: json['subject_code'],
      subjectColor: colors[colorIndex],
    );
  }
}

class StudentTimetablePage extends StatefulWidget {
  const StudentTimetablePage({super.key});

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  Student? student;
  ClassInfo? classInfo;
  List<Timetable> timetable = [];
  List<Timetable> filteredTimetable = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  String? error;
  String viewMode = "calendar";

  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    fetchStudentAndTimetable();
  }

  Future<void> fetchStudentAndTimetable() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Get student email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null || email.isEmpty) {
        setState(() {
          error = 'No logged-in student email found.';
          isLoading = false;
        });
        return;
      }

      // Fetch student data
      final studentRes = await http.get(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/students/',
        ),
      );

      if (!studentRes.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to fetch students: ${studentRes.statusCode}');
      }

      final allStudents = json.decode(studentRes.body) as List;
      final matchedStudent = allStudents
          .map((s) => Student.fromJson(s))
          .cast<Student?>()
          .firstWhere(
            (s) => s!.email.toLowerCase() == email.toLowerCase(),
            orElse: () => null,
          );

      if (matchedStudent == null) {
        throw Exception('Student profile not found in system');
      }

      setState(() => student = matchedStudent);

      // Fetch class information
      final classRes = await http.get(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/classes/',
        ),
      );

      if (classRes.statusCode.toString().startsWith('2')) {
        final allClasses = json.decode(classRes.body) as List;
        final matchedClass = allClasses
            .map((c) => ClassInfo.fromJson(c))
            .cast<ClassInfo?>()
            .firstWhere(
              (c) => c!.id == matchedStudent.classId,
              orElse: () => null,
            );

        setState(() => classInfo = matchedClass);
      }

      // Fetch timetable data
      await fetchTimetable();
    } catch (e) {
      setState(() {
        error = 'Could not load data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTimetable() async {
    if (student?.classId == null) return;

    try {
      final res = await http.get(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/timetable/',
        ),
      );

      if (!res.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to fetch timetable: ${res.statusCode}');
      }

      final data = json.decode(res.body) as List;
      final filtered = data
          .map((t) => Timetable.fromJson(t))
          .where((t) => t.classId?.toString() == student!.classId?.toString())
          .toList();

      // Sort by day and time
      const dayOrder = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
      ];
      filtered.sort((a, b) {
        final dayCompare =
            dayOrder.indexOf(a.dayOfWeek) - dayOrder.indexOf(b.dayOfWeek);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });

      setState(() {
        timetable = filtered;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load timetable: $e';
      });
    }
  }

  void handleDateClick(DateTime date) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayNameFormatted = dayNames[date.weekday - 1];

    // Filter timetable for selected day
    final filtered = timetable
        .where(
          (t) => t.dayOfWeek.toLowerCase() == dayNameFormatted.toLowerCase(),
        )
        .toList();
    setState(() {
      selectedDate = date;
      filteredTimetable = filtered;
    });
  }

  String formatTime(String timeString) {
    if (timeString.isEmpty) return "N/A";
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final ampm = hour >= 12 ? "PM" : "AM";
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        return '$displayHour:$minute $ampm';
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  Map<String, List<Timetable>> get timetableByDay {
    final result = <String, List<Timetable>>{};
    for (final item in timetable) {
      if (!result.containsKey(item.dayOfWeek)) {
        result[item.dayOfWeek] = [];
      }
      result[item.dayOfWeek]!.add(item);
    }
    return result;
  }

  Timetable? getCurrentPeriod() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final today = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];

    try {
      return timetable.firstWhere((item) {
        if (item.dayOfWeek != today) return false;

        try {
          final startParts = item.startTime.split(':').map(int.parse).toList();
          final endParts = item.endTime.split(':').map(int.parse).toList();
          final startTime = startParts[0] * 60 + startParts[1];
          final endTime = endParts[0] * 60 + endParts[1];

          return currentTime >= startTime && currentTime <= endTime;
        } catch (e) {
          return false;
        }
      });
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPeriod = getCurrentPeriod();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '📚 Class Timetable',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'View your class schedule and academic calendar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Class Info
        if (classInfo != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  Text(
                    '${classInfo!.className} • ${classInfo!.sec} Section',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (classInfo!.classTeacherName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Class Teacher: ${classInfo!.classTeacherName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (student?.rollNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Student ID: ${student!.rollNumber}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Current Period Alert
        if (currentPeriod != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Live: ${currentPeriod.subjectName} (${formatTime(currentPeriod.startTime)} - ${formatTime(currentPeriod.endTime)})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // View Mode Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
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
            child: Row(
              children: [
                Expanded(child: _buildTabButton('📅 Calendar', 'calendar')),
                Expanded(child: _buildTabButton('🕐 Schedule', 'timetable')),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Content based on view mode
        if (viewMode == "calendar")
          _buildCalendarView()
        else
          _buildTimetableView(),

        // Footer Info
        if (timetable.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '${timetable.length} classes scheduled',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Calendar and Side Panel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 768;
              return Column(
                children: [
                  // Calendar
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        const Text(
                          '📅 Academic Calendar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: focusedDay,
                          calendarFormat: calendarFormat,
                          selectedDayPredicate: (day) =>
                              isSameDay(selectedDay, day),
                          onDaySelected: (selected, focused) {
                            setState(() {
                              selectedDay = selected;
                              focusedDay = focused;
                            });
                            handleDateClick(selected);
                          },
                          onFormatChanged: (format) {
                            setState(() => calendarFormat = format);
                          },
                          onPageChanged: (focused) {
                            setState(() => focusedDay = focused);
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          eventLoader: (day) {
                            // Return leave events for this day
                            return timetable.where((t) {
                              final dayNames = [
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday',
                              ];
                              final dayName = dayNames[day.weekday - 1];
                              return t.dayOfWeek.toLowerCase() ==
                                  dayName.toLowerCase();
                            }).toList();
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty) return null;

                              return Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected Date Details
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        Text(
                          selectedDate.toLocal().toString().split(
                            ' ',
                          )[0], // Format date
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '📚 Schedule',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (filteredTimetable.isNotEmpty)
                          Column(
                            children: filteredTimetable
                                .map((item) => _buildClassCard(item))
                                .toList(),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No classes scheduled for this date',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimetableView() {
    final days = timetableByDay.keys.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                const Text(
                  '🕐 Weekly Schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${timetable.length} classes scheduled',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (days.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 768
                      ? 4
                      : MediaQuery.of(context).size.width > 600
                      ? 2
                      : 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final classes = timetableByDay[day]!;
                  return _buildDayScheduleCard(day, classes);
                },
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.schedule, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Schedule Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your class schedule is being prepared.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String mode) {
    final isSelected = viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(Timetable classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: classItem.subjectColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classItem.subjectName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '⏰ ${formatTime(classItem.startTime)} - ${formatTime(classItem.endTime)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 2),
          Text(
            '👨‍🏫 ${classItem.teacherName} • 🚪 ${classItem.roomNumber}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDayScheduleCard(String day, List<Timetable> classes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return _buildClassCard(classes[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
