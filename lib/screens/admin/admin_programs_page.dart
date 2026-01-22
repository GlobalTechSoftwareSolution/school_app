import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Program {
  final int? id;
  final String name;
  final String description;
  final String startDate;
  final String endDate;
  final String status;
  final String coordinatorEmail;
  final String coordinator;
  final String? category;
  final double? budget;

  Program({
    this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.coordinatorEmail,
    required this.coordinator,
    this.category,
    this.budget,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Program',
      description: json['description'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'Planned',
      coordinatorEmail: json['coordinator_email'] ?? '',
      coordinator: json['coordinator'] ?? 'Unknown',
      category: json['category'],
      budget: json['budget'] != null
          ? (json['budget'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'coordinator_email': coordinatorEmail,
      'coordinator': coordinator,
      'category': category,
      'budget': budget,
    };
  }
}

class ProgramWithCalculatedStatus extends Program {
  final String calculatedStatus;

  ProgramWithCalculatedStatus({
    required Program program,
    required this.calculatedStatus,
  }) : super(
         id: program.id,
         name: program.name,
         description: program.description,
         startDate: program.startDate,
         endDate: program.endDate,
         status: program.status,
         coordinatorEmail: program.coordinatorEmail,
         coordinator: program.coordinator,
         category: program.category,
         budget: program.budget,
       );

  factory ProgramWithCalculatedStatus.fromProgram(Program program) {
    final calculatedStatus = _getCalculatedStatus(
      program.startDate,
      program.endDate,
    );
    return ProgramWithCalculatedStatus(
      program: program,
      calculatedStatus: calculatedStatus,
    );
  }

  static String _getCalculatedStatus(String startDate, String endDate) {
    final today = DateTime.now();
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);

    if (today.isBefore(start)) {
      return "Upcoming";
    } else if (today.isAfter(start) &&
        today.isBefore(end.add(const Duration(days: 1)))) {
      return "Active";
    } else {
      return "Completed";
    }
  }
}

class AdminProgramsPage extends StatefulWidget {
  const AdminProgramsPage({super.key});

  @override
  State<AdminProgramsPage> createState() => _AdminProgramsPageState();
}

class _AdminProgramsPageState extends State<AdminProgramsPage> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Program> programs = [];
  bool isLoading = true;
  String? error;
  String userEmail = '';
  String searchTerm = '';
  String activeFilter = 'all'; // 'all', 'active', 'completed', 'upcoming'

  @override
  void initState() {
    super.initState();
    loadUserEmail();
    fetchPrograms();
  }

  Future<void> loadUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => userEmail = prefs.getString('user_email') ?? '');
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> fetchPrograms() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/programs/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(
          () => programs = data.map((e) => Program.fromJson(e)).toList(),
        );
      } else {
        setState(() => error = 'Failed to load programs');
      }
    } catch (err) {
      setState(() => error = err.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> createProgram(Program program) async {
    setState(() => isLoading = true);

    try {
      final payload = program.toJson();

      final response = await http.post(
        Uri.parse('$apiBaseUrl/programs/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchPrograms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Program created successfully')),
          );
        }
      } else {
        throw Exception('Failed to create program');
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

  Future<void> updateProgram(int id, Program program) async {
    setState(() => isLoading = true);

    try {
      final payload = program.toJson();

      final response = await http.put(
        Uri.parse('$apiBaseUrl/programs/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        await fetchPrograms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Program updated successfully')),
          );
        }
      } else {
        throw Exception('Failed to update program');
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

  Future<void> deleteProgram(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: const Text('Are you sure you want to delete this program?'),
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
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/programs/$id/'),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        setState(() => programs.removeWhere((p) => p.id == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Program deleted successfully')),
          );
        }
      } else {
        throw Exception('Failed to delete program');
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

  List<ProgramWithCalculatedStatus> get filteredPrograms {
    List<ProgramWithCalculatedStatus> filtered = programs
        .map((program) => ProgramWithCalculatedStatus.fromProgram(program))
        .toList();

    // Apply search filter
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((program) {
        final name = program.name.toLowerCase();
        final description = program.description.toLowerCase();
        final coordinator = program.coordinator.toLowerCase();
        final category = program.category?.toLowerCase() ?? '';
        final search = searchTerm.toLowerCase();
        return name.contains(search) ||
            description.contains(search) ||
            coordinator.contains(search) ||
            category.contains(search);
      }).toList();
    }

    // Apply category filter
    switch (activeFilter) {
      case 'active':
        filtered = filtered
            .where((p) => p.calculatedStatus == 'Active')
            .toList();
        break;
      case 'completed':
        filtered = filtered
            .where((p) => p.calculatedStatus == 'Completed')
            .toList();
        break;
      case 'upcoming':
        filtered = filtered
            .where((p) => p.calculatedStatus == 'Upcoming')
            .toList();
        break;
    }

    return filtered;
  }

  Map<String, int> get stats {
    final active = programs
        .where(
          (p) =>
              ProgramWithCalculatedStatus.fromProgram(p).calculatedStatus ==
              'Active',
        )
        .length;
    final completed = programs
        .where(
          (p) =>
              ProgramWithCalculatedStatus.fromProgram(p).calculatedStatus ==
              'Completed',
        )
        .length;
    final upcoming = programs
        .where(
          (p) =>
              ProgramWithCalculatedStatus.fromProgram(p).calculatedStatus ==
              'Upcoming',
        )
        .length;

    return {
      'total': programs.length,
      'active': active,
      'completed': completed,
      'upcoming': upcoming,
    };
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      case 'Upcoming':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String getStatusEmoji(String status) {
    switch (status) {
      case 'Active':
        return '🚀';
      case 'Completed':
        return '✅';
      case 'Upcoming':
        return '📅';
      default:
        return '📊';
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
                          Icons.event_available,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Programs Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Create, manage, and track all school programs',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateProgramDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Program'),
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
                        'Total Programs',
                        stats['total']!.toString(),
                        Icons.event_available,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Active',
                        stats['active']!.toString(),
                        Icons.access_time,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Completed',
                        stats['completed']!.toString(),
                        Icons.check_circle,
                        Colors.grey,
                      ),
                      _buildStatCard(
                        'Upcoming',
                        stats['upcoming']!.toString(),
                        Icons.calendar_today,
                        Colors.blue[700]!,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search and Filters
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
                            hintText: 'Search programs...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setState(() => searchTerm = value),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildFilterChip('All', 'all'),
                            _buildFilterChip('Active', 'active'),
                            _buildFilterChip('Completed', 'completed'),
                            _buildFilterChip('Upcoming', 'upcoming'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Programs Grid
                  if (filteredPrograms.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No programs found'),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 768
                            ? 3
                            : MediaQuery.of(context).size.width > 600
                            ? 2
                            : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredPrograms.length,
                      itemBuilder: (context, index) {
                        final program = filteredPrograms[index];
                        return _buildProgramCard(program);
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

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = activeFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => activeFilter = filter);
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildProgramCard(ProgramWithCalculatedStatus program) {
    return InkWell(
      onTap: () => _showProgramDetail(program),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge and Menu
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
                        program.calculatedStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getStatusColor(
                          program.calculatedStatus,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${getStatusEmoji(program.calculatedStatus)} ${program.calculatedStatus}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(program.calculatedStatus),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditProgramDialog(program);
                          break;
                        case 'delete':
                          deleteProgram(program.id!);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Program Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[100]!, Colors.purple[100]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 24)),
                ),
              ),

              const SizedBox(height: 12),

              // Program Name
              Text(
                program.name,
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
                  program.description,
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

              // Date Information
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${formatDate(program.startDate)} - ${formatDate(program.endDate)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Coordinator Info
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green[100],
                      child: const Text('👤', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.coordinator,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            program.coordinatorEmail,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Category and Budget
              if (program.category != null || program.budget != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (program.category != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              program.category!,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (program.category != null && program.budget != null)
                        const SizedBox(width: 8),
                      if (program.budget != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '\$${program.budget!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
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
    );
  }

  void _showCreateProgramDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateProgramDialog(),
    ).then((program) {
      if (program != null) {
        createProgram(program);
      }
    });
  }

  void _showEditProgramDialog(ProgramWithCalculatedStatus program) {
    showDialog(
      context: context,
      builder: (context) => EditProgramDialog(program: program),
    ).then((updatedProgram) {
      if (updatedProgram != null) {
        updateProgram(program.id!, updatedProgram);
      }
    });
  }

  void _showProgramDetail(ProgramWithCalculatedStatus program) {
    showDialog(
      context: context,
      builder: (context) => ProgramDetailDialog(program: program),
    );
  }
}

class CreateProgramDialog extends StatefulWidget {
  const CreateProgramDialog({super.key});

  @override
  State<CreateProgramDialog> createState() => _CreateProgramDialogState();
}

class _CreateProgramDialogState extends State<CreateProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coordinatorController = TextEditingController();
  final _coordinatorEmailController = TextEditingController();
  final _categoryController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'Planned';

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
                'Create New Program',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Program Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Program name is required';
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
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : 'Select date',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : 'Select date',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coordinatorController,
                decoration: const InputDecoration(
                  labelText: 'Coordinator Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true)
                    return 'Coordinator name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coordinatorEmailController,
                decoration: const InputDecoration(
                  labelText: 'Coordinator Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true)
                    return 'Coordinator email is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
                      if (_formKey.currentState!.validate() &&
                          _startDate != null &&
                          _endDate != null) {
                        final program = Program(
                          name: _nameController.text,
                          description: _descriptionController.text,
                          startDate: DateFormat(
                            'yyyy-MM-dd',
                          ).format(_startDate!),
                          endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
                          status: _status,
                          coordinator: _coordinatorController.text,
                          coordinatorEmail: _coordinatorEmailController.text,
                          category: _categoryController.text.isEmpty
                              ? null
                              : _categoryController.text,
                          budget: _budgetController.text.isEmpty
                              ? null
                              : double.tryParse(_budgetController.text),
                        );
                        Navigator.of(context).pop(program);
                      }
                    },
                    child: const Text('Create'),
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

class EditProgramDialog extends StatefulWidget {
  final ProgramWithCalculatedStatus program;

  const EditProgramDialog({super.key, required this.program});

  @override
  State<EditProgramDialog> createState() => _EditProgramDialogState();
}

class _EditProgramDialogState extends State<EditProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coordinatorController;
  late final TextEditingController _coordinatorEmailController;
  late final TextEditingController _categoryController;
  late final TextEditingController _budgetController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program.name);
    _descriptionController = TextEditingController(
      text: widget.program.description,
    );
    _coordinatorController = TextEditingController(
      text: widget.program.coordinator,
    );
    _coordinatorEmailController = TextEditingController(
      text: widget.program.coordinatorEmail,
    );
    _categoryController = TextEditingController(
      text: widget.program.category ?? '',
    );
    _budgetController = TextEditingController(
      text: widget.program.budget?.toString() ?? '',
    );
    _startDate = DateTime.parse(widget.program.startDate);
    _endDate = DateTime.parse(widget.program.endDate);
    _status = widget.program.status;
  }

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
                'Edit Program',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Program Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Program name is required';
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
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_startDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coordinatorController,
                decoration: const InputDecoration(
                  labelText: 'Coordinator Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true)
                    return 'Coordinator name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coordinatorEmailController,
                decoration: const InputDecoration(
                  labelText: 'Coordinator Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true)
                    return 'Coordinator email is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
                        final program = Program(
                          id: widget.program.id,
                          name: _nameController.text,
                          description: _descriptionController.text,
                          startDate: DateFormat(
                            'yyyy-MM-dd',
                          ).format(_startDate),
                          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
                          status: _status,
                          coordinator: _coordinatorController.text,
                          coordinatorEmail: _coordinatorEmailController.text,
                          category: _categoryController.text.isEmpty
                              ? null
                              : _categoryController.text,
                          budget: _budgetController.text.isEmpty
                              ? null
                              : double.tryParse(_budgetController.text),
                        );
                        Navigator.of(context).pop(program);
                      }
                    },
                    child: const Text('Update'),
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

class ProgramDetailDialog extends StatelessWidget {
  final ProgramWithCalculatedStatus program;

  const ProgramDetailDialog({super.key, required this.program});

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
              program.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (program.description.isNotEmpty) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(program.description),
              const SizedBox(height: 16),
            ],
            _buildInfoRow('Status', program.calculatedStatus),
            _buildInfoRow('Start Date', program.startDate),
            _buildInfoRow('End Date', program.endDate),
            _buildInfoRow('Coordinator', program.coordinator),
            _buildInfoRow('Coordinator Email', program.coordinatorEmail),
            if (program.category != null)
              _buildInfoRow('Category', program.category!),
            if (program.budget != null)
              _buildInfoRow(
                'Budget',
                '\$${program.budget!.toStringAsFixed(2)}',
              ),
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
