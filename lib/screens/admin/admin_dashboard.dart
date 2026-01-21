import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../student/attendance_page.dart';
import '../student/student_profile.dart' as student_profile;
import '../teacher/teacher_dashboard.dart';
import '../student/student_reports.dart';
import 'admin_attendance_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  Map<String, dynamic> stats = {
    'totalStudents': 0,
    'totalTeachers': 0,
    'totalClasses': 0,
    'presentToday': 0,
    'absentToday': 0,
    'totalLeaves': 0,
    'pendingLeaves': 0,
    'totalReports': 0,
  };

  List<Map<String, dynamic>> attendanceData = [];
  List<Map<String, dynamic>> classDistribution = [];
  List<Map<String, dynamic>> recentActivity = [];
  bool loading = true;
  String adminEmail = '';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    loadAdminEmail();
  }

  Future<void> loadAdminEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';
      setState(() => adminEmail = email);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      setState(() => loading = true);

      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/students/')),
        http.get(Uri.parse('$apiBaseUrl/teachers/')),
        http.get(Uri.parse('$apiBaseUrl/classes/')),
        http.get(Uri.parse('$apiBaseUrl/attendance/')),
        http.get(Uri.parse('$apiBaseUrl/leaves/')),
        http.get(Uri.parse('$apiBaseUrl/reports/')),
      ]);

      final students = jsonDecode(responses[0].body) as List<dynamic>;
      final teachers = jsonDecode(responses[1].body) as List<dynamic>;
      final classes = jsonDecode(responses[2].body) as List<dynamic>;
      final attendance = jsonDecode(responses[3].body) as List<dynamic>;
      final leaves = jsonDecode(responses[4].body) as List<dynamic>;
      final reports = jsonDecode(responses[5].body) as List<dynamic>;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayAttendance = attendance
          .where((a) => a['date'] == today)
          .toList();
      final presentToday = todayAttendance
          .where((a) => a['status'] == 'Present')
          .length;

      setState(() {
        stats = {
          'totalStudents': students.length,
          'totalTeachers': teachers.length,
          'totalClasses': classes.length,
          'presentToday': presentToday,
          'absentToday': todayAttendance.length - presentToday,
          'totalLeaves': leaves.length,
          'pendingLeaves': leaves.where((l) => l['status'] == 'Pending').length,
          'totalReports': reports.length,
        };
      });

      final classData = classes.map((cls) {
        final studentCount = students
            .where((s) => s['class_id'] == cls['id'])
            .length;
        return {
          'name': '${cls['class_name']} - ${cls['sec'] ?? ''}',
          'students': studentCount,
          'teacher': cls['class_teacher_name'] ?? 'N/A',
        };
      }).toList();
      setState(() => classDistribution = classData);

      final last7Days = List.generate(7, (i) {
        final date = DateTime.now().subtract(Duration(days: 6 - i));
        return DateFormat('yyyy-MM-dd').format(date);
      });

      final trendData = last7Days.map((date) {
        final dayAttendance = attendance
            .where((a) => a['date'] == date)
            .toList();
        final present = dayAttendance
            .where((a) => a['status'] == 'Present')
            .length;
        final absent = dayAttendance
            .where((a) => a['status'] == 'Absent')
            .length;

        return {
          'date': DateFormat('MMM dd').format(DateTime.parse(date)),
          'present': present,
          'absent': absent,
          'total': dayAttendance.length,
        };
      }).toList();
      setState(() => attendanceData = trendData);

      final sortedAttendance =
          attendance.where((a) => a['date'] != null).toList()..sort(
            (a, b) =>
                DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
          );

      final activity = sortedAttendance.take(8).map((record) {
        return {
          'id': record['id'],
          'name': record['user_name'] ?? record['user_email'] ?? 'Unknown',
          'action': record['status'] == 'Present'
              ? 'Checked in'
              : 'Marked absent',
          'time': '${record['date']} ${record['check_in'] ?? ''}'.trim(),
          'type': record['status'].toString().toLowerCase(),
          'avatar': _getInitials(
            record['user_name'] ?? record['user_email'] ?? 'Unknown',
          ),
        };
      }).toList();

      setState(() => recentActivity = activity);
    } catch (error) {
      debugPrint('Error fetching dashboard data: $error');
    } finally {
      setState(() => loading = false);
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back, ${adminEmail.isNotEmpty ? adminEmail : 'Admin'}!',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Students',
                stats['totalStudents'].toString(),
                '👨‍🎓',
                Colors.blue,
                '+12%',
              ),
              _buildStatCard(
                'Total Teachers',
                stats['totalTeachers'].toString(),
                '👨‍🏫',
                Colors.green,
                '+8%',
              ),
              _buildStatCard(
                'Classes',
                stats['totalClasses'].toString(),
                '🏫',
                Colors.purple,
                '+2',
              ),
              _buildStatCard(
                'Present Today',
                stats['presentToday'].toString(),
                '✅',
                Colors.teal,
                '${stats['absentToday']} absent',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Additional Stats
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Leaves',
                stats['totalLeaves'].toString(),
                '📝',
                Colors.blue,
                '${stats['pendingLeaves']} pending',
              ),
              _buildStatCard(
                'Total Reports',
                stats['totalReports'].toString(),
                '📊',
                Colors.green,
                'Generated',
              ),
              if (MediaQuery.of(context).size.width > 768)
                _buildStatCard(
                  'Attendance Rate',
                  stats['totalStudents'] > 0
                      ? '${((stats['presentToday'] / (stats['presentToday'] + stats['absentToday'])) * 100).round()}%'
                      : '0%',
                  '📈',
                  Colors.orange,
                  'Today',
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Charts Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 768;
              return isLargeScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildAttendanceChart()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildClassDistributionChart()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildAttendanceChart(),
                        const SizedBox(height: 16),
                        _buildClassDistributionChart(),
                      ],
                    );
            },
          ),

          const SizedBox(height: 24),

          // Recent Activity and Quick Actions
          LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 768;
              return isLargeScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildRecentActivity()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildQuickActions()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildRecentActivity(),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Container(
      height: 300,
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
          const Text(
            'Attendance Trend (Last 7 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < attendanceData.length) {
                          return Text(
                            attendanceData[value.toInt()]['date'],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: attendanceData
                        .asMap()
                        .entries
                        .map(
                          (entry) => FlSpot(
                            entry.key.toDouble(),
                            entry.value['present'].toDouble(),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: attendanceData
                        .asMap()
                        .entries
                        .map(
                          (entry) => FlSpot(
                            entry.key.toDouble(),
                            entry.value['absent'].toDouble(),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDistributionChart() {
    return Container(
      height: 350,
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
          const Text(
            'Class Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: classDistribution.isNotEmpty
                    ? classDistribution.length * 70.0
                    : 300, // Minimum width for empty state
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: classDistribution.isNotEmpty
                        ? classDistribution
                                  .map((e) => e['students'] as int)
                                  .reduce((a, b) => a > b ? a : b) +
                              5.0
                        : 10,
                    barGroups: classDistribution.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value['students'].toDouble(),
                            color: Colors.blue,
                            width: 25,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < classDistribution.length) {
                              final className =
                                  classDistribution[value.toInt()]['name'];
                              // Clean, readable labels
                              final displayName = className.length > 8
                                  ? '${className.substring(0, 6)}...'
                                  : className;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval:
                              classDistribution.isNotEmpty &&
                                  classDistribution
                                          .map((e) => e['students'] as int)
                                          .reduce((a, b) => a > b ? a : b) >
                                      10
                              ? 5
                              : 2,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final classData = classDistribution[group.x.toInt()];
                          return BarTooltipItem(
                            '${classData['name']}\n${rod.toY.toInt()} students',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          ...recentActivity.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickAction(
            '📊',
            'View Attendance',
            'Check all attendance records',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAttendancePage(),
                ),
              );
            },
          ),
          _buildQuickAction(
            '👨‍🎓',
            'Manage Students',
            'Add or edit students',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const student_profile.StudentProfilePage(),
                ),
              );
            },
          ),
          _buildQuickAction(
            '👨‍🏫',
            'Manage Teachers',
            'Add or edit teachers',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherDashboard(),
                ),
              );
            },
          ),
          _buildQuickAction(
            '📋',
            'Generate Reports',
            'Create attendance reports',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentReportsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String icon,
    Color color,
    String trend,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                activity['avatar'],
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  activity['action'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity['time'],
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: activity['type'] == 'present'
                      ? Colors.green[100]
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activity['type'],
                  style: TextStyle(
                    fontSize: 10,
                    color: activity['type'] == 'present'
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
