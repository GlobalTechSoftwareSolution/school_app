import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Notice {
  final int id;
  final String title;
  final String message;
  final String type;
  final String postedDate;
  final bool important;
  final String noticeBy;
  final String category;
  final String noticeTo;
  final String noticeToEmail;

  Notice({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.postedDate,
    required this.important,
    required this.noticeBy,
    required this.category,
    required this.noticeTo,
    required this.noticeToEmail,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Notice',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      postedDate: json['posted_date'] ?? '',
      important: json['important'] ?? false,
      noticeBy: json['notice_by'] ?? 'Admin',
      category: json['category'] ?? 'General',
      noticeTo: json['notice_to'] ?? '',
      noticeToEmail: json['notice_to_email'] ?? '',
    );
  }
}

class StudentNoticePage extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const StudentNoticePage({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<StudentNoticePage> createState() => _StudentNoticePageState();
}

class _StudentNoticePageState extends State<StudentNoticePage> {
  List<Notice> notices = [];
  bool isLoading = true;
  String? error;
  final TextEditingController searchController = TextEditingController();
  String typeFilter = 'all';
  String priorityFilter = 'all';

  String get searchTerm => searchController.text;

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Get user email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? widget.userEmail;

      if (userEmail.isEmpty) {
        throw Exception('User email not found');
      }

      final response = await http.get(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/notices/',
        ),
      );

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to fetch notices: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      // Filter notices that are specifically addressed to this user
      final filteredData = (data is List ? data : []).where((notice) {
        final noticeTo = (notice['notice_to'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        return noticeTo == userEmail.toLowerCase();
      }).toList();

      setState(() {
        notices = filteredData.map((n) => Notice.fromJson(n)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load notices: $e';
        isLoading = false;
      });
    }
  }

  List<Notice> get filteredNotices {
    return notices.where((notice) {
      final matchesType = typeFilter == 'all' || notice.type == typeFilter;
      final matchesPriority =
          priorityFilter == 'all' ||
          (priorityFilter == 'high' && notice.important) ||
          (priorityFilter == 'low' && !notice.important);
      final matchesSearch =
          searchTerm.isEmpty ||
          notice.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          notice.message.toLowerCase().contains(searchTerm.toLowerCase()) ||
          notice.noticeBy.toLowerCase().contains(searchTerm.toLowerCase());

      return matchesType && matchesPriority && matchesSearch;
    }).toList();
  }

  void clearFilters() {
    setState(() {
      typeFilter = 'all';
      priorityFilter = 'all';
      searchController.clear();
    });
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return Colors.blue;
      case 'update':
        return Colors.purple;
      case 'security':
        return Colors.red;
      case 'general':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
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
                '📢 Notice Board',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredNotices.length} notices',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Stay updated with important announcements and notices',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),

        const SizedBox(height: 24),

        // Search and Clear Filters
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search notices...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: clearFilters,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // On small screens, stack vertically
                    if (constraints.maxWidth < 600) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Filter by type: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: typeFilter,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All Types'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'general',
                                      child: Text('General'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'maintenance',
                                      child: Text('Maintenance'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'update',
                                      child: Text('Update'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'security',
                                      child: Text('Security'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => typeFilter = value ?? 'all',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Priority: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: priorityFilter,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All Priorities'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'high',
                                      child: Text('High'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'low',
                                      child: Text('Low'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => priorityFilter = value ?? 'all',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // On larger screens, keep horizontal layout
                      return Row(
                        children: [
                          const Text(
                            'Filter by type: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: typeFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Types'),
                              ),
                              DropdownMenuItem(
                                value: 'general',
                                child: Text('General'),
                              ),
                              DropdownMenuItem(
                                value: 'maintenance',
                                child: Text('Maintenance'),
                              ),
                              DropdownMenuItem(
                                value: 'update',
                                child: Text('Update'),
                              ),
                              DropdownMenuItem(
                                value: 'security',
                                child: Text('Security'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => typeFilter = value ?? 'all'),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Priority: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: priorityFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Priorities'),
                              ),
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High'),
                              ),
                              DropdownMenuItem(
                                value: 'low',
                                child: Text('Low'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => priorityFilter = value ?? 'all'),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Notices List
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
                  Text(
                    error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchNotices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (filteredNotices.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notices found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchTerm.isNotEmpty ||
                            typeFilter != 'all' ||
                            priorityFilter != 'all'
                        ? 'Try adjusting your filters'
                        : 'No notices have been posted for you yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredNotices.length,
            itemBuilder: (context, index) {
              final notice = filteredNotices[index];
              final priority = notice.important ? 'high' : 'low';

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                  border: Border(
                    left: BorderSide(
                      color: getPriorityColor(priority),
                      width: 4,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with type and priority
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getTypeColor(notice.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: getTypeColor(notice.type).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            notice.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: getTypeColor(notice.type),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getPriorityColor(priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: getPriorityColor(
                                priority,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: getPriorityColor(priority),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Message
                    Text(
                      notice.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Footer with author and date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Posted by: ${notice.noticeBy}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatDate(notice.postedDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),

                    // Category and recipient info
                    if (notice.category.isNotEmpty ||
                        notice.noticeToEmail.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (notice.category.isNotEmpty)
                              Text(
                                '📁 ${notice.category}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            if (notice.category.isNotEmpty &&
                                notice.noticeToEmail.isNotEmpty)
                              const SizedBox(width: 12),
                            if (notice.noticeToEmail.isNotEmpty)
                              Expanded(
                                child: Text(
                                  '🎯 To: ${notice.noticeToEmail}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
