import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Grade {
  final int id;
  final String? studentName;
  final String? subjectName;
  final String? teacherName;
  final double? percentage;
  final String? marksObtained;
  final String? totalMarks;
  final String? examType;
  final String? examDate;
  final String? remarks;
  final String? student;

  Grade({
    required this.id,
    this.studentName,
    this.subjectName,
    this.teacherName,
    this.percentage,
    this.marksObtained,
    this.totalMarks,
    this.examType,
    this.examDate,
    this.remarks,
    this.student,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? 0,
      studentName: json['student_name'],
      subjectName: json['subject_name'],
      teacherName: json['teacher_name'],
      percentage: json['percentage'] != null
          ? (json['percentage'] as num).toDouble()
          : null,
      marksObtained: json['marks_obtained'],
      totalMarks: json['total_marks'],
      examType: json['exam_type'],
      examDate: json['exam_date'],
      remarks: json['remarks'],
      student: json['student'],
    );
  }
}

class StudentMarksPage extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const StudentMarksPage({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<StudentMarksPage> createState() => _StudentMarksPageState();
}

class _StudentMarksPageState extends State<StudentMarksPage> {
  List<Grade> grades = [];
  bool loading = true;
  String? error;
  Grade? selectedGrade;
  bool isModalOpen = false;

  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/'; // Actual API base URL

  @override
  void initState() {
    super.initState();
    fetchAndFilterGrades();
  }

  Future<void> fetchAndFilterGrades() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        // Add auth headers if needed
      };

      // First try to get all grades and filter
      try {
        final allGradesRes = await http.get(
          Uri.parse('$apiBase/grades/'),
          headers: headers,
        );

        if (allGradesRes.statusCode == 200) {
          final allData = json.decode(allGradesRes.body);
          final allGradesArray = allData is List ? allData : [allData];

          final matched = allGradesArray
              .where((g) {
                if (g == null) return false;
                final studentField = g['student'];
                if (studentField != null &&
                    studentField.toString().toLowerCase() ==
                        widget.userEmail.toLowerCase()) {
                  return true;
                }
                final jsonStr = json.encode(g).toLowerCase();
                return jsonStr.contains(widget.userEmail.toLowerCase());
              })
              .map((g) => Grade.fromJson(g))
              .toList();

          if (matched.isNotEmpty) {
            setState(() {
              grades = matched;
              loading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Could not fetch all grades: $e');
      }

      // Fallback: get student info and fetch by student ID
      try {
        final studentRes = await http.get(
          Uri.parse(
            '$apiBase/students/?email=${Uri.encodeComponent(widget.userEmail)}',
          ),
          headers: headers,
        );

        if (studentRes.statusCode == 200) {
          final studentData = json.decode(studentRes.body);
          final studentRecord = studentData is List
              ? studentData[0]
              : studentData;

          if (studentRecord != null && studentRecord['student_id'] != null) {
            final studentId = studentRecord['student_id'];

            final gradesRes = await http.get(
              Uri.parse('$apiBase/grades/$studentId/'),
              headers: headers,
            );

            if (gradesRes.statusCode == 200) {
              final gradesData = json.decode(gradesRes.body);
              final normalized = gradesData is List ? gradesData : [gradesData];

              final filtered = normalized
                  .where((g) {
                    final grade = Grade.fromJson(g);
                    return grade.student?.toLowerCase() ==
                            widget.userEmail.toLowerCase() ||
                        json
                            .encode(g)
                            .toLowerCase()
                            .contains(widget.userEmail.toLowerCase());
                  })
                  .map((g) => Grade.fromJson(g))
                  .toList();

              setState(() {
                grades = filtered.isNotEmpty
                    ? filtered
                    : normalized.map((g) => Grade.fromJson(g)).toList();
              });
            }
          } else {
            setState(() {
              error = 'Student record not found.';
            });
          }
        } else {
          setState(() {
            error = 'Failed to fetch student information.';
          });
        }
      } catch (e) {
        setState(() {
          error = 'Failed to fetch grades for this student.';
        });
        debugPrint('Error fetching student grades: $e');
      }
    } catch (e) {
      setState(() {
        error = 'Unexpected error while fetching grades.';
      });
      debugPrint('Unexpected error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void handleCardClick(Grade grade) {
    setState(() {
      selectedGrade = grade;
      isModalOpen = true;
    });
    _showGradeDetails(grade);
  }

  void closeModal() {
    setState(() {
      isModalOpen = false;
      selectedGrade = null;
    });
  }

  Color getProgressColor(double? percentage) {
    final marks = percentage ?? 0;
    if (marks >= 80) return Colors.green;
    if (marks >= 60) return Colors.blue;
    if (marks >= 40) return Colors.yellow;
    return Colors.red;
  }

  Color getGradeColor(double? percentage) {
    final marks = percentage ?? 0;
    if (marks >= 80) return Colors.green;
    if (marks >= 60) return Colors.blue;
    if (marks >= 40) return Colors.yellow;
    return Colors.red;
  }

  String getGradeLetter(double? percentage) {
    final marks = percentage ?? 0;
    if (marks >= 90) return "A+";
    if (marks >= 80) return "A";
    if (marks >= 70) return "B";
    if (marks >= 60) return "C";
    if (marks >= 50) return "D";
    if (marks >= 40) return "E";
    return "F";
  }

  String formatExamDate(String? dateString) {
    if (dateString == null) return "—";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Fixed Header
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
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
                    'Academic Performance',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),

              // Content Area
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading your academic performance...',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we fetch your grades',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: fetchAndFilterGrades,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (grades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.grey, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'No grades found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We could not find any grade records for your account.',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final averagePercentage = grades.isNotEmpty
        ? grades.map((g) => g.percentage ?? 0).reduce((a, b) => a + b) /
              grades.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // Stats Summary
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: _buildStatCard(
                    '${grades.length}',
                    'Total Records',
                    Colors.blue,
                    Icons.analytics,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: _buildStatCard(
                    '${averagePercentage.toStringAsFixed(1)}%',
                    'Average %',
                    Colors.green,
                    Icons.star,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: _buildStatCard(
                    grades.isNotEmpty && grades[0].examDate != null
                        ? formatExamDate(grades[0].examDate)
                        : "—",
                    'Last Exam',
                    Colors.purple,
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: _buildStatCard(
                    getGradeLetter(averagePercentage),
                    'Overall Grade',
                    Colors.amber,
                    Icons.grade,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Grades List
          ...grades.map(
            (grade) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGradeCard(grade),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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

  Widget _buildGradeCard(Grade grade) {
    return GestureDetector(
      onTap: () => handleCardClick(grade),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade.subjectName ?? 'Unknown Subject',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${grade.teacherName ?? 'No Teacher'} • ${grade.examType ?? 'Exam'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getGradeColor(
                      grade.percentage,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getGradeColor(
                        grade.percentage,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    getGradeLetter(grade.percentage),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: getGradeColor(grade.percentage),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Percentage Circle
            Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: (grade.percentage ?? 0) / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getProgressColor(grade.percentage),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${grade.percentage?.toStringAsFixed(0) ?? '—'}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Marks
            Center(
              child: Column(
                children: [
                  Text(
                    '${grade.marksObtained ?? '0'}/${grade.totalMarks ?? '0'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Marks Obtained',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Performance',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${grade.percentage?.toStringAsFixed(0) ?? 0}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (grade.percentage ?? 0) / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    getProgressColor(grade.percentage),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📅 ${formatExamDate(grade.examDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'View Details →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeDetails(Grade grade) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                grade.subjectName ?? 'Unknown Subject',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${grade.teacherName ?? 'No Teacher'} • ${grade.examType ?? 'Exam'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
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
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grade Overview
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${grade.percentage?.toStringAsFixed(0) ?? '—'}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Percentage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  getGradeLetter(grade.percentage),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Grade',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Detailed Information
                    _buildDetailRow(
                      'Marks Obtained',
                      '${grade.marksObtained ?? '0'}/${grade.totalMarks ?? '0'}',
                    ),
                    _buildDetailRow(
                      'Exam Date',
                      formatExamDate(grade.examDate),
                    ),
                    _buildDetailRow('Exam Type', grade.examType ?? '—'),
                    _buildDetailRow('Teacher', grade.teacherName ?? '—'),

                    const SizedBox(height: 16),

                    // Remarks
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        grade.remarks ??
                            'No remarks provided for this assessment.',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Performance Indicator
                    const Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (grade.percentage ?? 0) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getProgressColor(grade.percentage),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Needs Improvement',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          'Excellent',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(StudentMarksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedGrade != null && isModalOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGradeDetails(selectedGrade!);
      });
    }
  }
}
