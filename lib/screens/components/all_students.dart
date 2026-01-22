import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Student {
  final int? id;
  final String? email;
  final String? fullname;
  final String? studentId;
  final int? classId;
  final String? className;
  final String? section;
  final String? gender;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? phone;
  final String? residentialAddress;
  final String? academicYear;
  final String? profilePicture;

  Student({
    this.id,
    this.email,
    this.fullname,
    this.studentId,
    this.classId,
    this.className,
    this.section,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.phone,
    this.residentialAddress,
    this.academicYear,
    this.profilePicture,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      email: json['email'],
      fullname: json['fullname'],
      studentId: json['student_id'],
      classId: json['class_id'],
      className: json['class_name'],
      section: json['section'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      bloodGroup: json['blood_group'],
      phone: json['phone'],
      residentialAddress: json['residential_address'],
      academicYear: json['academic_year'],
      profilePicture: json['profile_picture'],
    );
  }
}

class Class {
  final int id;
  final String? className;
  final String? sec;

  Class({required this.id, this.className, this.sec});

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      id: json['id'],
      className: json['class_name'],
      sec: json['sec'],
    );
  }
}

class AttendanceRecord {
  final int? id;
  final String? date;
  final String? status;
  final String? checkInTime;
  final String? student;

  AttendanceRecord({
    this.id,
    this.date,
    this.status,
    this.checkInTime,
    this.student,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      date: json['date'],
      status: json['status'],
      checkInTime: json['check_in_time'] ?? json['check_in'],
      student: json['student'],
    );
  }
}

class LeaveRecord {
  final int? id;
  final String? applicantEmail;
  final String? leaveType;
  final String? status;
  final String? startDate;
  final String? endDate;
  final String? reason;

  LeaveRecord({
    this.id,
    this.applicantEmail,
    this.leaveType,
    this.status,
    this.startDate,
    this.endDate,
    this.reason,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      id: json['id'],
      applicantEmail: json['applicant_email'],
      leaveType: json['leave_type'],
      status: json['status'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      reason: json['reason'],
    );
  }
}

class GradeRecord {
  final int? id;
  final String? subjectName;
  final String? marksObtained;
  final String? grade;
  final String? totalMarks;
  final String? remarks;

  GradeRecord({
    this.id,
    this.subjectName,
    this.marksObtained,
    this.grade,
    this.totalMarks,
    this.remarks,
  });

  factory GradeRecord.fromJson(Map<String, dynamic> json) {
    return GradeRecord(
      id: json['id'],
      subjectName: json['subject_name'],
      marksObtained: json['marks_obtained'],
      grade: json['grade'],
      totalMarks: json['total_marks'],
      remarks: json['remarks'],
    );
  }
}

class AllStudents extends StatefulWidget {
  const AllStudents({super.key});

  @override
  State<AllStudents> createState() => _AllStudentsState();
}

class _AllStudentsState extends State<AllStudents>
    with TickerProviderStateMixin {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Student> students = [];
  List<Class> classes = [];
  Student? selectedStudent;
  List<AttendanceRecord> attendance = [];
  List<LeaveRecord> leaves = [];
  List<GradeRecord> grades = [];
  bool loading = false;
  String activeTab = "overview";
  String searchTerm = "";
  String classFilter = "all";
  String sectionFilter = "all";
  String attendanceFilter = "all";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        activeTab = [
          "overview",
          "attendance",
          "leaves",
          "grades",
          "analytics",
        ][_tabController.index];
      });
    });
    fetchInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    setState(() => loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/students/')),
        http.get(Uri.parse('$apiBaseUrl/classes/')),
      ]);

      if (responses[0].statusCode == 200) {
        final studentsData = jsonDecode(responses[0].body) as List<dynamic>;
        setState(
          () =>
              students = studentsData.map((e) => Student.fromJson(e)).toList(),
        );
      }

      if (responses[1].statusCode == 200) {
        final classesData = jsonDecode(responses[1].body) as List<dynamic>;
        setState(
          () => classes = classesData.map((e) => Class.fromJson(e)).toList(),
        );
      }
    } catch (error) {
      debugPrint('Error fetching initial data: $error');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchStudentDetails(Student student) async {
    setState(() {
      selectedStudent = student;
      loading = true;
      activeTab = "overview";
      _tabController.index = 0;
    });

    try {
      final responses =
          await Future.wait([
            http.get(Uri.parse('$apiBaseUrl/student_attendance/')),
            http.get(Uri.parse('$apiBaseUrl/leaves/')),
            http.get(Uri.parse('$apiBaseUrl/grades/?student=${student.email}')),
          ]).catchError(
            (_) => [
              http.Response('[]', 200),
              http.Response('[]', 200),
              http.Response('[]', 200),
            ],
          );

      // Process attendance
      List<AttendanceRecord> studentAttendance = [];
      if (responses[0].statusCode == 200) {
        final attendanceData = jsonDecode(responses[0].body) as List<dynamic>;
        final allAttendance = attendanceData
            .map((e) => AttendanceRecord.fromJson(e))
            .toList();
        studentAttendance = allAttendance.where((a) {
          final email = student.email?.toLowerCase();
          if (email == null) return false;
          final recordEmail = a.student?.toLowerCase();
          return recordEmail == email;
        }).toList();
      }

      // Process leaves
      List<LeaveRecord> studentLeaves = [];
      if (responses[1].statusCode == 200) {
        final leavesData = jsonDecode(responses[1].body) as List<dynamic>;
        final allLeaves = leavesData
            .map((e) => LeaveRecord.fromJson(e))
            .toList();
        studentLeaves = allLeaves
            .where(
              (l) =>
                  l.applicantEmail?.toLowerCase() ==
                  student.email?.toLowerCase(),
            )
            .toList();
      }

      // Process grades
      List<GradeRecord> studentGrades = [];
      if (responses[2].statusCode == 200) {
        final gradesData = jsonDecode(responses[2].body) as List<dynamic>;
        studentGrades = gradesData.map((e) => GradeRecord.fromJson(e)).toList();
      }

      setState(() {
        attendance = studentAttendance;
        leaves = studentLeaves;
        grades = studentGrades;
      });
    } catch (error) {
      debugPrint('Error fetching student details: $error');
      setState(() {
        attendance = [];
        leaves = [];
        grades = [];
      });
    } finally {
      setState(() => loading = false);
    }
  }

  void goBack() {
    setState(() {
      selectedStudent = null;
      attendance = [];
      leaves = [];
      grades = [];
      activeTab = "overview";
      _tabController.index = 0;
    });
  }

  Map<String, dynamic> calculateStats() {
    final totalDays = attendance.length;
    final presentDays = attendance.where((a) => a.status == "Present").length;
    final absentDays = attendance.where((a) => a.status == "Absent").length;
    final attendancePercentage = totalDays > 0
        ? ((presentDays / totalDays) * 100).toStringAsFixed(1)
        : "0";

    final approvedLeaves = leaves.where((l) => l.status == "Approved").length;
    final pendingLeaves = leaves.where((l) => l.status == "Pending").length;

    final averageGrade = grades.isNotEmpty
        ? (grades
                      .map(
                        (g) =>
                            double.tryParse(
                              g.grade ?? g.marksObtained ?? "0",
                            ) ??
                            0,
                      )
                      .reduce((a, b) => a + b) /
                  grades.length)
              .toStringAsFixed(1)
        : "0";

    final excellentGrades = grades
        .where(
          (g) =>
              (double.tryParse(g.grade ?? g.marksObtained ?? "0") ?? 0) >= 4.0,
        )
        .length;
    final goodGrades = grades.where((g) {
      final gradeVal = double.tryParse(g.grade ?? g.marksObtained ?? "0") ?? 0;
      return gradeVal >= 3.0 && gradeVal < 4.0;
    }).length;
    final averageGrades = grades.where((g) {
      final gradeVal = double.tryParse(g.grade ?? g.marksObtained ?? "0") ?? 0;
      return gradeVal >= 2.0 && gradeVal < 3.0;
    }).length;
    final poorGrades = grades
        .where(
          (g) =>
              (double.tryParse(g.grade ?? g.marksObtained ?? "0") ?? 0) < 2.0,
        )
        .length;

    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'attendancePercentage': attendancePercentage,
      'approvedLeaves': approvedLeaves,
      'pendingLeaves': pendingLeaves,
      'averageGrade': averageGrade,
      'totalSubjects': grades.length,
      'excellentGrades': excellentGrades,
      'goodGrades': goodGrades,
      'averageGrades': averageGrades,
      'poorGrades': poorGrades,
    };
  }

  Class? getClassInfoForStudent(Student student) {
    if (student.classId == null) return null;
    return classes.firstWhere((cls) => cls.id == student.classId);
  }

  List<String> get uniqueClasses {
    return classes
        .map((cls) => cls.className)
        .where((name) => name != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  List<String> get uniqueSectionsForSelectedClass {
    if (classFilter == "all") return [];
    return classes
        .where((cls) => cls.className == classFilter)
        .map((cls) => cls.sec)
        .where((sec) => sec != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  List<Student> get filteredStudents {
    return students.where((student) {
      final matchesSearch =
          student.fullname?.toLowerCase().contains(searchTerm.toLowerCase()) ==
              true ||
          student.email?.toLowerCase().contains(searchTerm.toLowerCase()) ==
              true ||
          student.studentId?.toLowerCase().contains(searchTerm.toLowerCase()) ==
              true;

      final classInfo = getClassInfoForStudent(student);
      final className = classInfo?.className;
      final section = classInfo?.sec;

      final matchesClass = classFilter == "all" || className == classFilter;
      final matchesSection =
          sectionFilter == "all" ||
          sectionFilter == "" ||
          section == sectionFilter;

      return matchesSearch && matchesClass && matchesSection;
    }).toList();
  }

  void exportStudentData() {
    if (selectedStudent == null) return;

    final data = {
      'student': selectedStudent!.fullname,
      'email': selectedStudent!.email,
      'attendance': attendance,
      'leaves': leaves,
      'grades': grades,
      'stats': calculateStats(),
    };

    // In Flutter, we'd typically use a package like share_plus or path_provider
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality would be implemented here'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = selectedStudent != null
        ? calculateStats()
        : <String, dynamic>{};

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: selectedStudent == null
            ? _buildStudentsGrid()
            : _buildStudentDetails(stats),
      ),
    );
  }

  Widget _buildStudentsGrid() {
    return Column(
      children: [
        // Header Section
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Student Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Comprehensive student monitoring and management system with advanced analytics',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Search and Filter Section
        Container(
          margin: const EdgeInsets.only(bottom: 24),
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
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => searchTerm = value),
                      decoration: const InputDecoration(
                        hintText: 'Search by name, email, or ID...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: classFilter,
                      onChanged: (value) {
                        setState(() {
                          classFilter = value!;
                          sectionFilter = "all";
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: "all",
                          child: Text("All Classes"),
                        ),
                        ...uniqueClasses.map(
                          (cls) => DropdownMenuItem(
                            value: cls,
                            child: Text("Class $cls"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (classFilter != "all") ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: sectionFilter,
                        onChanged: (value) =>
                            setState(() => sectionFilter = value!),
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: "all",
                            child: Text("All Sections"),
                          ),
                          ...uniqueSectionsForSelectedClass.map(
                            (sec) => DropdownMenuItem(
                              value: sec,
                              child: Text("Section $sec"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filteredStudents.length} students',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Students Grid
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filteredStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        searchTerm.isEmpty && classFilter == "all"
                            ? 'No students found'
                            : 'No students match your filters',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          searchTerm = "";
                          classFilter = "all";
                          sectionFilter = "all";
                        }),
                        child: const Text('Clear All Filters'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 3
                        : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final classInfo = getClassInfoForStudent(student);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => fetchStudentDetails(student),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: student.profilePicture != null
                                    ? NetworkImage(student.profilePicture!)
                                    : null,
                                child: student.profilePicture == null
                                    ? Text(
                                        student.fullname?.isNotEmpty == true
                                            ? student.fullname![0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                student.fullname ?? 'Unknown Student',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Class ${classInfo?.className ?? 'N/A'} • Sec ${classInfo?.sec ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student.email ?? 'No email',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'ID: ${student.studentId ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.blue,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (student.gender != null) ...[
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        student.gender!,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.purple,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentDetails(Map<String, dynamic> stats) {
    final student = selectedStudent!;
    final classInfo = getClassInfoForStudent(student);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with Back and Actions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: goBack,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Back to Students',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: exportStudentData,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Student Header Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                  Color(0xFF047857),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: student.profilePicture != null
                      ? NetworkImage(student.profilePicture!)
                      : null,
                  child: student.profilePicture == null
                      ? Text(
                          student.fullname?.isNotEmpty == true
                              ? student.fullname![0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullname ?? 'Unknown Student',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Class ${classInfo?.className ?? 'N/A'} • Section ${classInfo?.sec ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFE8F5E8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip('ID', student.studentId ?? 'N/A'),
                          _buildInfoChip('Email', student.email ?? 'N/A'),
                          _buildInfoChip('Phone', student.phone ?? 'N/A'),
                          _buildInfoChip('Gender', student.gender ?? 'N/A'),
                          _buildInfoChip('DOB', student.dateOfBirth ?? 'N/A'),
                          _buildInfoChip(
                            'Year',
                            student.academicYear ?? '2024',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats Cards
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 800
                    ? 4
                    : width > 600
                    ? 2
                    : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      '${stats['attendancePercentage']}%',
                      'Attendance',
                      Icons.trending_up,
                      Colors.green,
                    ),
                    _buildStatCard(
                      '${stats['totalSubjects']}',
                      'Subjects',
                      Icons.book,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      '${stats['averageGrade']}',
                      'Avg Grade',
                      Icons.grade,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      '${stats['approvedLeaves']}',
                      'Approved Leaves',
                      Icons.check_circle,
                      Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Tabs Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: DefaultTabController(
                length: 5,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Overview'),
                        Tab(text: 'Attendance'),
                        Tab(text: 'Leaves'),
                        Tab(text: 'Grades'),
                        Tab(text: 'Analytics'),
                      ],
                    ),
                    SizedBox(
                      height: 500, // Fixed height for tab content
                      child: TabBarView(
                        children: [
                          _buildOverviewTab(stats),
                          _buildAttendanceTab(stats),
                          _buildLeavesTab(),
                          _buildGradesTab(stats),
                          _buildAnalyticsTab(stats),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> stats) {
    final student = selectedStudent!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Personal Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Full Name', student.fullname ?? 'N/A'),
                  _buildInfoRow('Student ID', student.studentId ?? 'N/A'),
                  _buildInfoRow(
                    'Class & Section',
                    '${student.className ?? 'N/A'} - ${student.section ?? 'N/A'}',
                  ),
                  _buildInfoRow('Gender', student.gender ?? 'N/A'),
                  _buildInfoRow('Date of Birth', student.dateOfBirth ?? 'N/A'),
                  _buildInfoRow('Blood Group', student.bloodGroup ?? 'N/A'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    Icons.email,
                    'Email',
                    student.email ?? 'N/A',
                  ),
                  _buildContactRow(
                    Icons.phone,
                    'Phone',
                    student.phone ?? 'N/A',
                  ),
                  _buildContactRow(
                    Icons.location_on,
                    'Address',
                    student.residentialAddress ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Performance Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildPerformanceCard(
                        '${stats['presentDays']}',
                        'Days Present',
                        Colors.green,
                      ),
                      _buildPerformanceCard(
                        '${stats['absentDays']}',
                        'Days Absent',
                        Colors.red,
                      ),
                      _buildPerformanceCard(
                        '${stats['totalSubjects']}',
                        'Subjects',
                        Colors.blue,
                      ),
                      _buildPerformanceCard(
                        '${stats['averageGrade']}',
                        'Avg Grade',
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Attendance Records',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: attendanceFilter,
                  onChanged: (value) =>
                      setState(() => attendanceFilter = value!),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(
                      value: 'present',
                      child: Text('Present Only'),
                    ),
                    DropdownMenuItem(
                      value: 'absent',
                      child: Text('Absent Only'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (attendance.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('No attendance records found')),
            )
          else
            ...attendance
                .where((record) {
                  if (attendanceFilter == 'all') return true;
                  if (attendanceFilter == 'present' &&
                      record.status == 'Present')
                    return true;
                  if (attendanceFilter == 'absent' && record.status == 'Absent')
                    return true;
                  return false;
                })
                .map(
                  (record) => Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: record.status == 'Present'
                            ? Colors.green
                            : Colors.red,
                        child: Icon(
                          record.status == 'Present'
                              ? Icons.check
                              : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(record.date ?? 'Unknown date'),
                      subtitle: Text(
                        'Check-in: ${record.checkInTime ?? 'Not recorded'}',
                      ),
                      trailing: Text(record.status ?? 'Unknown'),
                    ),
                  ),
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLeavesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (loading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (leaves.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('No leave records found')),
            )
          else
            ...leaves.map(
              (leave) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(leave.status),
                    child: Icon(
                      _getStatusIcon(leave.status),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(leave.leaveType ?? 'Leave'),
                  subtitle: Text(
                    '${leave.startDate ?? 'N/A'} to ${leave.endDate ?? 'N/A'}',
                  ),
                  trailing: Text(leave.status ?? 'Unknown'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradesTab(Map<String, dynamic> stats) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : grades.isEmpty
        ? const Center(child: Text('No grade records found'))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Grades List
                ...grades.map(
                  (grade) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(grade.subjectName ?? 'Unknown Subject'),
                      subtitle: Text(
                        'Grade: ${grade.grade ?? grade.marksObtained ?? 'N/A'} / ${grade.totalMarks ?? 'N/A'}',
                      ),
                      trailing: Text(grade.remarks ?? ''),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Performance Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grade Distribution',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGradeBar(
                          'Excellent (4.0+)',
                          stats['excellentGrades'],
                          stats['totalSubjects'],
                          Colors.green,
                        ),
                        _buildGradeBar(
                          'Good (3.0-3.9)',
                          stats['goodGrades'],
                          stats['totalSubjects'],
                          Colors.green,
                        ),
                        _buildGradeBar(
                          'Average (2.0-2.9)',
                          stats['averageGrades'],
                          stats['totalSubjects'],
                          Colors.yellow,
                        ),
                        _buildGradeBar(
                          'Needs Improvement (<2.0)',
                          stats['poorGrades'],
                          stats['totalSubjects'],
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildAnalyticsTab(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Student Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildAnalyticsCard(
                'Attendance Rate',
                '${stats['attendancePercentage']}%',
                Colors.green,
              ),
              _buildAnalyticsCard(
                'Total Subjects',
                '${stats['totalSubjects']}',
                Colors.blue,
              ),
              _buildAnalyticsCard(
                'Average Grade',
                '${stats['averageGrade']}',
                Colors.purple,
              ),
              _buildAnalyticsCard(
                'Approved Leaves',
                '${stats['approvedLeaves']}',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(
                '$count',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.yellow;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
