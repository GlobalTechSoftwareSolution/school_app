import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  final Function(String) onNavigate;

  const StudentDashboard({super.key, required this.onNavigate});

  Widget _buildStudentStatCard(
    String title,
    String value,
    String emoji,
    Color color,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  Widget _buildQuickLink(
    String title,
    String emoji,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildActivitySummary(
    String title,
    String count,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                fontSize: 20,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Center(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
                  ).createShader(bounds),
                  child: Text(
                    'Welcome back, Student!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome to your Student Dashboard',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stats Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStudentStatCard(
                'Attendance',
                '0%',
                '📊',
                Colors.blue,
                '0 present • 0 absent',
                () => onNavigate('Attendance'),
              ),
              _buildStudentStatCard(
                'Average Marks',
                '0%',
                '⭐',
                Colors.green,
                '0 subjects',
                () => onNavigate('Marks'),
              ),
              _buildStudentStatCard(
                'Leaves',
                '0',
                '📅',
                Colors.purple,
                '0 pending',
                () => onNavigate('Leaves'),
              ),
              _buildStudentStatCard(
                'Notices',
                '0',
                '📢',
                Colors.orange,
                '0 unread',
                () => onNavigate('Notice'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Quick Links and Content Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Links (takes 1/3 on large screens)
              Expanded(
                flex: MediaQuery.of(context).size.width > 768 ? 1 : 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(24),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Links',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickLink(
                        'Task Manager',
                        '🎯',
                        Colors.blue,
                        () => onNavigate('Tasks'),
                      ),
                      _buildQuickLink(
                        'Assignments',
                        '📝',
                        Colors.green,
                        () => onNavigate('Assignments'),
                      ),
                      _buildQuickLink(
                        'Academic Performance',
                        '📊',
                        Colors.purple,
                        () => onNavigate('Marks'),
                      ),
                      _buildQuickLink(
                        'Leave Management',
                        '📅',
                        Colors.orange,
                        () => onNavigate('Leaves'),
                      ),
                      _buildQuickLink(
                        'My Documents',
                        '📁',
                        Colors.red,
                        () => onNavigate('Documents'),
                      ),
                      _buildQuickLink(
                        'Holiday Calendar',
                        '📅',
                        Colors.teal,
                        () => onNavigate('Calendar'),
                      ),
                    ],
                  ),
                ),
              ),

              // Latest Notices (takes 2/3 on large screens)
              if (MediaQuery.of(context).size.width > 768)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Latest Notices',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () => onNavigate('Notice'),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildNoticeCard(
                          'School Holiday Announcement',
                          'School will remain closed for Diwali vacation from 25th October to 5th November.',
                          'high',
                          'Admin',
                          '2 days ago',
                        ),
                        const SizedBox(height: 12),
                        _buildNoticeCard(
                          'Exam Schedule Update',
                          'Mid-term examinations will begin from 15th November. Check your timetable.',
                          'medium',
                          'Academic Office',
                          '5 days ago',
                        ),
                        const SizedBox(height: 12),
                        _buildNoticeCard(
                          'Library Hours Extended',
                          'Library will remain open till 8 PM during exam preparation period.',
                          'low',
                          'Librarian',
                          '1 week ago',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent Notices
          Container(
            padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Notices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigate('Notice'),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'No recent notices',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
