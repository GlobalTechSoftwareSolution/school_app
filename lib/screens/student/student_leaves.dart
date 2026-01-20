import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class Leave {
  final int id;
  final String applicant;
  final String? approvedBy;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final String createdAt;
  final String updatedAt;

  Leave({
    required this.id,
    required this.applicant,
    required this.approvedBy,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'] ?? 0,
      applicant: json['applicant'] ?? '',
      approvedBy: json['approved_by'],
      leaveType: json['leave_type'] ?? 'Other',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class StudentLeavesPage extends StatefulWidget {
  const StudentLeavesPage({super.key});

  @override
  State<StudentLeavesPage> createState() => _StudentLeavesPageState();
}

class _StudentLeavesPageState extends State<StudentLeavesPage> {
  List<Leave> leaves = [];
  bool isLoading = true;
  String? error;
  String? studentEmail;
  String activeTab = 'all';
  bool showForm = false;
  bool submitting = false;

  final TextEditingController reasonController = TextEditingController();
  String leaveType = 'Sick';
  DateTime? startDate;
  DateTime? endDate;

  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
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
          'https://school.globaltechsoftwaresolutions.cloud/api/leaves/',
        ),
      );

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to fetch leaves: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final allLeaves = (data is List ? data : [])
          .map((l) => Leave.fromJson(l))
          .toList();

      // Filter leaves for this student
      final studentLeaves = allLeaves.where((leave) {
        return leave.applicant.toLowerCase() == email.toLowerCase();
      }).toList();

      setState(() {
        leaves = studentLeaves;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load leaves: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitLeave() async {
    if (startDate == null || endDate == null || reasonController.text.isEmpty) {
      _showSnackBar('Please fill all fields', Colors.red);
      return;
    }

    if (startDate!.isAfter(endDate!)) {
      _showSnackBar('End date cannot be before start date', Colors.red);
      return;
    }

    setState(() => submitting = true);

    try {
      final leaveData = {
        'applicant': studentEmail,
        'leave_type': leaveType,
        'start_date': startDate!.toIso8601String().split('T')[0],
        'end_date': endDate!.toIso8601String().split('T')[0],
        'reason': reasonController.text,
        'status': 'Pending',
      };

      final response = await http.post(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/leaves/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(leaveData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar(
          'Leave application submitted successfully!',
          Colors.green,
        );
        setState(() {
          showForm = false;
          reasonController.clear();
          leaveType = 'Sick';
          startDate = null;
          endDate = null;
        });
        await fetchLeaves(); // Refresh the list
      } else {
        _showSnackBar('Failed to submit leave application', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error submitting leave: $e', Colors.red);
    } finally {
      setState(() => submitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<Leave> get filteredLeaves {
    if (activeTab == 'all') return leaves;
    return leaves
        .where((leave) => leave.status.toLowerCase() == activeTab)
        .toList();
  }

  Map<String, int> get stats {
    final pending = leaves
        .where((l) => l.status.toLowerCase() == 'pending')
        .length;
    final approved = leaves
        .where((l) => l.status.toLowerCase() == 'approved')
        .length;
    final rejected = leaves
        .where((l) => l.status.toLowerCase() == 'rejected')
        .length;

    return {
      'total': leaves.length,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return '✅';
      case 'pending':
        return '⏳';
      case 'rejected':
        return '❌';
      default:
        return '📄';
    }
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  int calculateDays(String start, String end) {
    try {
      final startDate = DateTime.parse(start);
      final endDate = DateTime.parse(end);
      return endDate.difference(startDate).inDays + 1;
    } catch (e) {
      return 0;
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On small screens, stack vertically
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏖️ Leave Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => showForm = true),
                        icon: const Icon(Icons.add),
                        label: const Text('Apply for Leave'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // On larger screens, keep horizontal layout
                return Row(
                  children: [
                    const Text(
                      '🏖️ Leave Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => showForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Apply for Leave'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            'Track and manage your leave applications professionally',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),

        if (studentEmail != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ),

        const SizedBox(height: 24),

        // Statistics Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildStatCard(
                'Total Applications',
                stats['total']!.toString(),
                Icons.bar_chart,
                Colors.blue,
              ),
              _buildStatCard(
                'Pending',
                stats['pending']!.toString(),
                Icons.hourglass_top,
                Colors.orange,
              ),
              _buildStatCard(
                'Approved',
                stats['approved']!.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Rejected',
                stats['rejected']!.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Calendar Section
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
                const Text(
                  'Leave Calendar',
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
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => calendarFormat = format);
                  },
                  onPageChanged: (focused) {
                    focusedDay = focused;
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
                    return leaves.where((leave) {
                      final start = DateTime.parse(leave.startDate);
                      final end = DateTime.parse(leave.endDate);
                      return day.isAfter(
                            start.subtract(const Duration(days: 1)),
                          ) &&
                          day.isBefore(end.add(const Duration(days: 1)));
                    }).toList();
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;

                      final leave = events.first as Leave;
                      Color markerColor;
                      switch (leave.status.toLowerCase()) {
                        case 'approved':
                          markerColor = Colors.green;
                          break;
                        case 'pending':
                          markerColor = Colors.orange;
                          break;
                        case 'rejected':
                          markerColor = Colors.red;
                          break;
                        default:
                          markerColor = Colors.grey;
                      }

                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                ),

                // Legend
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLegendItem('Approved', Colors.green),
                      const SizedBox(width: 16),
                      _buildLegendItem('Pending', Colors.orange),
                      const SizedBox(width: 16),
                      _buildLegendItem('Rejected', Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Filter Tabs
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('All', 'all'),
                  const SizedBox(width: 8),
                  _buildTabButton('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildTabButton('Approved', 'approved'),
                  const SizedBox(width: 8),
                  _buildTabButton('Rejected', 'rejected'),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Leaves List
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
                    'Error Loading Leaves',
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
                    onPressed: fetchLeaves,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        else if (filteredLeaves.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.beach_access, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    activeTab == 'all'
                        ? 'No Leaves Found'
                        : 'No $activeTab Leaves',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeTab == 'all'
                        ? "You haven't applied for any leaves yet."
                        : 'No leave applications with $activeTab status.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => showForm = true),
                    child: const Text('Apply for Leave'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredLeaves.length,
            itemBuilder: (context, index) {
              final leave = filteredLeaves[index];
              final days = calculateDays(leave.startDate, leave.endDate);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(
                                leave.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: getStatusColor(
                                  leave.status,
                                ).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${getStatusIcon(leave.status)} ${leave.status.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(leave.status),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '📅 $days days',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Leave Type
                      Text(
                        '${leave.leaveType} Leave',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Reason
                      Text(
                        leave.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Dates and Metadata
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Period: ${formatDate(leave.startDate)} - ${formatDate(leave.endDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Applied: ${formatDate(leave.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Approved By
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Approved By',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    leave.approvedBy ?? 'Pending Approval',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (leave.updatedAt.isNotEmpty)
                                    Text(
                                      'Updated: ${formatDate(leave.updatedAt)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // Apply Leave Form Modal
        if (showForm)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[600]!, Colors.purple[600]!],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Apply for Leave',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () =>
                                    setState(() => showForm = false),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Leave Type
                              const Text(
                                'Leave Type',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: leaveType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Sick',
                                    child: Text('Sick Leave'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Casual',
                                    child: Text('Casual Leave'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Vacation',
                                    child: Text('Vacation Leave'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Other',
                                    child: Text('Other'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => leaveType = value ?? 'Sick'),
                              ),

                              const SizedBox(height: 16),

                              // Start Date
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => startDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        startDate != null
                                            ? formatDate(
                                                startDate!
                                                    .toIso8601String()
                                                    .split('T')[0],
                                              )
                                            : 'Select start date',
                                        style: TextStyle(
                                          color: startDate != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // End Date
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        endDate ?? startDate ?? DateTime.now(),
                                    firstDate: startDate ?? DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => endDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        endDate != null
                                            ? formatDate(
                                                endDate!
                                                    .toIso8601String()
                                                    .split('T')[0],
                                              )
                                            : 'Select end date',
                                        style: TextStyle(
                                          color: endDate != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Duration Info
                              if (startDate != null && endDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '📅 Leave Duration: ${calculateDays(startDate!.toIso8601String().split('T')[0], endDate!.toIso8601String().split('T')[0])} days',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Reason
                              const Text(
                                'Reason for Leave',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: reasonController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Please provide a detailed reason for your leave application...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => showForm = false),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: submitting
                                          ? null
                                          : submitLeave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: submitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text('Submit Application'),
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
                ),
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
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    final isSelected = activeTab == tab;
    return ElevatedButton(
      onPressed: () => setState(() => activeTab = tab),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
