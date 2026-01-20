import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String assignedToEmail;
  final String status; // "Pending" | "In Progress" | "Completed" | "Overdue"
  final String dueDate;
  final String createdAt;
  final String? priority; // "Low" | "Medium" | "High"
  final String? subject;
  final String? teacherName;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToEmail,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    this.priority,
    this.subject,
    this.teacherName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedToEmail: json['assigned_to_email'] ?? '',
      status: json['status'] ?? 'Pending',
      dueDate: json['due_date'] ?? '',
      createdAt: json['created_at'] ?? '',
      priority: json['priority'],
      subject: json['subject'],
      teacherName: json['teacher_name'],
    );
  }
}

class TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int inProgress;
  final int overdue;

  TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.overdue,
  });
}

class StudentTasksPage extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const StudentTasksPage({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<StudentTasksPage> createState() => _StudentTasksPageState();
}

class _StudentTasksPageState extends State<StudentTasksPage> {
  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/';

  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  bool loading = true;
  String? error;
  Task? selectedTask;
  TaskStats stats = TaskStats(
    total: 0,
    completed: 0,
    pending: 0,
    inProgress: 0,
    overdue: 0,
  );
  String filter = 'all';
  String searchTerm = '';

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final email = widget.userEmail;
      final token = prefs.getString('accessToken');

      if (email.isEmpty) {
        setError('Student email not found.');
        return;
      }

      // For now, show empty state since /api/tasks/ endpoint doesn't exist
      // You can uncomment and modify this code when you create the tasks endpoint

      /*
      final apiUrl = '$apiBase/tasks/';

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }

      final data = json.decode(response.body);

      final filteredTasksData = data is List
          ? data
                .where(
                  (task) =>
                      task['assigned_to_email']?.toString().toLowerCase() ==
                      email.toLowerCase(),
                )
                .map((task) => Task.fromJson(task))
                .toList()
          : [];

      setState(() {
        tasks = filteredTasksData as List<Task>;
        calculateStats(filteredTasksData);
        applyFilters();
      });
      */

      // Temporary: Show empty state
      setState(() {
        tasks = [];
        calculateStats([]);
        applyFilters();
      });
    } catch (e) {
      setError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void calculateStats(List<Task> taskList) {
    final newStats = TaskStats(
      total: taskList.length,
      completed: taskList.where((task) => task.status == 'Completed').length,
      pending: taskList.where((task) => task.status == 'Pending').length,
      inProgress: taskList.where((task) => task.status == 'In Progress').length,
      overdue: taskList.where((task) {
        if (task.status == 'Completed') return false;
        if (task.dueDate.isEmpty) return false;
        return DateTime.parse(task.dueDate).isBefore(DateTime.now());
      }).length,
    );
    setState(() => stats = newStats);
  }

  void applyFilters() {
    List<Task> result = tasks;

    // Apply status filter
    if (filter != 'all') {
      result = result.where((task) => task.status == filter).toList();
    }

    // Apply search filter
    if (searchTerm.isNotEmpty) {
      final term = searchTerm.toLowerCase();
      result = result
          .where(
            (task) =>
                task.title.toLowerCase().contains(term) ||
                task.description.toLowerCase().contains(term) ||
                (task.subject?.toLowerCase().contains(term) ?? false) ||
                (task.teacherName?.toLowerCase().contains(term) ?? false),
          )
          .toList();
    }

    setState(() => filteredTasks = result);
  }

  void setError(String message) {
    setState(() => error = message);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.yellow;
    }
  }

  Color getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String formatDate(String dateString) {
    if (dateString.isEmpty) return 'Not specified';

    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow, ${DateFormat('HH:mm').format(date)}';
    } else {
      return '${DateFormat('MMM d, yyyy').format(date)}, ${DateFormat('HH:mm').format(date)}';
    }
  }

  bool isOverdue(String dueDate, String status) {
    if (status == 'Completed') return false;
    if (dueDate.isEmpty) return false;
    return DateTime.parse(dueDate).isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
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
                  child: const Column(
                    children: [
                      Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Manage your academic assignments, track progress, and stay organized with all your tasks in one place.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Statistics Cards
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildStatCard(
                        '${stats.total}',
                        'Total Tasks',
                        Colors.blue,
                      ),
                      _buildStatCard(
                        '${stats.completed}',
                        'Completed',
                        Colors.green,
                      ),
                      _buildStatCard(
                        '${stats.pending}',
                        'Pending',
                        Colors.yellow,
                      ),
                      _buildStatCard(
                        '${stats.inProgress}',
                        'In Progress',
                        Colors.blue,
                      ),
                      _buildStatCard('${stats.overdue}', 'Overdue', Colors.red),
                      Container(), // Empty container for even grid
                    ],
                  ),
                ),

                // Filters and Search
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Filter buttons
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterButton('All Tasks', 'all'),
                          _buildFilterButton('Pending', 'Pending'),
                          _buildFilterButton('In Progress', 'In Progress'),
                          _buildFilterButton('Completed', 'Completed'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          setState(() => searchTerm = value);
                          applyFilters();
                        },
                      ),
                    ],
                  ),
                ),

                // Loading State
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Error State
                if (error != null && !loading)
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Unable to Load Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchTasks,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // Empty State
                if (!loading && error == null && filteredTasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('📚', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          searchTerm.isNotEmpty || filter != 'all'
                              ? 'No tasks match your criteria'
                              : 'No tasks assigned',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchTerm.isNotEmpty || filter != 'all'
                              ? 'Try adjusting your search or filter criteria.'
                              : 'You don\'t have any tasks assigned yet. Check back later for new assignments.',
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        if (searchTerm.isNotEmpty || filter != 'all')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  searchTerm = '';
                                  filter = 'all';
                                });
                                applyFilters();
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Task Grid
                if (!loading && error == null && filteredTasks.isNotEmpty)
                  ...filteredTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTaskCard(task),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      width: 85,
      height: 90,
      padding: const EdgeInsets.all(12),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String filterValue) {
    final isSelected = filter == filterValue;
    return ElevatedButton(
      onPressed: () {
        setState(() => filter = filterValue);
        applyFilters();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () => _showTaskDetailModal(task),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status/Priority badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title.isNotEmpty ? task.title : 'Untitled Task',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(task.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: getStatusColor(task.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: getStatusColor(task.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (task.priority != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getPriorityColor(
                            task.priority,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${task.priority} Priority',
                          style: TextStyle(
                            fontSize: 12,
                            color: getPriorityColor(task.priority),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              task.description.isNotEmpty
                  ? task.description
                  : 'No description provided.',
              style: const TextStyle(color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Subject and Teacher
            Row(
              children: [
                if (task.subject != null) ...[
                  const Icon(Icons.book, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    task.subject!,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                ],
                if (task.teacherName != null) ...[
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    task.teacherName!,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetailModal(Task task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title.isNotEmpty ? task.title : 'Task Details',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status and Priority
                Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(task.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getStatusColor(task.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Status: ${task.status}',
                        style: TextStyle(
                          color: getStatusColor(task.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (task.priority != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getPriorityColor(
                            task.priority,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Priority: ${task.priority}',
                          style: TextStyle(
                            color: getPriorityColor(task.priority),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.description.isNotEmpty
                        ? task.description
                        : 'No description provided.',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),

                const SizedBox(height: 20),

                // Metadata
                const Text(
                  'Task Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Metadata Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetadataItem(
                            'Assigned To',
                            task.assignedToEmail,
                          ),
                          if (task.subject != null)
                            _buildMetadataItem('Subject', task.subject!),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetadataItem(
                            'Due Date',
                            formatDate(task.dueDate),
                            isOverdue: isOverdue(task.dueDate, task.status),
                          ),
                          _buildMetadataItem(
                            'Created At',
                            task.createdAt.isNotEmpty
                                ? formatDate(task.createdAt)
                                : 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (task.teacherName != null) ...[
                  const SizedBox(height: 16),
                  _buildMetadataItem(
                    'Assigned By',
                    '👨‍🏫 ${task.teacherName}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataItem(
    String label,
    String value, {
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isOverdue ? Colors.red : Colors.black87,
              fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
