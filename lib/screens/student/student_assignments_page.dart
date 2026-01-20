import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subjectName: json['subject_name'] ?? '',
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? '',
      section: json['section'] ?? '',
      dueDate: json['due_date'] ?? '',
      attachment: json['attachment'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Student {
  final int id;
  final String email;
  final String fullname;
  final int classId;
  final String className;
  final String section;

  Student({
    required this.id,
    required this.email,
    required this.fullname,
    required this.classId,
    required this.className,
    required this.section,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullname: json['fullname'] ?? '',
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? '',
      section: json['section'] ?? '',
    );
  }
}

class SubmittedAssignment {
  final int id;
  final int assignment;
  final String student;
  final String submissionFile;
  final String feedback;
  final bool isLate;
  final String submissionDate;

  SubmittedAssignment({
    required this.id,
    required this.assignment,
    required this.student,
    required this.submissionFile,
    required this.feedback,
    required this.isLate,
    required this.submissionDate,
  });

  factory SubmittedAssignment.fromJson(Map<String, dynamic> json) {
    return SubmittedAssignment(
      id: json['id'] ?? 0,
      assignment: json['assignment'] ?? 0,
      student: json['student'] ?? '',
      submissionFile: json['submission_file'] ?? '',
      feedback: json['feedback'] ?? '',
      isLate: json['is_late'] ?? false,
      submissionDate: json['submission_date'] ?? '',
    );
  }
}

class StudentAssignmentsPage extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const StudentAssignmentsPage({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/';

  Student? student;
  List<Assignment> assignments = [];
  List<SubmittedAssignment> submittedAssignments = [];
  bool loading = true;
  String searchTerm = "";
  String selectedTab = "all"; // all, pending, overdue, submitted
  String sortBy = "due_date"; // due_date, title, subject, created_at

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final studentData = await fetchStudent();
      student = studentData;

      final results = await Future.wait([
        fetchAssignments(studentData.classId),
        fetchSubmittedAssignments(studentData.email),
      ]);

      setState(() {
        assignments = results[0] as List<Assignment>;
        submittedAssignments = results[1] as List<SubmittedAssignment>;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _showSnackBar('Failed to load assignments', isError: true);
    }
  }

  Future<Student> fetchStudent() async {
    final response = await http.get(
      Uri.parse(
        '$apiBase/students/?email=${Uri.encodeComponent(widget.userEmail)}',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final studentData = data is List ? data[0] : data;
      return Student.fromJson(studentData);
    } else {
      throw Exception('Failed to fetch student data');
    }
  }

  Future<List<Assignment>> fetchAssignments(int classId) async {
    final response = await http.get(
      Uri.parse('$apiBase/assignments/?class_id=$classId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((item) => Assignment.fromJson(item)).toList();
      } else {
        return [Assignment.fromJson(data)];
      }
    } else {
      return [];
    }
  }

  Future<List<SubmittedAssignment>> fetchSubmittedAssignments(
    String email,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/submitted_assignments/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final submissions = data is List
            ? data.map((item) => SubmittedAssignment.fromJson(item)).toList()
            : [SubmittedAssignment.fromJson(data)];

        return submissions
            .where((sub) => sub.student.toLowerCase() == email.toLowerCase())
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching submitted assignments: $e');
    }
    return [];
  }

  bool isSubmitted(int assignmentId) {
    return submittedAssignments.any((sub) => sub.assignment == assignmentId);
  }

  List<Assignment> getFilteredAssignments() {
    final filtered = assignments.where((assignment) {
      final matchesSearch =
          assignment.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          assignment.description.toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          assignment.subjectName.toLowerCase().contains(
            searchTerm.toLowerCase(),
          );

      final submitted = isSubmitted(assignment.id);
      final dueDate = DateTime.parse(assignment.dueDate);
      final now = DateTime.now();

      if (!matchesSearch) return false;

      switch (selectedTab) {
        case "pending":
          return !submitted && dueDate.isAfter(now);
        case "overdue":
          return !submitted && dueDate.isBefore(now);
        case "submitted":
          return submitted;
        default:
          return true;
      }
    }).toList();

    // Sort assignments
    filtered.sort((a, b) {
      switch (sortBy) {
        case "due_date":
          return DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate));
        case "title":
          return a.title.compareTo(b.title);
        case "subject":
          return a.subjectName.compareTo(b.subjectName);
        case "created_at":
          return DateTime.parse(
            b.createdAt,
          ).compareTo(DateTime.parse(a.createdAt));
        default:
          return 0;
      }
    });

    return filtered;
  }

  Map<String, int> getStats() {
    return {
      "total": assignments.length,
      "pending": assignments
          .where(
            (a) =>
                !isSubmitted(a.id) &&
                DateTime.parse(a.dueDate).isAfter(DateTime.now()),
          )
          .length,
      "overdue": assignments
          .where(
            (a) =>
                !isSubmitted(a.id) &&
                DateTime.parse(a.dueDate).isBefore(DateTime.now()),
          )
          .length,
      "submitted": assignments.where((a) => isSubmitted(a.id)).length,
    };
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your assignments...',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final filteredAssignments = getFilteredAssignments();
    final stats = getStats();

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'My Assignments',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),

              // Student Info
              if (student != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${student!.fullname} • ${student!.className} - ${student!.section}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Stats Cards
              Container(
                height: 100,
                margin: const EdgeInsets.all(16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatCard('${stats["total"]}', 'Total', Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '${stats["pending"]}',
                      'Pending',
                      Colors.yellow,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '${stats["overdue"]}',
                      'Overdue',
                      Colors.red,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '${stats["submitted"]}',
                      'Submitted',
                      Colors.green,
                    ),
                  ],
                ),
              ),

              // Search and Filters
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search assignments...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) => setState(() => searchTerm = value),
                    ),
                    const SizedBox(height: 12),

                    // Tabs
                    Row(
                      children: [
                        _buildTabButton('All', 'all', stats["total"]!),
                        const SizedBox(width: 8),
                        _buildTabButton(
                          'Pending',
                          'pending',
                          stats["pending"]!,
                        ),
                        const SizedBox(width: 8),
                        _buildTabButton(
                          'Overdue',
                          'overdue',
                          stats["overdue"]!,
                        ),
                        const SizedBox(width: 8),
                        _buildTabButton(
                          'Submitted',
                          'submitted',
                          stats["submitted"]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Assignments List
              Expanded(
                child: filteredAssignments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchTerm.isNotEmpty || selectedTab != 'all'
                                    ? 'No matching assignments'
                                    : 'No assignments yet',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchTerm.isNotEmpty || selectedTab != 'all'
                                    ? 'Try adjusting your search or filters'
                                    : 'Assignments will appear here when created by teachers',
                                style: const TextStyle(color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAssignments.length,
                        itemBuilder: (context, index) {
                          final assignment = filteredAssignments[index];
                          final submitted = isSubmitted(assignment.id);
                          final submittedData = submittedAssignments.firstWhere(
                            (sub) => sub.assignment == assignment.id,
                            orElse: () => SubmittedAssignment(
                              id: 0,
                              assignment: 0,
                              student: '',
                              submissionFile: '',
                              feedback: '',
                              isLate: false,
                              submissionDate: '',
                            ),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AssignmentCard(
                              assignment: assignment,
                              isSubmitted: submitted,
                              submittedData: submittedData,
                              onSubmit: () =>
                                  _showSubmitModal(context, assignment),
                              onViewSubmission:
                                  submittedData.submissionFile.isNotEmpty
                                  ? () =>
                                        _launchURL(submittedData.submissionFile)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tabValue, int count) {
    final isSelected = selectedTab == tabValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = tabValue),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitModal(BuildContext context, Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => SubmitAssignmentModal(
        assignment: assignment,
        student: student!,
        onSuccess: () {
          loadData();
          _showSnackBar('Assignment submitted successfully!');
        },
      ),
    );
  }

  void _launchURL(String url) {
    // For now, just show a snackbar. In a real app, you'd use url_launcher
    _showSnackBar('Opening submission file...');
  }
}

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final bool isSubmitted;
  final SubmittedAssignment submittedData;
  final VoidCallback onSubmit;
  final VoidCallback? onViewSubmission;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.isSubmitted,
    required this.submittedData,
    required this.onSubmit,
    this.onViewSubmission,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();
    final dueDate = DateTime.parse(assignment.dueDate);
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: status.color.withOpacity(0.3)),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: status.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Subject and Class
          Text(
            '${assignment.subjectName} • ${assignment.className} - ${assignment.section}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            assignment.description,
            style: const TextStyle(color: Colors.black87),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Due Date
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              if (onViewSubmission != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewSubmission,
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Submission'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              if (onViewSubmission != null) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSubmitted ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubmitted ? Colors.green : Colors.blue,
                    disabledBackgroundColor: Colors.green,
                  ),
                  child: Text(isSubmitted ? 'Submitted' : 'Submit Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _Status _getStatus() {
    if (isSubmitted) {
      return _Status('Submitted', Colors.green);
    }

    final dueDate = DateTime.parse(assignment.dueDate);
    final now = DateTime.now();
    final daysDiff = dueDate.difference(now).inDays;

    if (dueDate.isBefore(now)) {
      return _Status('Overdue', Colors.red);
    } else if (daysDiff <= 1) {
      return _Status('Due Today', Colors.orange);
    } else if (daysDiff <= 2) {
      return _Status('Due Tomorrow', Colors.yellow.shade700);
    } else if (daysDiff <= 7) {
      return _Status('This Week', Colors.blue);
    } else {
      return _Status('Upcoming', Colors.grey);
    }
  }
}

class _Status {
  final String label;
  final Color color;

  _Status(this.label, this.color);
}

class SubmitAssignmentModal extends StatefulWidget {
  final Assignment assignment;
  final Student student;
  final VoidCallback onSuccess;

  const SubmitAssignmentModal({
    super.key,
    required this.assignment,
    required this.student,
    required this.onSuccess,
  });

  @override
  State<SubmitAssignmentModal> createState() => _SubmitAssignmentModalState();
}

class _SubmitAssignmentModalState extends State<SubmitAssignmentModal> {
  File? selectedFile;
  String comment = "";
  bool isUploading = false;
  String error = "";

  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/';

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      setState(() {
        error = "Failed to pick file";
      });
    }
  }

  Future<void> submitAssignment() async {
    if (selectedFile == null) {
      setState(() => error = "Please select a file to upload");
      return;
    }

    setState(() {
      isUploading = true;
      error = "";
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBase/submitted_assignments/'),
      );

      request.fields['student'] = widget.student.email;
      request.fields['assignment'] = widget.assignment.id.toString();
      if (comment.isNotEmpty) {
        request.fields['feedback'] = comment;
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        widget.onSuccess();
        Navigator.of(context).pop();
      } else {
        setState(
          () => error = "Failed to submit assignment. Please try again.",
        );
      }
    } catch (e) {
      setState(() => error = "Network error. Please check your connection.");
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueDate = DateTime.parse(widget.assignment.dueDate);
    final daysLeft = dueDate.difference(DateTime.now()).inDays;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submit Assignment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.assignment.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Due Date Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Due: ${DateFormat('EEEE, MMMM d, yyyy').format(dueDate)} (${daysLeft > 0 ? '$daysLeft days left' : 'Overdue'})',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // File Selection
                  const Text(
                    'Upload Your Work',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedFile != null
                                ? Icons.file_present
                                : Icons.file_upload,
                            color: selectedFile != null
                                ? Colors.green
                                : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedFile != null
                                  ? selectedFile!.path.split('/').last
                                  : 'Tap to select file (PDF, DOC, DOCX, PNG, JPG, ZIP)',
                              style: TextStyle(
                                color: selectedFile != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Comment
                  const Text(
                    'Feedback (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Add your feedback or notes for your teacher...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) => setState(() => comment = value),
                  ),

                  // Error Message
                  if (error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
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

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isUploading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (isUploading || selectedFile == null)
                              ? null
                              : submitAssignment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green,
                          ),
                          child: isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Submit Assignment'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
