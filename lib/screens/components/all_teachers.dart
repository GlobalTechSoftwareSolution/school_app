import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Teacher {
  final int? id;
  final String? email;
  final String? fullname;
  final String? employeeId;
  final String? phone;
  final String? department;
  final String? departmentName;
  final String? subject;
  final String? qualification;
  final String? education;
  final String? experience;
  final String? experienceYears;
  final String? gender;
  final String? dateOfBirth;
  final String? dateJoined;
  final String? profilePicture;
  final bool? isActive;
  final bool? isClassteacher;
  final List<dynamic>? subjects;
  final List<dynamic>? classes;
  final List<dynamic>? classTeacherInfo;
  final int? teacherId;
  final String? educationLevel;
  final String? educationLevelDisplay;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactNo;
  final String? nationality;
  final String? bloodGroup;
  final List<dynamic>? subjectList;

  Teacher({
    this.id,
    this.email,
    this.fullname,
    this.employeeId,
    this.phone,
    this.department,
    this.departmentName,
    this.subject,
    this.qualification,
    this.education,
    this.experience,
    this.experienceYears,
    this.gender,
    this.dateOfBirth,
    this.dateJoined,
    this.profilePicture,
    this.isActive,
    this.isClassteacher,
    this.subjects,
    this.classes,
    this.classTeacherInfo,
    this.teacherId,
    this.educationLevel,
    this.educationLevelDisplay,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactNo,
    this.nationality,
    this.bloodGroup,
    this.subjectList,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] is int ? json['id'] : null,
      email: json['email'] is String ? json['email'] : null,
      fullname: json['fullname'] is String
          ? json['fullname']
          : json['first_name'] is String
          ? json['first_name']
          : json['user_details']?['email']?.split('@')?[0],
      employeeId: json['employee_id'] is String
          ? json['employee_id']
          : json['teacher_id'] is String
          ? json['teacher_id']
          : json['teacher_id']?.toString(),
      phone: json['phone'] is String ? json['phone'] : null,
      department: json['department']?.toString(),
      departmentName: json['department_name'] is String
          ? json['department_name']
          : null,
      subject: json['subject'] is String
          ? json['subject']
          : (json['subject_list'] is List && json['subject_list'].isNotEmpty)
          ? json['subject_list'][0]['subject_name'] is String
                ? json['subject_list'][0]['subject_name']
                : null
          : null,
      qualification: json['qualification'] is String
          ? json['qualification']
          : json['education'] is String
          ? json['education']
          : null,
      education: json['education'] is String ? json['education'] : null,
      experience: json['experience'] is String ? json['experience'] : null,
      experienceYears: json['experience_years'] is String
          ? json['experience_years']
          : json['experience'] is String
          ? json['experience']
          : null,
      gender: json['gender'] is String ? json['gender'] : null,
      dateOfBirth: json['date_of_birth'] is String
          ? json['date_of_birth']
          : null,
      dateJoined: json['date_joined'] is String
          ? json['date_joined']
          : json['joining_date'] is String
          ? json['joining_date']
          : json['user_details']?['created_at'] is String
          ? json['user_details']['created_at']
          : null,
      profilePicture: json['profile_picture'] is String
          ? json['profile_picture']
          : json['profile_image'] is String
          ? json['profile_image']
          : null,
      isActive: json['is_active'] is bool
          ? json['is_active']
          : json['user_details']?['is_active'] is bool
          ? json['user_details']['is_active']
          : null,
      isClassteacher: json['is_classteacher'] is bool
          ? json['is_classteacher']
          : null,
      subjects: json['subjects'] is List ? json['subjects'] : null,
      classes: json['classes'] is List ? json['classes'] : null,
      classTeacherInfo: json['class_teacher_info'] is List
          ? json['class_teacher_info']
          : null,
      teacherId: json['teacher_id'] is int
          ? json['teacher_id']
          : json['id'] is int
          ? json['id']
          : null,
      educationLevel: json['education_level'] is String
          ? json['education_level']
          : null,
      educationLevelDisplay: json['education_level_display'] is String
          ? json['education_level_display']
          : null,
      emergencyContactName: json['emergency_contact_name'] is String
          ? json['emergency_contact_name']
          : null,
      emergencyContactRelationship:
          json['emergency_contact_relationship'] is String
          ? json['emergency_contact_relationship']
          : null,
      emergencyContactNo: json['emergency_contact_no'] is String
          ? json['emergency_contact_no']
          : null,
      nationality: json['nationality'] is String ? json['nationality'] : null,
      bloodGroup: json['blood_group'] is String ? json['blood_group'] : null,
      subjectList: json['subject_list'] is List ? json['subject_list'] : null,
    );
  }
}

class AllTeachers extends StatefulWidget {
  const AllTeachers({super.key});

  @override
  State<AllTeachers> createState() => _AllTeachersState();
}

class _AllTeachersState extends State<AllTeachers>
    with TickerProviderStateMixin {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Teacher> teachers = [];
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> leaves = [];
  List<Map<String, dynamic>> timetable = [];
  Teacher? selectedTeacher;
  bool loading = false;
  String activeTab = "overview";
  bool timetableLoading = false;
  Map<String, dynamic>? selectedSubject;
  List<Map<String, dynamic>> filteredTimetable = [];
  String searchTerm = "";
  String departmentFilter = "all";
  String subjectFilter = "all";
  String educationLevelFilter = "all";
  String subjectEducationLevelFilter = "all";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        activeTab = [
          "overview",
          "subjects",
          "schedule",
          "performance",
        ][_tabController.index];
      });
    });
    fetchTeachers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchTeachers() async {
    setState(() => loading = true);
    try {
      debugPrint('Fetching teachers from: $apiBaseUrl/teachers/');
      final response = await http.get(Uri.parse('$apiBaseUrl/teachers/'));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        debugPrint('Decoded response type: ${decodedBody.runtimeType}');
        debugPrint('Decoded response: $decodedBody');

        if (decodedBody is List) {
          debugPrint('Response is List with length: ${decodedBody.length}');
          final teachersData = decodedBody as List<dynamic>;
          debugPrint('Processing ${teachersData.length} teachers...');

          final teachersList = teachersData.map((e) {
            debugPrint('Processing teacher: $e');
            return Teacher.fromJson(e);
          }).toList();

          debugPrint(
            'Successfully created ${teachersList.length} teacher objects',
          );
          setState(() => teachers = teachersList);
        } else {
          debugPrint(
            'Response is not a List, it is: ${decodedBody.runtimeType}',
          );
          debugPrint('Response content: $decodedBody');
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching teachers: $error');
      debugPrint('Error stack: ${error.toString()}');
    } finally {
      setState(() => loading = false);
    }
  }

  void goBack() {
    setState(() {
      selectedTeacher = null;
      activeTab = "overview";
      _tabController.index = 0;
    });
  }

  List<String> get uniqueDepartments {
    return teachers
        .map((teacher) => teacher.departmentName)
        .where((dept) => dept != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  List<String> get uniqueSubjects {
    return teachers
        .map((teacher) => teacher.subject)
        .where((subj) => subj != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  // Helper function to get education level from teacher ID
  String getEducationLevelFromId(String? teacherId) {
    if (teacherId == null || teacherId.isEmpty) return "other";

    final idLower = teacherId.toLowerCase();

    if (idLower.startsWith('n')) return "nursery";
    if (idLower.startsWith('p')) return "primary";
    if (idLower.startsWith('h')) return "highschool";
    if (idLower.startsWith('l')) return "college";
    if (idLower.startsWith('s')) return "school";

    return "other";
  }

  // Helper function to get education level display name
  String getEducationLevelDisplayName(String level) {
    switch (level) {
      case "nursery":
        return "Nursery School";
      case "primary":
        return "Primary School";
      case "highschool":
        return "High School";
      case "college":
        return "College";
      case "school":
        return "School";
      default:
        return "Other";
    }
  }

  List<Teacher> get filteredTeachers {
    return teachers.where((teacher) {
      final matchesSearch =
          teacher.fullname?.toLowerCase().contains(searchTerm.toLowerCase()) ==
              true ||
          teacher.email?.toLowerCase().contains(searchTerm.toLowerCase()) ==
              true ||
          teacher.employeeId?.toLowerCase().contains(
                searchTerm.toLowerCase(),
              ) ==
              true;

      final matchesDepartment =
          departmentFilter == "all" ||
          teacher.departmentName == departmentFilter;
      final matchesSubject =
          subjectFilter == "all" || teacher.subject == subjectFilter;

      // Filter by education level based on teacher ID prefix
      final teacherEducationLevel = getEducationLevelFromId(
        teacher.employeeId ?? teacher.teacherId?.toString(),
      );
      final matchesEducationLevel =
          educationLevelFilter == "all" ||
          teacherEducationLevel == educationLevelFilter;

      return matchesSearch &&
          matchesDepartment &&
          matchesSubject &&
          matchesEducationLevel;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
        child: selectedTeacher == null
            ? _buildTeachersGrid()
            : _buildTeacherDetails(),
      ),
    );
  }

  Widget _buildTeachersGrid() {
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
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
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
                    'Teacher Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Comprehensive teacher monitoring and management system',
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
                  const Icon(Icons.search, color: Color(0xFF3B82F6)),
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
                      value: departmentFilter,
                      onChanged: (value) {
                        setState(() {
                          departmentFilter = value!;
                          subjectFilter = "all";
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: "all",
                          child: Text("All Departments"),
                        ),
                        ...uniqueDepartments.map(
                          (dept) =>
                              DropdownMenuItem(value: dept, child: Text(dept)),
                        ),
                      ],
                    ),
                  ),
                  if (departmentFilter != "all") ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: subjectFilter,
                        onChanged: (value) =>
                            setState(() => subjectFilter = value!),
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: "all",
                            child: Text("All Subjects"),
                          ),
                          ...uniqueSubjects.map(
                            (subj) => DropdownMenuItem(
                              value: subj,
                              child: Text(subj),
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
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filteredTeachers.length} teachers',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
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
                      value: educationLevelFilter,
                      onChanged: (value) =>
                          setState(() => educationLevelFilter = value!),
                      decoration: const InputDecoration(
                        labelText: 'Education Level',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "all",
                          child: Text("All Education Levels"),
                        ),
                        DropdownMenuItem(
                          value: "school",
                          child: Text("School"),
                        ),
                        DropdownMenuItem(
                          value: "college",
                          child: Text("College"),
                        ),
                        DropdownMenuItem(
                          value: "nursery",
                          child: Text("Nursery School"),
                        ),
                        DropdownMenuItem(
                          value: "primary",
                          child: Text("Primary School"),
                        ),
                        DropdownMenuItem(
                          value: "highschool",
                          child: Text("High School"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Teachers Grid
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filteredTeachers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        searchTerm.isEmpty && departmentFilter == "all"
                            ? 'No teachers found'
                            : 'No teachers match your filters',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          searchTerm = "";
                          departmentFilter = "all";
                          subjectFilter = "all";
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
                  itemCount: filteredTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = filteredTeachers[index];

                    final educationLevel = getEducationLevelFromId(
                      teacher.employeeId ?? teacher.teacherId?.toString(),
                    );
                    final educationLevelDisplay = getEducationLevelDisplayName(
                      educationLevel,
                    );

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => selectedTeacher = teacher),
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage:
                                        teacher.profilePicture != null
                                        ? NetworkImage(teacher.profilePicture!)
                                        : null,
                                    child: teacher.profilePicture == null
                                        ? Text(
                                            teacher.fullname?.isNotEmpty == true
                                                ? teacher.fullname![0]
                                                      .toUpperCase()
                                                : 'T',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    teacher.fullname ?? 'Unknown Teacher',
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
                                    teacher.subject ?? 'Subject not specified',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    teacher.email ?? 'No email',
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
                                          'ID: ${teacher.employeeId ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.blue,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (teacher.department != null) ...[
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            teacher.department!,
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
                                  const SizedBox(height: 8),
                                  // Class Teacher Badge
                                  if (teacher.isClassteacher == true) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.purple[200]!,
                                        ),
                                      ),
                                      child: const Text(
                                        'Class Teacher',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Education Level Badge (top right)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEducationLevelBadgeColor(
                                    educationLevel,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getEducationLevelBorderColor(
                                      educationLevel,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  educationLevelDisplay,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
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
    );
  }

  Widget _buildTeacherDetails() {
    final teacher = selectedTeacher!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with Back Button
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
                  'Back to Teachers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Teacher Header Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1D4ED8),
                  Color(0xFF1E3A8A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: teacher.profilePicture != null
                      ? NetworkImage(teacher.profilePicture!)
                      : null,
                  child: teacher.profilePicture == null
                      ? Text(
                          teacher.fullname?.isNotEmpty == true
                              ? teacher.fullname![0].toUpperCase()
                              : 'T',
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
                        teacher.fullname ?? 'Unknown Teacher',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        teacher.subject ?? 'Subject not specified',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFDBEAFE),
                        ),
                      ),
                      if (teacher.department != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Department: ${teacher.department}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFDBEAFE),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip('ID', teacher.employeeId ?? 'N/A'),
                          _buildInfoChip('Email', teacher.email ?? 'N/A'),
                          _buildInfoChip('Phone', teacher.phone ?? 'N/A'),
                          _buildInfoChip('Gender', teacher.gender ?? 'N/A'),
                          _buildInfoChip('DOB', teacher.dateOfBirth ?? 'N/A'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tabs Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Overview'),
                        Tab(text: 'Subjects'),
                        Tab(text: 'Schedule'),
                        Tab(text: 'Performance'),
                      ],
                    ),
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        children: [
                          _buildOverviewTab(),
                          _buildSubjectsTab(),
                          _buildScheduleTab(),
                          _buildPerformanceTab(),
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

  Widget _buildOverviewTab() {
    final teacher = selectedTeacher!;
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
                  _buildInfoRow('Full Name', teacher.fullname ?? 'N/A'),
                  _buildInfoRow('Employee ID', teacher.employeeId ?? 'N/A'),
                  _buildInfoRow('Subject', teacher.subject ?? 'N/A'),
                  _buildInfoRow('Department', teacher.department ?? 'N/A'),
                  _buildInfoRow('Gender', teacher.gender ?? 'N/A'),
                  _buildInfoRow('Date of Birth', teacher.dateOfBirth ?? 'N/A'),
                  _buildInfoRow(
                    'Qualification',
                    teacher.qualification ?? 'N/A',
                  ),
                  _buildInfoRow('Experience', teacher.experience ?? 'N/A'),
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
                    teacher.email ?? 'N/A',
                  ),
                  _buildContactRow(
                    Icons.phone,
                    'Phone',
                    teacher.phone ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Primary Subject',
                    selectedTeacher?.subject ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Department',
                    selectedTeacher?.department ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Qualification',
                    selectedTeacher?.qualification ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Experience',
                    selectedTeacher?.experience ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teaching Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Schedule information will be displayed here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Performance data will be displayed here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Color _getEducationLevelBadgeColor(String level) {
    switch (level) {
      case "nursery":
        return const Color(0xFFFCE7F3); // Pink background
      case "primary":
        return const Color(0xFFDCFCE7); // Green background
      case "highschool":
        return const Color(0xFFDBEAFE); // Blue background
      case "college":
        return const Color(0xFFF3E8FF); // Purple background
      case "school":
        return const Color(0xFFFEF3C7); // Orange background
      default:
        return const Color(0xFFF3F4F6); // Gray background
    }
  }

  Color _getEducationLevelBorderColor(String level) {
    switch (level) {
      case "nursery":
        return const Color(0xFFF9A8D4); // Pink border
      case "primary":
        return const Color(0xFF86EFAC); // Green border
      case "highschool":
        return const Color(0xFF93C5FD); // Blue border
      case "college":
        return const Color(0xFFD8B4FE); // Purple border
      case "school":
        return const Color(0xFFFCD34D); // Orange border
      default:
        return const Color(0xFFD1D5DB); // Gray border
    }
  }
}
