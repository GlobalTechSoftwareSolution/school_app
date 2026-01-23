import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Issue {
  final int id;
  final String subject;
  final String status;
  final String description;
  final String priority;
  final String createdAt;
  final String updatedAt;
  final String? raisedBy;
  final String? raisedTo;
  final String? closedDescription;

  Issue({
    required this.id,
    required this.subject,
    required this.status,
    required this.description,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.raisedBy,
    this.raisedTo,
    this.closedDescription,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'Open',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Low',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      raisedBy: json['raised_by'],
      raisedTo: json['raised_to'],
      closedDescription: json['closed_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'description': description,
      'priority': priority,
      'raised_to': raisedTo,
      'raised_by': raisedBy,
      'status': status,
    };
  }
}

class AdminIssuesComponent extends StatefulWidget {
  const AdminIssuesComponent({super.key});

  @override
  State<AdminIssuesComponent> createState() => _AdminIssuesComponentState();
}

class _AdminIssuesComponentState extends State<AdminIssuesComponent> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Issue> issues = [];
  bool isLoading = true;
  bool showForm = false;
  bool showView = false;
  Issue? selectedIssue;
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController raisedToController = TextEditingController();
  final TextEditingController newCommentController = TextEditingController();
  String priority = "Low";
  String search = "";
  String activeTab = "details";
  String currentUserName = "";
  String currentUserEmail = "";

  @override
  void initState() {
    super.initState();
    fetchIssues();
    fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final name =
          prefs.getString('user_name') ?? email?.split('@')[0] ?? 'User';

      setState(() {
        currentUserEmail = email ?? '';
        currentUserName = name;
      });
    } catch (e) {
      setState(() {
        currentUserName = 'User';
        currentUserEmail = '';
      });
    }
  }

  Future<void> fetchIssues() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/issues/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => issues = data.map((e) => Issue.fromJson(e)).toList());
      } else {
        throw Exception('Failed to load issues');
      }
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching issues: $err')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleAddIssue() async {
    if (subjectController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');

      if (userEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
          ),
        );
        return;
      }

      final issueData = {
        'subject': subjectController.text,
        'description': descriptionController.text,
        'priority': priority,
        'raised_to': raisedToController.text,
        'raised_by': userEmail,
        'status': 'Open',
      };

      await http.post(
        Uri.parse('$apiBaseUrl/issues/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(issueData),
      );

      setState(() {
        showForm = false;
        subjectController.clear();
        descriptionController.clear();
        raisedToController.clear();
        priority = "Low";
      });

      fetchIssues();
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating issue: $err')));
    }
  }

  Future<void> handleStatusChange(int id, String newStatus) async {
    try {
      await http.patch(
        Uri.parse('$apiBaseUrl/issues/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      fetchIssues();

      if (selectedIssue != null && selectedIssue!.id == id) {
        setState(
          () => selectedIssue = Issue(
            id: selectedIssue!.id,
            subject: selectedIssue!.subject,
            status: newStatus,
            description: selectedIssue!.description,
            priority: selectedIssue!.priority,
            createdAt: selectedIssue!.createdAt,
            updatedAt: selectedIssue!.updatedAt,
            raisedBy: selectedIssue!.raisedBy,
            raisedTo: selectedIssue!.raisedTo,
            closedDescription: selectedIssue!.closedDescription,
          ),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $err')));
    }
  }

  Future<void> handleAddComment() async {
    if (newCommentController.text.trim().isEmpty || selectedIssue == null)
      return;

    try {
      final timestamp = DateTime.now().toLocal().toString();
      final commentHeader =
          '\n\n--- Comment by ${currentUserName} (${currentUserEmail}) on ${timestamp} ---\n';

      final updatedDescription =
          selectedIssue!.description +
          commentHeader +
          newCommentController.text;

      await http.patch(
        Uri.parse('$apiBaseUrl/issues/${selectedIssue!.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'description': updatedDescription}),
      );

      final res = await http.get(
        Uri.parse('$apiBaseUrl/issues/${selectedIssue!.id}/'),
      );

      setState(() {
        selectedIssue = Issue.fromJson(json.decode(res.body));
        newCommentController.clear();
      });

      fetchIssues();
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding comment: $err')));
    }
  }

  Future<void> handleDelete(int id) async {
    if (!await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Issue'),
        content: const Text('Are you sure you want to delete this issue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ))
      return;

    try {
      await http.delete(Uri.parse('$apiBaseUrl/issues/$id/'));

      fetchIssues();
      if (selectedIssue != null && selectedIssue!.id == id) {
        setState(() {
          showView = false;
          selectedIssue = null;
        });
      }
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting issue: $err')));
    }
  }

  void handleView(Issue issue) {
    setState(() {
      selectedIssue = issue;
      showView = true;
      activeTab = "details";
    });
  }

  List<Issue> get filteredIssues {
    return issues
        .where(
          (i) =>
              i.subject.toLowerCase().contains(search.toLowerCase()) ||
              i.description.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
  }

  Map<String, int> get stats {
    return {
      'total': issues.length,
      'open': issues.where((i) => i.status == "Open").length,
      'inProgress': issues.where((i) => i.status == "In Progress").length,
      'closed': issues.where((i) => i.status == "Closed").length,
      'highPriority': issues.where((i) => i.priority == "High").length,
    };
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Closed":
        return Colors.green;
      case "In Progress":
        return Colors.blue;
      case "Open":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget getStatusIcon(String status) {
    switch (status) {
      case "Closed":
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case "In Progress":
        return const Icon(Icons.access_time, size: 16, color: Colors.blue);
      case "Open":
        return const Icon(Icons.error_outline, size: 16, color: Colors.grey);
      default:
        return const Icon(Icons.help_outline, size: 16, color: Colors.grey);
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    raisedToController.dispose();
    newCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.blue[50]!],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '🎯 Issue Management',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 600
                                ? 28
                                : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => showForm = true),
                        icon: const Icon(Icons.add),
                        label: Text(
                          MediaQuery.of(context).size.width > 600
                              ? 'Report New Issue'
                              : 'Report Issue',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Track and resolve system issues efficiently',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),

            // Enhanced Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 768 ? 5 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatCard(
                    'Total Issues',
                    stats['total']!.toString(),
                    Icons.archive,
                    Colors.blue,
                    'Total reported',
                  ),
                  _buildStatCard(
                    'Open Issues',
                    stats['open']!.toString(),
                    Icons.error_outline,
                    Colors.red,
                    'Awaiting action',
                  ),
                  _buildStatCard(
                    'In Progress',
                    stats['inProgress']!.toString(),
                    Icons.access_time,
                    Colors.blue,
                    'Being worked on',
                  ),
                  _buildStatCard(
                    'Resolved',
                    stats['closed']!.toString(),
                    Icons.check_circle,
                    Colors.green,
                    'Completed',
                  ),
                  _buildStatCard(
                    'High Priority',
                    stats['highPriority']!.toString(),
                    Icons.trending_up,
                    Colors.orange,
                    'Urgent issues',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search
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
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search issues by subject or description...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => setState(() => search = value),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Issues Grid
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredIssues.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        search.isEmpty
                            ? 'No issues found'
                            : 'No matching issues',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => showForm = true),
                        child: const Text('Report First Issue'),
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
                  childAspectRatio: 1.2,
                ),
                itemCount: filteredIssues.length,
                itemBuilder: (context, index) {
                  final issue = filteredIssues[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with status and priority
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(
                                    issue.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: getStatusColor(
                                      issue.status,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    getStatusIcon(issue.status),
                                    const SizedBox(width: 4),
                                    Text(
                                      issue.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: getStatusColor(issue.status),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: getPriorityColor(
                                    issue.priority,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  issue.priority,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: getPriorityColor(issue.priority),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Subject
                          Text(
                            issue.subject,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Description preview
                          Expanded(
                            child: Text(
                              issue.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Metadata
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ID: #${issue.id}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                DateTime.parse(
                                  issue.createdAt,
                                ).toLocal().toString().split(' ')[0],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => handleView(issue),
                                  icon: const Icon(Icons.visibility, size: 14),
                                  label: const Text(
                                    'View',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              if (issue.status != "Closed") ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () =>
                                      handleStatusChange(issue.id, "Closed"),
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                  ),
                                  color: Colors.green,
                                  tooltip: 'Close Issue',
                                ),
                              ],
                              if (issue.status == "Open") ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () => handleStatusChange(
                                    issue.id,
                                    "In Progress",
                                  ),
                                  icon: const Icon(Icons.access_time, size: 16),
                                  color: Colors.orange,
                                  tooltip: 'Mark In Progress',
                                ),
                              ],
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => handleDelete(issue.id),
                                icon: const Icon(Icons.delete, size: 16),
                                color: Colors.red,
                                tooltip: 'Delete Issue',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Add Issue Form Modal
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
                                  colors: [
                                    Colors.blue[600]!,
                                    Colors.purple[600]!,
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Report New Issue',
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
                                  TextField(
                                    controller: subjectController,
                                    decoration: InputDecoration(
                                      labelText: 'Subject *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: priority,
                                          decoration: InputDecoration(
                                            labelText: 'Priority *',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Low',
                                              child: Text('Low'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Medium',
                                              child: Text('Medium'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'High',
                                              child: Text('High'),
                                            ),
                                          ],
                                          onChanged: (value) => setState(
                                            () => priority = value ?? 'Low',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  TextField(
                                    controller: raisedToController,
                                    decoration: InputDecoration(
                                      labelText: 'Assign To *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  TextField(
                                    controller: descriptionController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      labelText: 'Description *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

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
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: handleAddIssue,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text('Create Issue'),
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

            // View Issue Modal
            if (showView && selectedIssue != null)
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
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[600]!,
                                    Colors.purple[600]!,
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedIssue!.subject,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => showView = false),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tabs
                            Container(
                              color: Colors.grey[100],
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => activeTab = "details"),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        alignment: Alignment.center,
                                        color: activeTab == "details"
                                            ? Colors.white
                                            : Colors.grey[100],
                                        child: Text(
                                          '📋 Issue Details',
                                          style: TextStyle(
                                            fontWeight: activeTab == "details"
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: activeTab == "details"
                                                ? Colors.blue
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => activeTab = "comments",
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        alignment: Alignment.center,
                                        color: activeTab == "comments"
                                            ? Colors.white
                                            : Colors.grey[100],
                                        child: Text(
                                          '💬 Add Comment',
                                          style: TextStyle(
                                            fontWeight: activeTab == "comments"
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: activeTab == "comments"
                                                ? Colors.blue
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: activeTab == "details"
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Status badges
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: getStatusColor(
                                                  selectedIssue!.status,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: getStatusColor(
                                                    selectedIssue!.status,
                                                  ).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  getStatusIcon(
                                                    selectedIssue!.status,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    selectedIssue!.status,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: getStatusColor(
                                                        selectedIssue!.status,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: getPriorityColor(
                                                  selectedIssue!.priority,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                selectedIssue!.priority +
                                                    ' Priority',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: getPriorityColor(
                                                    selectedIssue!.priority,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 16),

                                        // Description
                                        const Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            selectedIssue!.description,
                                            style: const TextStyle(height: 1.5),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Metadata
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Created',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateTime.parse(
                                                      selectedIssue!.createdAt,
                                                    ).toLocal().toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Updated',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateTime.parse(
                                                      selectedIssue!.updatedAt,
                                                    ).toLocal().toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Add Comment / Update',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: newCommentController,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Add your comment or update here. This will be appended to the issue description...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: handleAddComment,
                                          icon: const Icon(Icons.send),
                                          label: const Text('Add Comment'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),

                            // Actions
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  if (selectedIssue!.status != "Closed") ...[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => handleStatusChange(
                                          selectedIssue!.id,
                                          "Closed",
                                        ),
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text('Close Issue'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (selectedIssue!.status == "Open") ...[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => handleStatusChange(
                                          selectedIssue!.id,
                                          "In Progress",
                                        ),
                                        icon: const Icon(Icons.access_time),
                                        label: const Text('Mark In Progress'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          handleDelete(selectedIssue!.id),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
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
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
