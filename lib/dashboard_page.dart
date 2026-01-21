import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/student/attendance_page.dart';
import 'screens/student/student_marks_page.dart';
import 'screens/student/student_assignments_page.dart';
import 'screens/student/student_tasks_page.dart';
import 'screens/student/student_online_test_page.dart';
import 'screens/components/google_calendar_page.dart';
import 'screens/student/student_notice.dart';
import 'screens/student/student_programs.dart';
import 'screens/student/student_reports.dart';
import 'screens/student/student_leaves.dart';
import 'screens/student/student_raise_issue.dart';
import 'screens/student/student_timetable.dart';
import 'screens/student/student_documents_page.dart';
import 'screens/student/student_fees_page.dart';
import 'screens/student/student_id.dart';
import 'screens/student/student_profile.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_attendance_page.dart';
import 'screens/management/management_dashboard.dart';
import 'screens/principal/principal_dashboard.dart';
import 'screens/parent/parent_dashboard.dart';

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
  bool _sidebarVisible = false;
  String _selectedMenuItem = 'Dashboard';
  bool _isLoading = false;

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
            {'name': 'Raise Issue', 'path': 'raise_issue'},
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
            margin: const EdgeInsets.only(
              left: 16,
              top: 12,
              right: 16,
              bottom: 0,
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
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
                Column(
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
              ],
            ),
          ),

          // Separator line
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: Colors.blue[700],
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
                    size: 24,
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
                  onTap: () async {
                    setState(() {
                      _isLoading = true;
                      _sidebarVisible = false;
                    });
                    if (MediaQuery.of(context).size.width < 768) {
                      Navigator.of(context).pop();
                    }
                    await Future.delayed(const Duration(milliseconds: 500));
                    setState(() {
                      _selectedMenuItem = item['name']!;
                      _isLoading = false;
                    });
                  },
                );
              },
            ),
          ),

          // Logout button with additional bottom padding and margin
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            margin: const EdgeInsets.only(bottom: 20),
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
      case 'raise_issue':
        return Icons.report_problem;
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
        color: const Color(0xFFF5F5F5), // Default background
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
                  // Hamburger menu button
                  IconButton(
                    icon: const Icon(Icons.menu, size: 24),
                    onPressed: () {
                      if (MediaQuery.of(context).size.width < 768) {
                        _scaffoldKey.currentState?.openDrawer();
                      } else {
                        setState(() => _sidebarVisible = !_sidebarVisible);
                      }
                    },
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

                  // Empty space for balance
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome back, ${widget.userName}!',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // Dashboard content based on selected menu
                    const SizedBox(height: 16),
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
    if (_isLoading) {
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedMenuItem.toLowerCase()) {
      case 'dashboard':
        return _getRoleBasedDashboard();
      case 'attendance':
        if (widget.userRole.toLowerCase() == 'admin') {
          return const AdminAttendancePage();
        } else {
          return AttendancePage(
            userEmail: widget.userEmail,
            userRole: widget.userRole,
          );
        }
      case 'marks':
        return StudentMarksPage(
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        );
      case 'assignments':
        return StudentAssignmentsPage(
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        );
      case 'tasks':
        return StudentTasksPage(
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        );
      case 'online test':
        return StudentOnlineTestPage(
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        );
      case 'calendar':
        return const GoogleCalendarPage();
      case 'notice':
        return StudentNoticePage(
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        );
      case 'programs':
        return const StudentProgramsPage();
      case 'reports':
        return const StudentReportsPage();
      case 'leaves':
        return const StudentLeavesPage();
      case 'raise issue':
        return const StudentRaiseIssuePage();
      case 'timetable':
        return const StudentTimetablePage();
      case 'documents':
        return const StudentDocumentsPage();
      case 'fees':
        return const StudentFeesPage();
      case 'id card':
        return const StudentIdPage();
      case 'profile':
        return const StudentProfilePage();
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

  Widget _getRoleBasedDashboard() {
    final role = widget.userRole.toLowerCase();
    if (role == 'student' || role == 'students') {
      return StudentDashboard(
        onNavigate: (page) {
          setState(() {
            _selectedMenuItem = page;
          });
        },
      );
    } else if (role == 'teacher' || role == 'teachers') {
      return const TeacherDashboard();
    } else if (role == 'admin') {
      return const AdminDashboard();
    } else if (role == 'management') {
      return const ManagementDashboard();
    } else if (role == 'principal') {
      return const PrincipalDashboard();
    } else if (role == 'parent' || role == 'parents') {
      return const ParentDashboard();
    } else {
      // Default dashboard for unrecognized roles
      return _buildDefaultDashboard();
    }
  }

  Widget _buildDefaultDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard('Welcome', 'Hello!', Icons.waving_hand, Colors.blue),
            _buildStatCard('Dashboard', 'Ready', Icons.dashboard, Colors.green),
          ],
        ),
        const SizedBox(height: 32),
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
          child: const Center(
            child: Text(
              'Welcome to your Dashboard',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
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
    Color color, {
    Color bgColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
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

  Widget _buildStudentStatCard(
    String title,
    String value,
    String emoji,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink(String title, String emoji, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(
    String title,
    String message,
    String priority,
    String author,
    String time,
  ) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: priorityColor.withOpacity(0.3)),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By: $author',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
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

  @override
  Widget build(BuildContext context) {
    final navigation = getRoleNavigation();
    final roleName = navigation.keys.first;

    return Scaffold(
      key: _scaffoldKey,
      drawer: MediaQuery.of(context).size.width < 768
          ? Drawer(child: _buildSidebar())
          : null,
      body: SafeArea(
        child: Row(
          children: [
            // Desktop Sidebar with animation
            if (MediaQuery.of(context).size.width >= 768)
              AnimatedContainer(
                width: _sidebarVisible ? 280 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _sidebarVisible ? _buildSidebar() : const SizedBox(),
              ),

            // Main Content
            _buildMainContent(),
          ],
        ),
      ),
    );
  }
}
