import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';

class Student {
  final int id;
  final String? email;
  final int? classId;

  Student({required this.id, this.email, this.classId});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      email: json['email'],
      classId: json['class_id'],
    );
  }
}

class ExamDetails {
  final int id;
  final String? title;
  final int? classId;

  ExamDetails({required this.id, this.title, this.classId});

  factory ExamDetails.fromJson(Map<String, dynamic> json) {
    return ExamDetails(
      id: json['id'] ?? 0,
      title: json['title'],
      classId: json['class_id'],
    );
  }
}

class MCQRow {
  final int id;
  final String question;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final int? correctOption;
  final int? studentAnswer;
  final bool? result;
  final ExamDetails? examDetails;
  final String? studentEmail;

  MCQRow({
    required this.id,
    required this.question,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    this.correctOption,
    this.studentAnswer,
    this.result,
    this.examDetails,
    this.studentEmail,
  });

  factory MCQRow.fromJson(Map<String, dynamic> json) {
    return MCQRow(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      option1: json['option_1'] ?? '',
      option2: json['option_2'] ?? '',
      option3: json['option_3'] ?? '',
      option4: json['option_4'] ?? '',
      correctOption: json['correct_option'],
      studentAnswer: json['student_answer'],
      result: json['result'],
      examDetails: json['exam_details'] != null
          ? ExamDetails.fromJson(json['exam_details'])
          : null,
      studentEmail: json['student_email'],
    );
  }
}

class StudentOnlineTestPage extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const StudentOnlineTestPage({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<StudentOnlineTestPage> createState() => _StudentOnlineTestPageState();
}

class _StudentOnlineTestPageState extends State<StudentOnlineTestPage> {
  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/';

  String? loggedEmail;
  List<Student> students = [];
  int? classId;
  List<Map<String, dynamic>> availableExams = [];
  int? selectedExamId;
  List<MCQRow> examRowsRaw = [];
  List<MCQRow> uniqueQuestions = [];
  Map<int, int> answers = {};
  Set<int> serverAnsweredQuestionIds = Set();
  bool loading = false;
  bool fetchingExams = false;
  bool submitting = false;
  String? error;
  bool showAnswers = false;
  bool hasAlreadyTakenTest = false;

  @override
  void initState() {
    super.initState();
    readEmailFromLocalStorage();
  }

  void readEmailFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Try different email keys
    String? email;
    final emailKeys = ['student_email', 'studentEmail', 'userEmail', 'email'];

    for (final key in emailKeys) {
      email = prefs.getString(key);
      if (email != null && email.isNotEmpty) {
        break;
      }
    }

    if (email != null) {
      setState(() => loggedEmail = email);
    }
  }

  Future<void> fetchStudents() async {
    if (loggedEmail == null) return;

    setState(() => error = null);

    try {
      final response = await http.get(Uri.parse('$apiBase/students/'));

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Students fetch failed (${response.statusCode})');
      }

      final data = json.decode(response.body);
      final studentsData = data is List ? data : [];

      setState(() {
        students = studentsData.map((s) => Student.fromJson(s)).toList();
      });
    } catch (e) {
      setState(() => error = 'Failed to load students: $e');
    }
  }

  Future<void> resolveClassId() async {
    if (students.isEmpty || loggedEmail == null) return;

    final me = students.firstWhere(
      (s) => s.email?.toLowerCase() == loggedEmail!.toLowerCase(),
      orElse: () => Student(id: 0),
    );

    if (me.id != 0) {
      setState(() => classId = me.classId);
    } else {
      setState(() => error = 'Student record not found in students list.');
    }
  }

  Future<void> fetchAvailableExams() async {
    if (classId == null) return;

    setState(() {
      fetchingExams = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('$apiBase/exams/'));

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Exams fetch failed (${response.statusCode})');
      }

      final data = json.decode(response.body);
      final allExams = data is List ? data : [];

      // Filter exams by classId
      final myExams = allExams
          .where(
            (ex) => (ex['class_id'] != null) && (ex['class_id'] == classId),
          )
          .toList();

      final examsArr = myExams
          .map(
            (ex) => {
              'id': ex['id'] ?? 0,
              'title': ex['title'] ?? 'Exam ${ex['id'] ?? 0}',
            },
          )
          .toList();

      setState(() => availableExams = examsArr);

      // Auto-select logic
      if (examsArr.length == 1) {
        setState(() => selectedExamId = examsArr[0]['id']);
      } else if (examsArr.length > 1) {
        // Select the latest one
        final latest = examsArr.reduce(
          (a, b) => (a['id'] as int) > (b['id'] as int) ? a : b,
        );
        setState(() => selectedExamId = latest['id']);
      }
    } catch (e) {
      setState(() => error = 'Failed to load exams: $e');
    } finally {
      setState(() => fetchingExams = false);
    }
  }

  Future<void> fetchExamDetails() async {
    if (selectedExamId == null) {
      setState(() {
        examRowsRaw = [];
        uniqueQuestions = [];
        answers = {};
        serverAnsweredQuestionIds = Set();
        hasAlreadyTakenTest = false;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBase/get_all_mcq/?exam_id=$selectedExamId'),
      );

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Exam fetch failed (${response.statusCode})');
      }

      final data = json.decode(response.body);
      final rows = data['mcq_answers'] is List ? data['mcq_answers'] : [];

      // Filter by class
      final validRows = rows
          .where(
            (r) =>
                (r['exam_details']?['class_id'] != null) &&
                (r['exam_details']['class_id'] == classId) &&
                (r['exam_details']['id'] == selectedExamId),
          )
          .toList();

      if (validRows.isEmpty) {
        setState(() => error = 'This exam does not belong to your class.');
        return;
      }

      // Deduplicate questions
      final seen = <String>{};
      final unique = <MCQRow>[];

      for (final r in validRows) {
        final question = (r['question'] ?? '').trim();
        if (question.isNotEmpty && !seen.contains(question)) {
          seen.add(question);
          unique.add(MCQRow.fromJson(r));
        }
      }

      // Preload server answers
      final answeredSet = <int>{};
      final preload = <int, int>{};

      if (loggedEmail != null) {
        for (final r in rows) {
          final rEmail = extractEmail(r['student_email']);
          final myEmail = extractEmail(loggedEmail!);

          if (rEmail == myEmail) {
            final rQuestion = (r['question'] ?? '').trim();
            final match = unique.firstWhere(
              (u) => (u.question).trim() == rQuestion,
              orElse: () => MCQRow(
                id: -1,
                question: '',
                option1: '',
                option2: '',
                option3: '',
                option4: '',
              ),
            );

            if (match.id != -1 && r['student_answer'] != null) {
              final ans = r['student_answer'] as int?;
              if (ans != null) {
                preload[match.id] = ans;
                answeredSet.add(match.id);
              }
            }
          }
        }
      }

      final alreadyTaken = preload.isNotEmpty;

      setState(() {
        examRowsRaw = rows.map((r) => MCQRow.fromJson(r)).toList();
        uniqueQuestions = unique;
        answers = preload;
        serverAnsweredQuestionIds = answeredSet;
        hasAlreadyTakenTest = alreadyTaken;
        if (alreadyTaken) showAnswers = true;
      });
    } catch (e) {
      setState(() => error = 'Failed to load exam data: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  String extractEmail(String? email) {
    if (email == null) return '';
    final trimmed = email.trim().toLowerCase();
    final match = RegExp(r'^([^\s(]+)').firstMatch(trimmed);
    return match?.group(1) ?? trimmed;
  }

  void handleOptionSelect(int questionId, int option) {
    if (serverAnsweredQuestionIds.contains(questionId)) return;

    setState(() => answers[questionId] = option);
  }

  Future<void> submitAnswers() async {
    if (hasAlreadyTakenTest) {
      _showSnackBar(
        'You have already taken this exam. You cannot submit again.',
      );
      return;
    }

    if (selectedExamId == null || loggedEmail == null) {
      _showSnackBar('Missing exam or email information');
      return;
    }

    final payloadAnswers = uniqueQuestions
        .map((q) => {'id': q.id, 'student_answer': answers[q.id]})
        .toList();

    final total = payloadAnswers.length;
    final answeredCount = payloadAnswers
        .where((a) => a['student_answer'] != null)
        .length;

    if (answeredCount < total) {
      final proceed = await _showConfirmDialog(
        'Incomplete Answers',
        'You answered ${answeredCount}/${total} questions. Submit anyway?',
      );
      if (!proceed) return;
    }

    setState(() {
      submitting = true;
      error = null;
    });

    try {
      final payload = {
        'exam_id': selectedExamId,
        'student_email': loggedEmail,
        'answers': payloadAnswers,
      };

      final response = await http.patch(
        Uri.parse('$apiBase/submit_multiple_mcq/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      final responseData = json.decode(response.body);

      if (!response.statusCode.toString().startsWith('2')) {
        final errorMsg =
            responseData['error'] ??
            responseData['message'] ??
            'Status ${response.statusCode}';

        if (errorMsg.toString().contains('already') ||
            errorMsg.toString().contains('duplicate')) {
          setState(() => hasAlreadyTakenTest = true);
          _showSnackBar('You have already completed this exam.');
          await refreshExam();
          return;
        }

        setState(() => error = 'Submit failed: $errorMsg');
        _showSnackBar('Submit failed: $errorMsg');
      } else {
        _showSnackBar('Submitted successfully!');
        setState(() {
          showAnswers = true;
          hasAlreadyTakenTest = true;
        });
        await refreshExam();
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('duplicate') ||
          errorMessage.contains('already')) {
        setState(() => hasAlreadyTakenTest = true);
        _showSnackBar('You have already taken this exam.');
      } else {
        setState(() => error = 'Submit failed: $errorMessage');
        _showSnackBar('Submit failed — check connection');
      }
    } finally {
      setState(() => submitting = false);
    }
  }

  Future<void> refreshExam() async {
    final currentExamId = selectedExamId;
    setState(() => selectedExamId = null);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => selectedExamId = currentExamId);
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Submit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loggedEmail != null && students.isEmpty) {
      fetchStudents();
    }
  }

  @override
  void didUpdateWidget(covariant StudentOnlineTestPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (loggedEmail != null && students.isNotEmpty && classId == null) {
      resolveClassId();
    }
    if (classId != null && availableExams.isEmpty && !fetchingExams) {
      fetchAvailableExams();
    }
    if (selectedExamId != null && uniqueQuestions.isEmpty && !loading) {
      fetchExamDetails();
    }
  }

  int get answeredQuestions => answers.length;
  int get totalQuestions => uniqueQuestions.length;
  double get progressPercentage =>
      totalQuestions > 0 ? (answeredQuestions / totalQuestions) * 100 : 0;

  int get correctAnswers {
    return uniqueQuestions.where((q) {
      final serverRow = examRowsRaw.firstWhere(
        (r) {
          final rEmail = extractEmail(r.studentEmail);
          final myEmail = extractEmail(loggedEmail ?? '');
          return r.question.trim() == q.question.trim() &&
              myEmail.isNotEmpty &&
              rEmail == myEmail;
        },
        orElse: () => MCQRow(
          id: -1,
          question: '',
          option1: '',
          option2: '',
          option3: '',
          option4: '',
        ),
      );
      return serverRow.result == true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.indigo.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.quiz, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Online Examination Platform',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete your assessments with confidence',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // User Info Bar
                if (loggedEmail != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loggedEmail!.split('@')[0],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Student',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Class #${classId ?? '—'}',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Stats Bar
                if (uniqueQuestions.isNotEmpty) ...[
                  // First Row: Total Questions and Answered
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedStatCard(
                            '$totalQuestions',
                            'Total Questions',
                            Icons.quiz,
                            Colors.blue,
                            LinearGradient(
                              colors: [
                                Colors.blue.shade500,
                                Colors.blue.shade700,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildEnhancedStatCard(
                            '$answeredQuestions',
                            'Answered',
                            Icons.check_circle,
                            Colors.green,
                            LinearGradient(
                              colors: [
                                Colors.green.shade500,
                                Colors.green.shade700,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Second Row: Progress and Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCircularProgressCard(
                            progressPercentage / 100,
                            '${(progressPercentage).round()}%',
                            'Progress',
                            Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildEnhancedStatCard(
                            '$correctAnswers/$totalQuestions',
                            'Score',
                            Icons.emoji_events,
                            Colors.purple,
                            LinearGradient(
                              colors: [
                                Colors.purple.shade500,
                                Colors.purple.shade700,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Exam Selection Card
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Select Exam',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (fetchingExams)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (availableExams.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Exams Available',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'There are currently no exams available for your class.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Class ID: ${classId ?? "Unknown"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    availableExams.clear();
                                    fetchingExams = true;
                                  });
                                  fetchAvailableExams();
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh Exams'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: BorderSide(color: Colors.blue.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: selectedExamId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Select an exam'),
                            ),
                            ...availableExams.map(
                              (exam) => DropdownMenuItem<int>(
                                value: exam['id'],
                                child: Text(
                                  '${exam['title']} (ID: ${exam['id']})',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => selectedExamId = value);
                          },
                        ),

                      // Progress Section
                      if (uniqueQuestions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Completion',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressPercentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Answered: $answeredQuestions',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Remaining: ${totalQuestions - answeredQuestions}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Controls Card
                if (uniqueQuestions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Exam Controls',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                submitting ||
                                    hasAlreadyTakenTest ||
                                    serverAnsweredQuestionIds.length ==
                                        totalQuestions
                                ? null
                                : submitAnswers,
                            icon: submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : hasAlreadyTakenTest ||
                                      serverAnsweredQuestionIds.length ==
                                          totalQuestions
                                ? const Icon(Icons.check_circle)
                                : const Icon(Icons.send),
                            label: Text(
                              submitting
                                  ? 'Submitting...'
                                  : hasAlreadyTakenTest ||
                                        serverAnsweredQuestionIds.length ==
                                            totalQuestions
                                  ? 'Already Submitted'
                                  : 'Submit Exam',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  hasAlreadyTakenTest ||
                                      serverAnsweredQuestionIds.length ==
                                          totalQuestions
                                  ? Colors.green
                                  : Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: refreshExam,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Exam'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Content Area
                Column(
                  children: [
                    // Loading State
                    if (loading)
                      Container(
                        padding: const EdgeInsets.all(48),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading Exam...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    // No Exam Selected
                    else if (selectedExamId == null)
                      Container(
                        padding: const EdgeInsets.all(48),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.quiz, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No Exam Selected',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please select an exam from the sidebar to begin',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    // No Questions
                    else if (uniqueQuestions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.warning, size: 48, color: Colors.orange),
                            SizedBox(height: 16),
                            Text(
                              'No Questions Available',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'This exam does not contain any questions yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    // Questions
                    else ...[
                      // Exam Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade900,
                              Colors.grey.shade800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        uniqueQuestions[0].examDetails?.title ??
                                            'Exam $selectedExamId',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Exam ID: $selectedExamId • Questions: $totalQuestions • Status: ${hasAlreadyTakenTest || serverAnsweredQuestionIds.length == totalQuestions ? 'Submitted' : 'In Progress'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
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
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        hasAlreadyTakenTest ||
                                                serverAnsweredQuestionIds
                                                        .length ==
                                                    totalQuestions
                                            ? Icons.check_circle
                                            : Icons.access_time,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasAlreadyTakenTest ||
                                                serverAnsweredQuestionIds
                                                        .length ==
                                                    totalQuestions
                                            ? 'Completed'
                                            : 'Active',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
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

                      // Error Alert
                      if (error != null && !loading)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Error Loading Content',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      size: 14,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Try refreshing the page or contact support if the issue persists',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Questions List
                      ...uniqueQuestions.map((q) => _buildQuestionCard(q)),
                    ],

                    // Score Summary
                    if (hasAlreadyTakenTest)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade50,
                              Colors.indigo.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade500,
                                        Colors.indigo.shade500,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Your Results',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildResultCard(
                                  '$totalQuestions',
                                  'Total Questions',
                                  Colors.grey.shade100,
                                  Colors.black87,
                                ),
                                const SizedBox(width: 12),
                                _buildResultCard(
                                  '$correctAnswers',
                                  'Correct Answers',
                                  Colors.green.shade100,
                                  Colors.green.shade800,
                                ),
                                const SizedBox(width: 12),
                                _buildResultCard(
                                  '${totalQuestions > 0 ? (correctAnswers / totalQuestions * 100).round() : 0}%',
                                  'Score',
                                  Colors.purple.shade100,
                                  Colors.purple.shade800,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Final Score: $correctAnswers out of $totalQuestions',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
    LinearGradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgressCard(
    double progress,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 8.0,
            percent: progress,
            center: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            progressColor: color,
            backgroundColor: color.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String value,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(MCQRow q) {
    final selected = answers[q.id];
    final serverHas = serverAnsweredQuestionIds.contains(q.id);
    final correctOpt = q.correctOption;
    final isCorrect = selected == correctOpt;
    final showCorrect = (showAnswers || serverHas);

    final serverRow = examRowsRaw.firstWhere(
      (r) {
        final rEmail = extractEmail(r.studentEmail);
        final myEmail = extractEmail(loggedEmail ?? '');
        return r.question.trim() == q.question.trim() &&
            myEmail.isNotEmpty &&
            rEmail == myEmail;
      },
      orElse: () => MCQRow(
        id: -1,
        question: '',
        option1: '',
        option2: '',
        option3: '',
        option4: '',
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
        border: showCorrect && serverRow.result != null
            ? Border.all(
                color: serverRow.result!
                    ? Colors.green.shade300
                    : Colors.red.shade300,
                width: 2,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: showCorrect && serverRow.result != null
                        ? (serverRow.result!
                              ? Colors.green.shade100
                              : Colors.red.shade100)
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${uniqueQuestions.indexOf(q) + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: showCorrect && serverRow.result != null
                          ? (serverRow.result!
                                ? Colors.green.shade800
                                : Colors.red.shade800)
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
                if (showCorrect && serverRow.result != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: serverRow.result!
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          serverRow.result! ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: serverRow.result!
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            serverRow.result! ? 'Correct' : 'Incorrect',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: serverRow.result!
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Question Text
            Text(
              q.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Options
            ...[
              q.option1,
              q.option2,
              q.option3,
              q.option4,
            ].asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionValue = index + 1;
              final isSelected = selected == optionValue;
              final isCorrectAnswer = correctOpt == optionValue;
              final isUserAnswer = serverRow.studentAnswer == optionValue;
              final isWrongUserAnswer = isUserAnswer && !isCorrectAnswer;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: serverHas
                      ? null
                      : () => handleOptionSelect(q.id, optionValue),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (isCorrectAnswer && showCorrect
                                  ? Colors.green
                                  : Colors.blue)
                            : (isCorrectAnswer && showCorrect
                                  ? Colors.green
                                  : Colors.grey.shade300),
                        width: isSelected || (isCorrectAnswer && showCorrect)
                            ? 2
                            : 1,
                      ),
                      color: isSelected
                          ? (isCorrectAnswer && showCorrect
                                ? Colors.green.shade50
                                : Colors.blue.shade50)
                          : (isCorrectAnswer && showCorrect
                                ? Colors.green.shade50
                                : Colors.white),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isCorrectAnswer && showCorrect
                                      ? Colors.green
                                      : Colors.blue)
                                : (isCorrectAnswer && showCorrect
                                      ? Colors.green.shade200
                                      : Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                color:
                                    isSelected ||
                                        (isCorrectAnswer && showCorrect)
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color:
                                  isSelected || (isCorrectAnswer && showCorrect)
                                  ? Colors.black87
                                  : Colors.black87,
                              fontWeight:
                                  isSelected || (isCorrectAnswer && showCorrect)
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (showCorrect) ...[
                          const SizedBox(width: 8),
                          if (isCorrectAnswer)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Correct',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else if (isWrongUserAnswer)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Your Answer',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Result Summary
            if (serverHas && serverRow.id != -1)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSummaryItem(
                      'Your Choice',
                      'Option ${serverRow.studentAnswer}',
                      Colors.blue.shade100,
                      Colors.blue.shade800,
                    ),
                    _buildSummaryItem(
                      'Correct Answer',
                      'Option $correctOpt',
                      Colors.green.shade100,
                      Colors.green.shade800,
                    ),
                    _buildSummaryItem(
                      'Result',
                      serverRow.result == true ? 'Correct ✓' : 'Incorrect ✗',
                      serverRow.result == true
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      serverRow.result == true
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
