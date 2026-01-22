import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Notice {
  final int? id;
  final String? title;
  final String? message;
  final String? postedDate;
  final String? validUntil;
  final bool? important;
  final String? email;
  final String? noticeBy;
  final String? noticeTo;
  final String? type;
  final String? priority;
  final String? status;

  Notice({
    this.id,
    this.title,
    this.message,
    this.postedDate,
    this.validUntil,
    this.important,
    this.email,
    this.noticeBy,
    this.noticeTo,
    this.type,
    this.priority,
    this.status,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      postedDate: json['posted_date'],
      validUntil: json['valid_until'],
      important: json['important'] ?? false,
      email: json['email'],
      noticeBy: json['notice_by'],
      noticeTo: json['notice_to'],
      type: json['type'] ?? 'info',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'posted_date': postedDate,
      'valid_until': validUntil,
      'important': important,
      'email': email,
      'notice_by': noticeBy,
      'notice_to': noticeTo,
      'type': type,
      'priority': priority,
      'status': status,
    };
  }
}

class AdminNoticePage extends StatefulWidget {
  const AdminNoticePage({super.key});

  @override
  State<AdminNoticePage> createState() => _AdminNoticePageState();
}

class _AdminNoticePageState extends State<AdminNoticePage> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Notice> notices = [];
  bool isLoading = true;
  String? error;
  String userEmail = '';
  String searchTerm = '';
  String activeFilter = 'all'; // 'all', 'my', 'forme', 'important'

  final Map<String, Color> typeColors = {
    "info": Colors.blue,
    "warning": Colors.amber,
    "critical": Colors.red,
    "success": Colors.green,
  };

  final Map<String, Color> priorityColors = {
    "low": Colors.grey,
    "medium": Colors.blue,
    "high": Colors.red,
  };

  @override
  void initState() {
    super.initState();
    loadUserEmail();
    fetchNotices();
  }

  Future<void> loadUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => userEmail = prefs.getString('user_email') ?? '');
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> fetchNotices() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/notices/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => notices = data.map((e) => Notice.fromJson(e)).toList());
      } else {
        setState(() => error = 'Failed to load notices');
      }
    } catch (err) {
      setState(() => error = err.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> createNotice(Notice notice) async {
    setState(() => isLoading = true);

    try {
      final payload = {
        'title': notice.title,
        'message': notice.message,
        'posted_date':
            DateTime.now().toIso8601String().split('T')[0] +
            ' ' +
            DateTime.now().toIso8601String().split('T')[1].substring(0, 8),
        'valid_until': notice.validUntil?.isNotEmpty == true
            ? notice.validUntil!.replaceAll('T', ' ')
            : null,
        'important': notice.important,
        'email': userEmail,
        'notice_by': userEmail,
        'notice_to': notice.noticeTo?.isNotEmpty == true
            ? notice.noticeTo
            : null,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/notices/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchNotices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice created successfully')),
          );
        }
      } else {
        throw Exception('Failed to create notice');
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

  Future<void> deleteNotice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
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
      final response = await http.delete(Uri.parse('$apiBaseUrl/notices/$id/'));

      if (response.statusCode == 204 || response.statusCode == 200) {
        setState(() => notices.removeWhere((n) => n.id == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted successfully')),
          );
        }
      } else {
        throw Exception('Failed to delete notice');
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

  List<Notice> get filteredNotices {
    List<Notice> filtered = notices;

    // Apply search filter
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((notice) {
        final title = notice.title?.toLowerCase() ?? '';
        final message = notice.message?.toLowerCase() ?? '';
        final search = searchTerm.toLowerCase();
        return title.contains(search) || message.contains(search);
      }).toList();
    }

    // Apply category filter
    switch (activeFilter) {
      case 'my':
        filtered = filtered.where((n) => n.noticeBy == userEmail).toList();
        break;
      case 'forme':
        filtered = filtered
            .where(
              (n) =>
                  n.noticeTo == null ||
                  n.noticeTo == userEmail ||
                  n.noticeTo!.isEmpty,
            )
            .toList();
        break;
      case 'important':
        filtered = filtered.where((n) => n.important == true).toList();
        break;
    }

    return filtered;
  }

  List<Notice> get myNotices =>
      filteredNotices.where((n) => n.noticeBy == userEmail).toList();
  List<Notice> get noticesForMe => filteredNotices
      .where(
        (n) =>
            n.noticeTo == null ||
            n.noticeTo == userEmail ||
            n.noticeTo!.isEmpty,
      )
      .toList();

  Map<String, int> get stats {
    return {
      'total': notices.length,
      'myNotices': notices.where((n) => n.noticeBy == userEmail).length,
      'forMe': notices
          .where(
            (n) =>
                n.noticeTo == null ||
                n.noticeTo == userEmail ||
                n.noticeTo!.isEmpty,
          )
          .length,
      'important': notices.where((n) => n.important == true).length,
      'active': notices.where((n) => n.status == 'active').length,
    };
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
                          Icons.notifications,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notice Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Create, manage, and track all system notices',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateNoticeDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Notice'),
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
                        'Total Notices',
                        stats['total']!.toString(),
                        Icons.notifications,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'My Notices',
                        stats['myNotices']!.toString(),
                        Icons.person,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'For Me',
                        stats['forMe']!.toString(),
                        Icons.people,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Important',
                        stats['important']!.toString(),
                        Icons.star,
                        Colors.orange,
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
                            hintText: 'Search notices...',
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
                            _buildFilterChip('My Notices', 'my'),
                            _buildFilterChip('For Me', 'forme'),
                            _buildFilterChip('Important', 'important'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notices Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isLargeScreen = constraints.maxWidth > 768;
                      return isLargeScreen
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildNoticeColumn(
                                    'My Notices',
                                    myNotices,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildNoticeColumn(
                                    'Notices For Me',
                                    noticesForMe,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildNoticeColumn('My Notices', myNotices),
                                const SizedBox(height: 16),
                                _buildNoticeColumn(
                                  'Notices For Me',
                                  noticesForMe,
                                ),
                              ],
                            );
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

  Widget _buildNoticeColumn(String title, List<Notice> notices) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (notices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No notices found'),
              ),
            )
          else
            ...notices.map((notice) => _buildNoticeCard(notice)),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice) {
    return InkWell(
      onTap: () => _showNoticeDetail(notice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.important == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Important',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _showNoticeDetail(notice);
                        break;
                      case 'delete':
                        deleteNotice(notice.id!);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'view', child: Text('View')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (notice.title?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                notice.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (notice.message?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                notice.message!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  notice.postedDate != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.parse(notice.postedDate!))
                      : 'Unknown date',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                if (notice.noticeBy?.isNotEmpty == true)
                  Text(
                    'By: ${notice.noticeBy!.split('@')[0]}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateNoticeDialog(),
    ).then((notice) {
      if (notice != null) {
        createNotice(notice);
      }
    });
  }

  void _showNoticeDetail(Notice notice) {
    showDialog(
      context: context,
      builder: (context) => NoticeDetailDialog(notice: notice),
    );
  }
}

class CreateNoticeDialog extends StatefulWidget {
  const CreateNoticeDialog({super.key});

  @override
  State<CreateNoticeDialog> createState() => _CreateNoticeDialogState();
}

class _CreateNoticeDialogState extends State<CreateNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _noticeToController = TextEditingController();
  DateTime? _validUntil;
  String _type = 'info';
  String _priority = 'medium';
  bool _important = false;

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
                'Create New Notice',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Message is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'info', child: Text('Info')),
                        DropdownMenuItem(
                          value: 'warning',
                          child: Text('Warning'),
                        ),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text('Critical'),
                        ),
                        DropdownMenuItem(
                          value: 'success',
                          child: Text('Success'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (value) => setState(() => _priority = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noticeToController,
                decoration: const InputDecoration(
                  labelText: 'Notice To (optional)',
                  hintText: 'Leave empty for all users',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _validUntil = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Valid Until (optional)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _validUntil != null
                        ? DateFormat('yyyy-MM-dd').format(_validUntil!)
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Mark as Important'),
                value: _important,
                onChanged: (value) =>
                    setState(() => _important = value ?? false),
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
                        final notice = Notice(
                          title: _titleController.text,
                          message: _messageController.text,
                          validUntil: _validUntil?.toIso8601String(),
                          important: _important,
                          noticeTo: _noticeToController.text.isEmpty
                              ? null
                              : _noticeToController.text,
                          type: _type,
                          priority: _priority,
                        );
                        Navigator.of(context).pop(notice);
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

class NoticeDetailDialog extends StatelessWidget {
  final Notice notice;

  const NoticeDetailDialog({super.key, required this.notice});

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
              notice.title ?? 'Notice Details',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (notice.message?.isNotEmpty == true) ...[
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(notice.message!),
              const SizedBox(height: 16),
            ],
            _buildInfoRow(
              'Posted Date',
              notice.postedDate != null
                  ? DateFormat(
                      'MMM dd, yyyy',
                    ).format(DateTime.parse(notice.postedDate!))
                  : 'Unknown',
            ),
            _buildInfoRow('Notice By', notice.noticeBy ?? 'Unknown'),
            _buildInfoRow('Notice To', notice.noticeTo ?? 'All Users'),
            _buildInfoRow('Valid Until', notice.validUntil ?? 'Not specified'),
            _buildInfoRow('Important', notice.important == true ? 'Yes' : 'No'),
            _buildInfoRow('Type', notice.type ?? 'Info'),
            _buildInfoRow('Priority', notice.priority ?? 'Medium'),
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
