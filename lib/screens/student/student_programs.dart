import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Program {
  final int id;
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
    required this.id,
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
      id: json['id'] ?? 0,
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

class StudentProgramsPage extends StatefulWidget {
  const StudentProgramsPage({super.key});

  @override
  State<StudentProgramsPage> createState() => _StudentProgramsPageState();
}

class _StudentProgramsPageState extends State<StudentProgramsPage> {
  List<Program> programs = [];
  List<ProgramWithCalculatedStatus> filteredPrograms = [];
  bool isLoading = true;
  String? error;
  bool isRefreshing = false;
  String selectedStatus = 'all';
  final TextEditingController searchController = TextEditingController();

  String get searchTerm => searchController.text;

  @override
  void initState() {
    super.initState();
    fetchPrograms();
  }

  Future<void> fetchPrograms() async {
    try {
      setState(() {
        if (!isRefreshing) isLoading = true;
        error = null;
      });

      final response = await http.get(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/programs/',
        ),
      );

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to fetch programs: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final programsList = (data is List ? data : [])
          .map((p) => Program.fromJson(p))
          .toList();

      setState(() {
        programs = programsList;
        _filterPrograms();
      });
    } catch (e) {
      setState(() {
        error = 'Could not load programs: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> handleRefresh() async {
    setState(() => isRefreshing = true);
    await fetchPrograms();
  }

  void _filterPrograms() {
    List<ProgramWithCalculatedStatus> filtered = programs
        .map((program) => ProgramWithCalculatedStatus.fromProgram(program))
        .toList();

    // Filter by status
    if (selectedStatus != 'all') {
      filtered = filtered
          .where((program) => program.calculatedStatus == selectedStatus)
          .toList();
    }

    // Filter by search term
    if (searchTerm.isNotEmpty) {
      filtered = filtered
          .where(
            (program) =>
                program.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                program.description.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
                program.coordinator.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
                (program.category?.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    setState(() => filteredPrograms = filtered);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  int getDaysRemaining(String endDate) {
    try {
      final end = DateTime.parse(endDate);
      final today = DateTime.now();
      final difference = end.difference(today).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '🎯 School Programs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: handleRefresh,
                icon: Icon(
                  isRefreshing ? Icons.refresh : Icons.refresh_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Discover and participate in various educational programs and activities',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Total Programs',
                stats['total']!.toString(),
                Icons.groups,
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
        ),

        const SizedBox(height: 24),

        // Search and Filters
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
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search programs by name, description, or coordinator...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => _filterPrograms(),
                ),

                const SizedBox(height: 16),

                // Status Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterButton('🚀 Active', 'Active'),
                      const SizedBox(width: 8),
                      _buildFilterButton('✅ Completed', 'Completed'),
                      const SizedBox(width: 8),
                      _buildFilterButton('📅 Upcoming', 'Upcoming'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Error Display
        if (error != null && programs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Programs Grid
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null && programs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to Load Programs',
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
                    onPressed: fetchPrograms,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        else if (filteredPrograms.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    programs.isEmpty
                        ? 'No Programs Available'
                        : 'No Matching Programs Found',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    programs.isEmpty
                        ? 'There are no programs scheduled at the moment.'
                        : 'Try adjusting your search terms or filters.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (searchTerm.isNotEmpty || selectedStatus != 'all')
                    ElevatedButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() => selectedStatus = 'all');
                        _filterPrograms();
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
            itemCount: filteredPrograms.length,
            itemBuilder: (context, index) {
              final program = filteredPrograms[index];
              final daysRemaining = getDaysRemaining(program.endDate);

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
                      // Status Badge
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
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
                      ),

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
                        child: Column(
                          children: [
                            Row(
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
                            if (program.calculatedStatus == 'Active' &&
                                daysRemaining > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$daysRemaining days remaining',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

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
                              child: const Text(
                                '👤',
                                style: TextStyle(fontSize: 12),
                              ),
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

                      // Bottom Info (Category and Budget)
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
                              if (program.category != null &&
                                  program.budget != null)
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
              );
            },
          ),

        // Results Summary
        if (filteredPrograms.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${filteredPrograms.length} of ${programs.length} programs${(searchTerm.isNotEmpty || selectedStatus != 'all') ? ' (filtered)' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active: ${stats['active']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed: ${stats['completed']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
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
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String status) {
    final isSelected = selectedStatus == status;
    return ElevatedButton(
      onPressed: () {
        setState(() => selectedStatus = status);
        _filterPrograms();
      },
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
}
