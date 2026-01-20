import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
}

class StudentReportsPage extends StatefulWidget {
  const StudentReportsPage({super.key});

  @override
  State<StudentReportsPage> createState() => _StudentReportsPageState();
}

class _StudentReportsPageState extends State<StudentReportsPage> {
  List<Report> reports = [];
  bool isLoading = true;
  String? error;
  String? studentEmail;
  final TextEditingController searchController = TextEditingController();
  String filterType = 'all';

  String get searchTerm => searchController.text;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
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

      setState(() => studentEmail = email);

      final response = await http.get(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/reports/',
        ),
      );

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to fetch reports: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final allReports = (data is List ? data : [])
          .map((r) => Report.fromJson(r))
          .toList();

      // Filter reports for this student
      final studentReports = allReports.where((report) {
        final reportEmails = [
          report.studentEmail,
          if (report.studentEmail != null) report.studentEmail!.toLowerCase(),
        ].where((e) => e != null && e.isNotEmpty).toSet();

        return reportEmails.contains(email.toLowerCase());
      }).toList();

      setState(() {
        reports = studentReports;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load reports: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Report> get filteredReports {
    return reports.where((report) {
      final matchesSearch =
          searchTerm.isEmpty ||
          report.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          report.description.toLowerCase().contains(searchTerm.toLowerCase());

      final matchesType =
          filterType == 'all' ||
          report.reportType.toLowerCase() == filterType.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();
  }

  List<String> get reportTypes {
    return reports
        .map((r) => r.reportType)
        .toSet()
        .where((type) => type.isNotEmpty)
        .toList();
  }

  Map<String, int> get stats {
    final thisMonth = reports.where((report) {
      final reportDate = DateTime.parse(report.createdAt);
      final now = DateTime.now();
      return reportDate.month == now.month && reportDate.year == now.year;
    }).length;

    final withAttachments = reports
        .where((report) => report.fileUrl != null && report.fileUrl!.isNotEmpty)
        .length;

    return {
      'total': reports.length,
      'thisMonth': thisMonth,
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
      default:
        return Colors.grey;
    }
  }

  void _showAttachmentInfo(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attachment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_file, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Attachment available for this report'),
            const SizedBox(height: 8),
            Text(
              url,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.description,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'My Reports',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Access all your academic reports and progress updates in one place',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (studentEmail != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Logged in as: ',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        studentEmail!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Statistics Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildStatCard(
                'Total Reports',
                stats['total']!.toString(),
                Icons.bar_chart,
                Colors.blue,
                BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              _buildStatCard(
                'This Month',
                stats['thisMonth']!.toString(),
                Icons.calendar_today,
                Colors.green,
                BorderRadius.zero,
              ),
              _buildStatCard(
                'With Attachments',
                stats['withAttachments']!.toString(),
                Icons.attach_file,
                Colors.purple,
                BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Search and Filter Section
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                const Text(
                  'Search Reports',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title or description...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Filter Dropdown
                const Text(
                  'Filter by Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: filterType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Report Types'),
                    ),
                    ...reportTypes.map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => filterType = value ?? 'all'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Reports Grid
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchReports,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        else if (filteredReports.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    reports.isEmpty
                        ? 'No Reports Found'
                        : 'No Matching Reports',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reports.isEmpty
                        ? "You don't have any reports yet. They will appear here once your teachers create them."
                        : 'Try adjusting your search or filter criteria.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (searchTerm.isNotEmpty || filterType != 'all')
                    ElevatedButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() => filterType = 'all');
                      },
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 768
                  ? 3
                  : MediaQuery.of(context).size.width > 600
                  ? 2
                  : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              final report = filteredReports[index];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with attachment indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (report.fileUrl != null &&
                              report.fileUrl!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.attach_file,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
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
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Expanded(
                        child: Text(
                          report.description.isEmpty
                              ? 'No description available.'
                              : report.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Metadata
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            if (report.teacherEmail != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Teacher: ${report.teacherEmail}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatDate(report.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Actions
                      if (report.fileUrl != null && report.fileUrl!.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showAttachmentInfo(report.fileUrl!),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Attachment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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

        // Footer Info
        if (filteredReports.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Showing ${filteredReports.length} of ${reports.length} reports',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BorderRadius borderRadius,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
