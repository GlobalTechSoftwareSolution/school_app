import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Project {
  final int? id;
  final String ownerEmail;
  final String owner;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String status;
  final int classId;
  final String? className;
  final String? section;
  final String? createdAt;
  final String? ownerName;
  final String? attachment;
  final String? updatedAt;

  Project({
    this.id,
    required this.ownerEmail,
    required this.owner,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.classId,
    this.className,
    this.section,
    this.createdAt,
    this.ownerName,
    this.attachment,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      ownerEmail: json['owner_email'] ?? '',
      owner: json['owner'] ?? '',
      title: json['title'] ?? 'Untitled Project',
      description: json['description'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'In Progress',
      classId: json['class_id'] ?? 0,
      className: json['class_name'],
      section: json['section'],
      createdAt: json['created_at'],
      ownerName: json['owner_name'],
      attachment: json['attachment'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_email': ownerEmail,
      'owner': owner,
      'title': title,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'class_id': classId,
    };
  }
}

class ClassInfo {
  final int id;
  final String className;
  final String sec;

  ClassInfo({required this.id, required this.className, required this.sec});

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] ?? 0,
      className: json['class_name'] ?? '',
      sec: json['sec'] ?? '',
    );
  }
}

class Teacher {
  final int id;
  final String? fullname;
  final String? firstName;
  final String email;

  Teacher({
    required this.id,
    this.fullname,
    this.firstName,
    required this.email,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? 0,
      fullname: json['fullname'],
      firstName: json['first_name'],
      email: json['email'] ?? '',
    );
  }
}

class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class AllProjects extends StatefulWidget {
  const AllProjects({super.key});

  @override
  State<AllProjects> createState() => _AllProjectsState();
}

class _AllProjectsState extends State<AllProjects> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Project> projects = [];
  List<Project> filteredProjects = [];
  List<ClassInfo> classes = [];
  List<Teacher> teachers = [];
  List<Student> students = [];
  bool isLoading = true;
  String? error;
  String searchTerm = '';
  String statusFilter = 'all';
  String classFilter = 'all';
  Project? viewingProject;
  int? deleteConfirm;
  Map<String, int> stats = {'total': 0, 'inProgress': 0, 'completed': 0};

  Project newProject = Project(
    ownerEmail: '',
    owner: '',
    title: '',
    description: '',
    startDate: '',
    endDate: '',
    status: 'In Progress',
    classId: 0,
  );

  // Function to calculate status based on current date
  String calculateStatus(String endDate) {
    final today = DateTime.now();
    final end = DateTime.parse(endDate);

    // Reset time parts to compare only dates
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDateOnly = DateTime(end.year, end.month, end.day);

    return todayDate.isAtSameMomentAs(endDateOnly) ||
            todayDate.isBefore(endDateOnly)
        ? 'In Progress'
        : 'Completed';
  }

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Filter projects whenever data changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (projects.isNotEmpty && classes.isNotEmpty) {
        _filterProjects();
      }
    });
  }

  Future<void> fetchClasses() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/classes/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(
          () => classes = data.map((e) => ClassInfo.fromJson(e)).toList(),
        );
      }
    } catch (err) {
      debugPrint('Error fetching classes: $err');
    }
  }

  Future<void> fetchTeachers() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/teachers/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(
          () => teachers = data.map((e) => Teacher.fromJson(e)).toList(),
        );
      }
    } catch (err) {
      debugPrint('Error fetching teachers: $err');
    }
  }

  Future<void> fetchStudents() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/students/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(
          () => students = data.map((e) => Student.fromJson(e)).toList(),
        );
      }
    } catch (err) {
      debugPrint('Error fetching students: $err');
    }
  }

  Future<void> fetchProjects() async {
    try {
      setState(() => isLoading = true);
      final res = await http.get(Uri.parse('$apiBaseUrl/projects/'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;

        // Calculate status for each project based on end date
        final projectsWithCalculatedStatus = data.map((item) {
          final project = Project.fromJson(item);
          return Project(
            id: project.id,
            ownerEmail: project.ownerEmail,
            owner: project.owner,
            title: project.title,
            description: project.description,
            startDate: project.startDate,
            endDate: project.endDate,
            status: calculateStatus(project.endDate),
            classId: project.classId,
            className: project.className,
            section: project.section,
            createdAt: project.createdAt,
            ownerName: project.ownerName,
            attachment: project.attachment,
            updatedAt: project.updatedAt,
          );
        }).toList();

        setState(() {
          projects = projectsWithCalculatedStatus;
          filteredProjects = projectsWithCalculatedStatus;
          _calculateStats(projectsWithCalculatedStatus);
        });
      } else {
        setState(() => error = 'Failed to load projects');
      }
    } catch (err) {
      setState(() => error = err.toString());
      debugPrint('Error fetching projects: $err');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchProjects(),
      fetchClasses(),
      fetchTeachers(),
      fetchStudents(),
    ]);
    setState(() => isLoading = false);
  }

  void _calculateStats(List<Project> projectsData) {
    final newStats = {
      'total': projectsData.length,
      'inProgress': projectsData.where((p) => p.status == 'In Progress').length,
      'completed': projectsData.where((p) => p.status == 'Completed').length,
    };
    setState(() => stats = newStats);
  }

  // Enhanced Projects with resolved class and section details
  List<Project> get enhancedProjects {
    return projects.map((project) {
      final classInfo = classes.firstWhere(
        (c) => c.id == project.classId,
        orElse: () => ClassInfo(id: 0, className: '', sec: ''),
      );

      // Resolve owner name from teachers or students
      final teacher = teachers.firstWhere(
        (t) => t.email.toLowerCase() == project.ownerEmail.toLowerCase(),
        orElse: () => Teacher(id: 0, email: ''),
      );
      final student = students.firstWhere(
        (s) => s.email.toLowerCase() == project.ownerEmail.toLowerCase(),
        orElse: () => Student(id: 0, email: '', firstName: '', lastName: ''),
      );

      final ownerName =
          teacher.fullname ??
          teacher.firstName ??
          ((student.firstName.isNotEmpty && student.lastName.isNotEmpty)
              ? '${student.firstName} ${student.lastName}'
              : null) ??
          (project.ownerName ?? project.owner ?? 'Unknown Owner');

      return Project(
        id: project.id,
        ownerEmail: project.ownerEmail,
        owner: project.owner,
        title: project.title,
        description: project.description,
        startDate: project.startDate,
        endDate: project.endDate,
        status: project.status,
        classId: project.classId,
        className: classInfo.className.isNotEmpty
            ? classInfo.className
            : (project.className ?? 'Unknown Class'),
        section: classInfo.sec.isNotEmpty
            ? classInfo.sec
            : (project.section ?? ''),
        createdAt: project.createdAt,
        ownerName: ownerName,
        attachment: project.attachment,
        updatedAt: project.updatedAt,
      );
    }).toList();
  }

  void _filterProjects() {
    List<Project> filtered = enhancedProjects;

    if (searchTerm.isNotEmpty) {
      final searchLower = searchTerm.toLowerCase();
      filtered = filtered.where((project) {
        return (project.title.toLowerCase().contains(searchLower) ||
            project.description.toLowerCase().contains(searchLower) ||
            (project.owner.toLowerCase().contains(searchLower)) ||
            (project.ownerName?.toLowerCase().contains(searchLower) ?? false) ||
            (project.className?.toLowerCase().contains(searchLower) ?? false) ||
            (project.section?.toLowerCase().contains(searchLower) ?? false) ||
            project.status.toLowerCase().contains(searchLower));
      }).toList();
    }

    if (statusFilter != 'all') {
      filtered = filtered
          .where((project) => project.status == statusFilter)
          .toList();
    }

    if (classFilter != 'all') {
      filtered = filtered
          .where((project) => project.className == classFilter)
          .toList();
    }

    setState(() => filteredProjects = filtered);
    _calculateStats(enhancedProjects);
  }

  // Add new project
  Future<void> _handleAddProject() async {
    try {
      final projectToAdd = Project(
        ownerEmail: newProject.ownerEmail,
        owner: newProject.owner,
        title: newProject.title,
        description: newProject.description,
        startDate: newProject.startDate,
        endDate: newProject.endDate,
        status: calculateStatus(newProject.endDate),
        classId: newProject.classId,
      );

      final res = await http.post(
        Uri.parse('$apiBaseUrl/projects/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(projectToAdd.toJson()),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Project added successfully!')),
        );
        _resetForm();
        fetchProjects();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to add project')),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $err')));
    }
  }

  // Delete project
  Future<void> _handleDeleteProject(int id) async {
    try {
      final res = await http.delete(Uri.parse('$apiBaseUrl/projects/$id/'));

      if (res.statusCode == 204 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Project deleted successfully!')),
        );
        setState(() => deleteConfirm = null);
        fetchProjects();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to delete project')),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $err')));
    }
  }

  void _resetForm() {
    setState(() {
      newProject = Project(
        ownerEmail: '',
        owner: '',
        title: '',
        description: '',
        startDate: '',
        endDate: '',
        status: 'In Progress',
        classId: 0,
      );
    });
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'In Progress':
        return '▶️';
      case 'Completed':
        return '✅';
      default:
        return '📅';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.green;
      case 'Completed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<String> get _uniqueClasses {
    return classes
        .map((c) => c.className)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'School Projects',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Manage and track academic projects and competitions',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddProjectDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Statistics Cards
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 768
                        ? 3
                        : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Total Projects',
                        stats['total']!.toString(),
                        Icons.groups,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'In Progress',
                        stats['inProgress']!.toString(),
                        Icons.play_circle,
                        Colors.yellow,
                      ),
                      _buildStatCard(
                        'Completed',
                        stats['completed']!.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Filters and Search
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        // Search Bar
                        TextField(
                          decoration: const InputDecoration(
                            hintText:
                                'Search projects by title, description, owner, or class...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() => searchTerm = value);
                            _filterProjects();
                          },
                        ),

                        const SizedBox(height: 16),

                        // Status and Class Filter
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: statusFilter,
                                onChanged: (value) {
                                  setState(() => statusFilter = value!);
                                  _filterProjects();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Status'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'In Progress',
                                    child: Text('In Progress'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Completed',
                                    child: Text('Completed'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: classFilter,
                                onChanged: (value) {
                                  setState(() => classFilter = value!);
                                  _filterProjects();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Class',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Classes'),
                                  ),
                                  ..._uniqueClasses.map(
                                    (className) => DropdownMenuItem(
                                      value: className,
                                      child: Text(className),
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

                  const SizedBox(height: 24),

                  // Projects Grid
                  if (filteredProjects.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchTerm.isEmpty &&
                                      statusFilter == 'all' &&
                                      classFilter == 'all'
                                  ? 'No projects found'
                                  : 'No projects match your filters',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (searchTerm.isNotEmpty ||
                                statusFilter != 'all' ||
                                classFilter != 'all')
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  searchTerm = '';
                                  statusFilter = 'all';
                                  classFilter = 'all';
                                }),
                                child: const Text('Clear Filters'),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => _showAddProjectDialog(),
                                child: const Text('Create Project'),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 768
                            ? 3
                            : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        return _buildProjectCard(project);
                      },
                    ),

                  // Error Display
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

                  // Modals
                  if (viewingProject != null) _buildViewProjectModal(),
                  if (deleteConfirm != null) _buildDeleteConfirmModal(),
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
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(project.status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_getStatusIcon(project.status)} ${project.status}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(project.status),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Project Title
            Text(
              project.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Description
            Expanded(
              child: Text(
                project.description,
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

            // Owner Info
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    project.ownerName ?? project.owner,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Class Info
            Row(
              children: [
                Icon(Icons.class_, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${project.className ?? 'N/A'} ${project.section?.isNotEmpty == true ? '(${project.section})' : ''}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dates
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_formatDate(project.startDate)} - ${_formatDate(project.endDate)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: #${project.id}',
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => viewingProject = project),
                      icon: const Icon(Icons.visibility, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => deleteConfirm = project.id),
                      icon: const Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.red,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Title *'),
                  onChanged: (value) => newProject = Project(
                    ownerEmail: newProject.ownerEmail,
                    owner: newProject.owner,
                    title: value,
                    description: newProject.description,
                    startDate: newProject.startDate,
                    endDate: newProject.endDate,
                    status: newProject.status,
                    classId: newProject.classId,
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) => newProject = Project(
                    ownerEmail: newProject.ownerEmail,
                    owner: newProject.owner,
                    title: newProject.title,
                    description: value,
                    startDate: newProject.startDate,
                    endDate: newProject.endDate,
                    status: newProject.status,
                    classId: newProject.classId,
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Start Date *'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final formattedDate =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      setState(
                        () => newProject = Project(
                          ownerEmail: newProject.ownerEmail,
                          owner: newProject.owner,
                          title: newProject.title,
                          description: newProject.description,
                          startDate: formattedDate,
                          endDate: newProject.endDate,
                          status: newProject.status,
                          classId: newProject.classId,
                        ),
                      );
                    }
                  },
                  controller: TextEditingController(text: newProject.startDate),
                  readOnly: true,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'End Date *'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final formattedDate =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      setState(
                        () => newProject = Project(
                          ownerEmail: newProject.ownerEmail,
                          owner: newProject.owner,
                          title: newProject.title,
                          description: newProject.description,
                          startDate: newProject.startDate,
                          endDate: formattedDate,
                          status: newProject.status,
                          classId: newProject.classId,
                        ),
                      );
                    }
                  },
                  controller: TextEditingController(text: newProject.endDate),
                  readOnly: true,
                ),
                DropdownButtonFormField<int>(
                  value: newProject.classId,
                  onChanged: (value) => setState(
                    () => newProject = Project(
                      ownerEmail: newProject.ownerEmail,
                      owner: newProject.owner,
                      title: newProject.title,
                      description: newProject.description,
                      startDate: newProject.startDate,
                      endDate: newProject.endDate,
                      status: newProject.status,
                      classId: value ?? 0,
                    ),
                  ),
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: classes
                      .map(
                        (classInfo) => DropdownMenuItem(
                          value: classInfo.id,
                          child: Text(
                            '${classInfo.className} ${classInfo.sec}',
                          ),
                        ),
                      )
                      .toList(),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Owner Email *'),
                  onChanged: (value) => newProject = Project(
                    ownerEmail: value,
                    owner: newProject.owner,
                    title: newProject.title,
                    description: newProject.description,
                    startDate: newProject.startDate,
                    endDate: newProject.endDate,
                    status: newProject.status,
                    classId: newProject.classId,
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Owner Name'),
                  onChanged: (value) => newProject = Project(
                    ownerEmail: newProject.ownerEmail,
                    owner: value,
                    title: newProject.title,
                    description: newProject.description,
                    startDate: newProject.startDate,
                    endDate: newProject.endDate,
                    status: newProject.status,
                    classId: newProject.classId,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _handleAddProject,
              child: const Text('Add Project'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewProjectModal() {
    if (viewingProject == null) return const SizedBox();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      viewingProject!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => viewingProject = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Description: ${viewingProject!.description}'),
                Text(
                  'Owner: ${viewingProject!.ownerName ?? viewingProject!.owner}',
                ),
                Text(
                  'Class: ${viewingProject!.className ?? 'N/A'} ${viewingProject!.section?.isNotEmpty == true ? '(${viewingProject!.section})' : ''}',
                ),
                Text('Status: ${viewingProject!.status}'),
                Text('Start Date: ${_formatDate(viewingProject!.startDate)}'),
                Text('End Date: ${_formatDate(viewingProject!.endDate)}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmModal() {
    if (deleteConfirm == null) return const SizedBox();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Delete Project',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to delete this project? This action cannot be undone.',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => deleteConfirm = null),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handleDeleteProject(deleteConfirm!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
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
}
