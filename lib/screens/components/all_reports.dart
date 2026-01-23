import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Report {
  final int id;
  final String title;
  final String description;
  final String reportType;
  final String createdAt;
  final String? teacherEmail;
  final String? studentEmail;
  final String? fileUrl;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.reportType,
    required this.createdAt,
    this.teacherEmail,
    this.studentEmail,
    this.fileUrl,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Report',
      description: json['description'] ?? '',
      reportType: json['report_type'] ?? 'general',
      createdAt: json['created_at'] ?? '',
      teacherEmail: json['teacher_email'],
      studentEmail: json['student_email'] ?? json['studentEmail'],
      fileUrl: json['file_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'report_type': reportType,
      'created_at': createdAt,
      'teacher_email': teacherEmail,
      'student_email': studentEmail,
      'file_url': fileUrl,
    };
  }
}

class AllReports extends StatefulWidget {
  const AllReports({super.key});

  @override
  State<AllReports> createState() => _AllReportsState();
}

class _AllReportsState extends State<AllReports> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Report> reports = [];
  bool isLoading = true;
  String? error;
  String searchTerm = '';
  String filterType = 'all';
  String filterTeacher = 'all';
  String filterStudent = 'all';
  DateTimeRange? dateRange;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/reports/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => reports = data.map((e) => Report.fromJson(e)).toList());
      } else {
        setState(() => error = 'Failed to load reports');
      }
    } catch (err) {
      setState(() => error = err.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> createReport(Report report) async {
    setState(() => isLoading = true);

    try {
      final payload = report.toJson();

      final response = await http.post(
        Uri.parse('$apiBaseUrl/reports/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report created successfully')),
          );
        }
      } else {
        throw Exception('Failed to create report');
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $err')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteReport(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final response = await http.delete(Uri.parse('$apiBaseUrl/reports/$id/'));

      if (response.statusCode == 204 || response.statusCode == 200) {
        setState(() => reports.removeWhere((r) => r.id == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully')),
          );
        }
      } else {
        throw Exception('Failed to delete report');
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $err')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Report> get filteredReports {
    return reports.where((report) {
      final matchesSearch =
          searchTerm.isEmpty ||
          report.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          report.description.toLowerCase().contains(searchTerm.toLowerCase()) ||
          (report.teacherEmail?.toLowerCase().contains(
                searchTerm.toLowerCase(),
              ) ??
              false) ||
          (report.studentEmail?.toLowerCase().contains(
                searchTerm.toLowerCase(),
              ) ??
              false);

      final matchesType =
          filterType == 'all' || report.reportType == filterType;
      final matchesTeacher =
          filterTeacher == 'all' || report.teacherEmail == filterTeacher;
      final matchesStudent =
          filterStudent == 'all' || report.studentEmail == filterStudent;

      final matchesDate =
          dateRange == null ||
          (DateTime.parse(
                report.createdAt,
              ).isAfter(dateRange!.start.subtract(const Duration(days: 1))) &&
              DateTime.parse(
                report.createdAt,
              ).isBefore(dateRange!.end.add(const Duration(days: 1))));

      return matchesSearch &&
          matchesType &&
          matchesTeacher &&
          matchesStudent &&
          matchesDate;
    }).toList();
  }

  List<String> get reportTypes {
    return reports
        .map((r) => r.reportType)
        .toSet()
        .where((type) => type.isNotEmpty)
        .toList();
  }

  List<String> get teachers {
    return reports
        .map((r) => r.teacherEmail)
        .where((email) => email != null && email.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();
  }

  List<String> get students {
    return reports
        .map((r) => r.studentEmail)
        .where((email) => email != null && email.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();
  }

  Map<String, int> get stats {
    final thisMonth = reports.where((report) {
      final reportDate = DateTime.parse(report.createdAt);
      final now = DateTime.now();
      return reportDate.month == now.month && reportDate.year == now.year;
    }).length;

    final thisWeek = reports.where((report) {
      final reportDate = DateTime.parse(report.createdAt);
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return reportDate.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).length;

    final withAttachments = reports
        .where((report) => report.fileUrl != null && report.fileUrl!.isNotEmpty)
        .length;

    return {
      'total': reports.length,
      'thisMonth': thisMonth,
      'thisWeek': thisWeek,
      'withAttachments': withAttachments,
    };
  }

  Color getReportTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'progress':
        return Colors.green;
      case 'behavior':
        return Colors.orange;
      case 'academic':
        return Colors.blue;
      case 'attendance':
        return Colors.purple;
      case 'financial':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
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
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.indigo],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reports Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Generate, view, and manage all system reports',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showGenerateReportDialog(),
                          icon: const Icon(Icons.add_chart),
                          label: const Text('Generate Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics Cards
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 768
                        ? 4
                        : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Total Reports',
                        stats['total']!.toString(),
                        Icons.bar_chart,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'This Month',
                        stats['thisMonth']!.toString(),
                        Icons.calendar_today,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'This Week',
                        stats['thisWeek']!.toString(),
                        Icons.date_range,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'With Files',
                        stats['withAttachments']!.toString(),
                        Icons.attach_file,
                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Filters
                  Container(
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
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search reports...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setState(() => searchTerm = value),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width > 600
                                  ? (MediaQuery.of(context).size.width - 64) / 2
                                  : MediaQuery.of(context).size.width - 32,
                              child: DropdownButtonFormField<String>(
                                value: filterType,
                                decoration: const InputDecoration(
                                  labelText: 'Report Type',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Types'),
                                  ),
                                  ...reportTypes.map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => filterType = value!),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width > 600
                                  ? (MediaQuery.of(context).size.width - 64) / 2
                                  : MediaQuery.of(context).size.width - 32,
                              child: DropdownButtonFormField<String>(
                                value: filterTeacher,
                                decoration: const InputDecoration(
                                  labelText: 'Teacher',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Teachers'),
                                  ),
                                  ...teachers.map(
                                    (email) => DropdownMenuItem(
                                      value: email,
                                      child: Tooltip(
                                        message: email,
                                        child: Text(
                                          email.length > 25
                                              ? '${email.substring(0, 22)}...'
                                              : email,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => filterTeacher = value!),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width > 600
                                  ? (MediaQuery.of(context).size.width - 64) / 2
                                  : MediaQuery.of(context).size.width - 32,
                              child: DropdownButtonFormField<String>(
                                value: filterStudent,
                                decoration: const InputDecoration(
                                  labelText: 'Student',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Students'),
                                  ),
                                  ...students.map(
                                    (email) => DropdownMenuItem(
                                      value: email,
                                      child: Tooltip(
                                        message: email,
                                        child: Text(
                                          email.length > 25
                                              ? '${email.substring(0, 22)}...'
                                              : email,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => filterStudent = value!),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width > 600
                                  ? (MediaQuery.of(context).size.width - 64) / 2
                                  : MediaQuery.of(context).size.width - 32,
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDateRange: dateRange,
                                  );
                                  if (picked != null)
                                    setState(() => dateRange = picked);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date Range',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    dateRange != null
                                        ? '${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}'
                                        : 'Select dates',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reports List
                  if (filteredReports.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No reports found'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return _buildReportCard(report);
                      },
                    ),

                  if (error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getReportTypeColor(
                      report.reportType,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getReportTypeColor(
                        report.reportType,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    report.reportType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: getReportTypeColor(report.reportType),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (report.fileUrl != null && report.fileUrl!.isNotEmpty)
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.blue,
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _showReportDetail(report);
                            break;
                          case 'delete':
                            deleteReport(report.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('View Details'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formatDate(report.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (report.teacherEmail != null) ...[
                  const Spacer(),
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    report.teacherEmail!.split('@')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
                if (report.studentEmail != null) ...[
                  const Spacer(),
                  Icon(Icons.school, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    report.studentEmail!.split('@')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateReportDialog() {
    showDialog(
      context: context,
      builder: (context) => const GenerateReportDialog(),
    ).then((report) {
      if (report != null) {
        createReport(report);
      }
    });
  }

  void _showReportDetail(Report report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailDialog(report: report),
    );
  }
}

class GenerateReportDialog extends StatefulWidget {
  const GenerateReportDialog({super.key});

  @override
  State<GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<GenerateReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teacherEmailController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _fileUrlController = TextEditingController();
  String _reportType = 'academic';

  final reportTypes = [
    'academic',
    'progress',
    'behavior',
    'attendance',
    'financial',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate New Report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Report Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _reportType,
                      decoration: const InputDecoration(
                        labelText: 'Report Type',
                        border: OutlineInputBorder(),
                      ),
                      items: reportTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _reportType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _teacherEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Email (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _studentEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Student Email (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fileUrlController,
                decoration: const InputDecoration(
                  labelText: 'File URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final report = Report(
                          id: 0,
                          title: _titleController.text,
                          description: _descriptionController.text,
                          reportType: _reportType,
                          createdAt: DateTime.now().toIso8601String(),
                          teacherEmail: _teacherEmailController.text.isEmpty
                              ? null
                              : _teacherEmailController.text,
                          studentEmail: _studentEmailController.text.isEmpty
                              ? null
                              : _studentEmailController.text,
                          fileUrl: _fileUrlController.text.isEmpty
                              ? null
                              : _fileUrlController.text,
                        );
                        Navigator.of(context).pop(report);
                      }
                    },
                    child: const Text('Generate Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportDetailDialog extends StatelessWidget {
  final Report report;

  const ReportDetailDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (report.description.isNotEmpty) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(report.description),
              const SizedBox(height: 16),
            ],
            _buildInfoRow('Report Type', report.reportType.toUpperCase()),
            _buildInfoRow('Created At', report.createdAt),
            if (report.teacherEmail != null)
              _buildInfoRow('Teacher', report.teacherEmail!),
            if (report.studentEmail != null)
              _buildInfoRow('Student', report.studentEmail!),
            if (report.fileUrl != null && report.fileUrl!.isNotEmpty)
              _buildInfoRow('File URL', report.fileUrl!),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
