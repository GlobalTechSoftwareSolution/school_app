import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String email;
  final String role;
  final bool isStaff;
  final bool? isSuperuser;
  final bool isActive;
  final bool isApproved;
  final String? lastLogin;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.email,
    required this.role,
    required this.isStaff,
    this.isSuperuser,
    required this.isActive,
    required this.isApproved,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] is String ? json['email'] : '',
      role: json['role'] is String ? json['role'] : 'Unknown',
      isStaff: json['is_staff'] is bool ? json['is_staff'] : false,
      isSuperuser: json['is_superuser'] is bool ? json['is_superuser'] : null,
      isActive: json['is_active'] is bool ? json['is_active'] : false,
      isApproved: json['is_approved'] is bool ? json['is_approved'] : false,
      lastLogin: json['last_login'] is String ? json['last_login'] : null,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['updated_at'] is String ? json['updated_at'] : null,
    );
  }
}

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<User> users = [];
  bool loading = true;
  String? error;
  User? selectedUser;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    debugPrint(
      'AdminApprovalPage: Retrieved token: ${token != null ? 'Present' : 'NULL'}',
    );
    debugPrint('AdminApprovalPage: Token value: $token');
    return token;
  }

  Future<void> fetchUsers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await _getToken();

      // Try with authentication first
      var response = await http.get(
        Uri.parse('$apiBaseUrl/users/'),
        headers: token != null
            ? {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json'},
      );

      debugPrint(
        'AdminApprovalPage: API call made with ${token != null ? 'token' : 'no token'}',
      );
      debugPrint('AdminApprovalPage: Response status: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Server error: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      final List<dynamic> data = jsonDecode(response.body);
      final List<User> userList = data.map((e) => User.fromJson(e)).toList();

      // Filter out rejected users (if we had a local storage mechanism)
      // For now, we'll just use all users
      debugPrint('AdminApprovalPage: Total users loaded: ${userList.length}');
      debugPrint(
        'AdminApprovalPage: Pending users: ${userList.where((u) => !u.isApproved).length}',
      );
      debugPrint(
        'AdminApprovalPage: Approved users: ${userList.where((u) => u.isApproved).length}',
      );
      setState(() => users = userList);
    } catch (err) {
      setState(() => error = err.toString());
      setState(() => users = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> handleApprove(String email) async {
    try {
      final token = await _getToken();

      final response = await http.patch(
        Uri.parse('$apiBaseUrl/users/${Uri.encodeComponent(email)}/'),
        headers: token != null
            ? {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json'},
        body: jsonEncode({'is_approved': true}),
      );

      debugPrint(
        'AdminApprovalPage: Approve API call made with ${token != null ? 'token' : 'no token'}',
      );
      debugPrint(
        'AdminApprovalPage: Approve response status: ${response.statusCode}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      // Parse response if needed
      if (response.body.isNotEmpty) {
        jsonDecode(response.body);
      }
      fetchUsers(); // Refresh the list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved successfully')),
      );
    } catch (err) {
      debugPrint('AdminApprovalPage: Approve error: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve user: ${err.toString()}')),
      );
    }
  }

  Future<void> handleReject(String email) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/users/${Uri.encodeComponent(email)}/'),
        headers: token != null
            ? {'Authorization': 'Bearer $token'}
            : {'Content-Type': 'application/json'},
      );

      debugPrint(
        'AdminApprovalPage: Reject API call made with ${token != null ? 'token' : 'no token'}',
      );
      debugPrint(
        'AdminApprovalPage: Reject response status: ${response.statusCode}',
      );

      if (response.statusCode == 204) {
        setState(() {
          users = users.where((u) => u.email != email).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User rejected successfully')),
        );
      } else {
        throw Exception('Failed to reject user (${response.statusCode})');
      }
    } catch (err) {
      debugPrint('AdminApprovalPage: Reject error: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject user: ${err.toString()}')),
      );
    }
  }

  List<User> get pendingUsers => users.where((u) => !u.isApproved).toList();
  List<User> get approvedUsers => users.where((u) => u.isApproved).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 1200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: Text(
                  'User Management',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            // Loading State
            if (loading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading users...'),
                  ],
                ),
              ),

            // Error State
            if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: fetchUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // No Users State
            if (!loading && users.isEmpty && error == null)
              const Center(child: Text('No users found.')),

            // Pending Approval Section
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Approval',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  pendingUsers.isEmpty
                      ? const Text(
                          'No users pending approval.',
                          style: TextStyle(color: Colors.grey),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                mainAxisSpacing: 8,
                                childAspectRatio: 8,
                              ),
                          itemCount: pendingUsers.length,
                          itemBuilder: (context, index) {
                            final user = pendingUsers[index];
                            return InkWell(
                              onTap: () => _showUserDetails(user),
                              child: Container(
                                height: 60,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue[100],
                                      child: Text(
                                        user.email.isNotEmpty
                                            ? user.email[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            user.role,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            // Approved Users Section
            Container(
              margin: const EdgeInsets.only(top: 40, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approved Users',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  approvedUsers.isEmpty
                      ? const Text(
                          'No approved users.',
                          style: TextStyle(color: Colors.grey),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                mainAxisSpacing: 8,
                                childAspectRatio: 8,
                              ),
                          itemCount: approvedUsers.length,
                          itemBuilder: (context, index) {
                            final user = approvedUsers[index];
                            return InkWell(
                              onTap: () => _showUserDetails(user),
                              child: Container(
                                height: 60,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.green[100],
                                      child: Text(
                                        user.email.isNotEmpty
                                            ? user.email[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            user.role,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Approved',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // User content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Avatar and Basic Info
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: user.isApproved
                                  ? Colors.green[100]
                                  : Colors.blue[100],
                              child: Text(
                                user.email.isNotEmpty
                                    ? user.email[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: user.isApproved
                                      ? Colors.green
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: user.isApproved
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.isApproved
                                    ? 'Approved'
                                    : 'Pending Approval',
                                style: TextStyle(
                                  color: user.isApproved
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Detailed Information
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow('Email', user.email),
                      _buildDetailRow('Role', user.role),
                      _buildDetailRow(
                        'Staff Member',
                        user.isStaff ? 'Yes' : 'No',
                      ),
                      _buildDetailRow(
                        'Superuser',
                        user.isSuperuser == true ? 'Yes' : 'No',
                      ),
                      _buildDetailRow('Active', user.isActive ? 'Yes' : 'No'),
                      _buildDetailRow(
                        'Approved',
                        user.isApproved ? 'Yes' : 'No',
                      ),

                      if (user.createdAt != null)
                        _buildDetailRow('Created', user.createdAt!),

                      if (user.updatedAt != null)
                        _buildDetailRow('Last Updated', user.updatedAt!),

                      if (user.lastLogin != null)
                        _buildDetailRow('Last Login', user.lastLogin!),

                      const SizedBox(height: 32),

                      // Action Buttons (only for pending users)
                      if (!user.isApproved) ...[
                        const Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  handleApprove(user.email);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Approve User'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  handleReject(user.email);
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Reject User'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
