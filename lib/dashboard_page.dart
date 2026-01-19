import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final String userRole;
  final String userEmail;
  final String userName;

  const DashboardPage({
    super.key,
    required this.userRole,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _menuOpen = false;
  String _selectedMenuItem = 'Dashboard';

  // Role-based navigation items
  Map<String, List<Map<String, String>>> getRoleNavigation() {
    switch (widget.userRole.toLowerCase()) {
      case 'student':
      case 'students':
        return {
          'Student': [
            {'name': 'Dashboard', 'path': 'dashboard'},
            {'name': 'Attendance', 'path': 'attendance'},
            {'name': 'Marks', 'path': 'marks'},
            {'name': 'Assignments', 'path': 'assignments'},
            {'name': 'Tasks', 'path': 'tasks'},
            {'name': 'Online Test', 'path': 'online_test'},
            {'name': 'Calendar', 'path': 'calendar'},
            {'name': 'Notice', 'path': 'notice'},
            {'name': 'Programs', 'path': 'programs'},
            {'name': 'Reports', 'path': 'reports'},
            {'name': 'Leaves', 'path': 'leaves'},
            {'name': 'TimeTable', 'path': 'timetable'},
            {'name': 'Documents', 'path': 'documents'},
            {'name': 'Fees', 'path': 'fees'},
            {'name': 'ID Card', 'path': 'id_card'},
            {'name': 'Profile', 'path': 'profile'},
          ],
        };
      case 'teacher':
      case 'teachers':
        return {
          'Teacher': [
            {'name': 'Dashboard', 'path': 'dashboard'},
            {'name': 'Attendance', 'path': 'attendance'},
            {'name': 'Marks', 'path': 'marks'},
            {'name': 'Assignments', 'path': 'assignments'},
            {'name': 'Online Test', 'path': 'online_test'},
            {'name': 'Calendar', 'path': 'calendar'},
            {'name': 'Notice', 'path': 'notice'},
            {'name': 'Programs', 'path': 'programs'},
            {'name': 'Projects', 'path': 'projects'},
            {'name': 'Monthly Report', 'path': 'monthly_report'},
            {'name': 'Leaves', 'path': 'leaves'},
            {'name': 'Student Leaves', 'path': 'student_leaves'},
            {'name': 'Documents', 'path': 'documents'},
            {'name': 'ID Card', 'path': 'id_card'},
            {'name': 'Timetable', 'path': 'timetable'},
            {'name': 'Profile', 'path': 'profile'},
          ],
        };
      case 'admin':
        return {
          'Admin': [
            {'name': 'Dashboard', 'path': 'dashboard'},
            {'name': 'Attendance', 'path': 'attendance'},
            {'name': 'Students', 'path': 'students'},
            {'name': 'Teachers', 'path': 'teachers'},
            {'name': 'Approvals', 'path': 'approvals'},
            {'name': 'Calendar', 'path': 'calendar'},
            {'name': 'Notice', 'path': 'notice'},
            {'name': 'Programs', 'path': 'programs'},
            {'name': 'Reports', 'path': 'reports'},
            {'name': 'Projects', 'path': 'projects'},
            {'name': 'ID Card', 'path': 'id_card'},
            {'name': 'Profile', 'path': 'profile'},
          ],
        };
      case 'management':
        return {
          'Management': [
            {'name': 'Dashboard', 'path': 'dashboard'},
            {'name': 'Reports', 'path': 'reports'},
            {'name': 'Activities', 'path': 'activities'},
            {'name': 'Students', 'path': 'students'},
            {'name': 'Teachers', 'path': 'teachers'},
            {'name': 'Attendance', 'path': 'attendance'},
            {'name': 'Finance', 'path': 'finance'},
            {'name': 'Calendar', 'path': 'calendar'},
            {'name': 'Notice', 'path': 'notice'},
            {'name': 'Programs', 'path': 'programs'},
            {'name': 'Projects', 'path': 'projects'},
            {'name': 'Monthly Report', 'path': 'monthly_report'},
            {'name': 'Pending Fees', 'path': 'pending_fees'},
            {'name': 'Create Fee', 'path': 'create_fee'},
            {'name': 'Transport', 'path': 'transport'},
            {'name': 'ID Card', 'path': 'id_card'},
            {'name': 'Profile', 'path': 'profile'},
          ],
        };
      case 'principal':
        return {
          'Principal': [
            {'name': 'Dashboard', 'path': 'dashboard'},
            {'name': 'Reports', 'path': 'reports'},
            {'name': 'Activities', 'path': 'activities'},
            {'name': 'Students', 'path': 'students'},
            {'name': 'Teachers', 'path': 'teachers'},
            {'name': 'Attendance', 'path': 'attendance'},
            {'name': 'Calendar', 'path': 'calendar'},
            {'name': 'Notice', 'path': 'notice'},
            {'name': 'Programs', 'path': 'programs'},
            {'name': 'Projects', 'path': 'projects'},
            {'name': 'Monthly Report', 'path': 'monthly_report'},
            {'name': 'ID Card', 'path': 'id_card'},
            {'name': 'Timetable Creation', 'path': 'timetable_creation'},
            {'name': 'Profile', 'path': 'profile'},
          ],
        };
      case 'parent':
      case 'parents':
        return {
          'Parent': [
            {'name': 'Dashboard', 'path': 'dashboard'},
            {'name': 'Attendance', 'path': 'attendance'},
            {'name': 'Reports', 'path': 'reports'},
            {'name': 'Fees', 'path': 'fees'},
            {'name': 'Activities', 'path': 'activities'},
            {'name': 'Notices', 'path': 'notices'},
            {'name': 'Programs', 'path': 'programs'},
            {'name': 'Profile', 'path': 'profile'},
          ],
        };
      default:
        return {
          'User': [
            {'name': 'Dashboard', 'path': 'dashboard'},
            {'name': 'Profile', 'path': 'profile'},
          ],
        };
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    // Clear stored session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data

    print('Logging out user - session cleared');

    // Navigate back to login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildSidebar() {
    final navigation = getRoleNavigation();
    final roleName = navigation.keys.first;
    final menuItems = navigation[roleName]!;

    return Container(
      width: 280,
      color: Colors.blue[600],
      child: Column(
        children: [
          // Header with user info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.blue[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        roleName.toUpperCase(),
                        style: TextStyle(color: Colors.blue[100], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation menu
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _selectedMenuItem == item['name'];

                return ListTile(
                  leading: Icon(
                    _getMenuIcon(item['name']!),
                    color: isSelected ? Colors.white : Colors.blue[100],
                    size: 20,
                  ),
                  title: Text(
                    item['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue[100],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.blue[700],
                  onTap: () {
                    setState(() {
                      _selectedMenuItem = item['name']!;
                      _menuOpen = false;
                    });
                  },
                );
              },
            ),
          ),

          // Logout button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMenuIcon(String menuName) {
    switch (menuName.toLowerCase()) {
      case 'dashboard':
        return Icons.dashboard;
      case 'attendance':
        return Icons.check_circle;
      case 'marks':
        return Icons.grade;
      case 'assignments':
        return Icons.assignment;
      case 'tasks':
        return Icons.task;
      case 'online test':
        return Icons.quiz;
      case 'calendar':
        return Icons.calendar_today;
      case 'notice':
        return Icons.notifications;
      case 'programs':
        return Icons.event;
      case 'reports':
        return Icons.bar_chart;
      case 'leaves':
        return Icons.beach_access;
      case 'timetable':
        return Icons.schedule;
      case 'documents':
        return Icons.file_present;
      case 'fees':
        return Icons.payment;
      case 'id card':
        return Icons.badge;
      case 'profile':
        return Icons.person;
      case 'students':
        return Icons.school;
      case 'teachers':
        return Icons.person_3;
      case 'projects':
        return Icons.work;
      case 'finance':
        return Icons.account_balance;
      default:
        return Icons.circle;
    }
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Container(
        color:
            Colors.blue[600], // Blue background from top to hamburger container
        child: Column(
          children: [
            // Top Header Bar (like React)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Mobile menu button on left
                  if (MediaQuery.of(context).size.width < 768)
                    IconButton(
                      icon: const Icon(Icons.menu, size: 24),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),

                  // Title in center - using Flexible to prevent overflow
                  Flexible(
                    child: Center(
                      child: Text(
                        '${widget.userRole} Dashboard',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Empty space for balance (only on mobile)
                  if (MediaQuery.of(context).size.width < 768)
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome back, ${widget.userName}!',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                    const SizedBox(height: 24),

                    // Dashboard content based on selected menu
                    _buildSelectedContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedMenuItem.toLowerCase()) {
      case 'dashboard':
        return _buildDashboardContent();
      case 'profile':
        return _buildProfileContent();
      default:
        return Container(
          height: 400,
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getMenuIcon(_selectedMenuItem),
                  size: 64,
                  color: Colors.blue[200],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedMenuItem,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Content for $_selectedMenuItem will be displayed here',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Cards
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Attendance',
              '95%',
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard('Assignments', '12', Icons.assignment, Colors.blue),
            _buildStatCard(
              'Notifications',
              '3',
              Icons.notifications,
              Colors.orange,
            ),
            _buildStatCard('Messages', '7', Icons.message, Colors.purple),
          ],
        ),

        const SizedBox(height: 32),

        // Recent Activity
        Container(
          padding: const EdgeInsets.all(24),
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
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                'Assignment submitted',
                'Mathematics homework completed',
                '2 hours ago',
                Icons.assignment_turned_in,
                Colors.green,
              ),
              _buildActivityItem(
                'Attendance marked',
                'Present for Computer Science class',
                '1 day ago',
                Icons.check_circle,
                Colors.blue,
              ),
              _buildActivityItem(
                'New notice',
                'School holiday announcement',
                '2 days ago',
                Icons.notifications,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            'Profile Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileField('Name', widget.userName),
          _buildProfileField('Email', widget.userEmail),
          _buildProfileField('Role', widget.userRole),
          _buildProfileField('Status', 'Active'),
        ],
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

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigation = getRoleNavigation();
    final roleName = navigation.keys.first;

    return Scaffold(
      key: _scaffoldKey,
      drawer: MediaQuery.of(context).size.width < 768
          ? Drawer(child: _buildSidebar())
          : null,
      body: Row(
        children: [
          // Desktop Sidebar
          if (MediaQuery.of(context).size.width >= 768) _buildSidebar(),

          // Main Content
          _buildMainContent(),
        ],
      ),
    );
  }
}
