import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class IdCardRecord {
  final int id;
  final String userEmail;
  final String userName;
  final String? idCardUrl;
  final String? pdfUrl;
  final String createdAt;
  final String updatedAt;

  IdCardRecord({
    required this.id,
    required this.userEmail,
    required this.userName,
    this.idCardUrl,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IdCardRecord.fromJson(Map<String, dynamic> json) {
    return IdCardRecord(
      id: json['id'] ?? 0,
      userEmail: json['user_email'] ?? '',
      userName: json['user_name'] ?? '',
      idCardUrl: json['id_card_url'],
      pdfUrl: json['pdf_url'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class StudentRecord {
  final String email;
  final String? fullname;
  final String? className;
  final String? section;
  final int? classId;

  StudentRecord({
    required this.email,
    this.fullname,
    this.className,
    this.section,
    this.classId,
  });

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      email: json['email'] ?? '',
      fullname: json['fullname'],
      className: json['class_name'],
      section: json['section'],
      classId: json['class_id'],
    );
  }
}

class IdCardComponent extends StatefulWidget {
  const IdCardComponent({super.key});

  @override
  State<IdCardComponent> createState() => _IdCardComponentState();
}

class _IdCardComponentState extends State<IdCardComponent> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<IdCardRecord> idCards = [];
  List<StudentRecord> students = [];
  bool isLoading = true;
  String error = '';
  bool showForm = false;
  String? previewUrl;
  String userEmail = '';
  String userRole = 'Student';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchData();
  }

  Future<void> loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userEmail = prefs.getString('user_email') ?? '';
        userRole = prefs.getString('user_role') ?? 'Student';
      });
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      // Fetch ID cards
      final cardsRes = await http.get(
        Uri.parse('$apiBaseUrl/id_cards/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (cardsRes.statusCode == 200) {
        final cardsData = jsonDecode(cardsRes.body) as List<dynamic>;
        setState(
          () =>
              idCards = cardsData.map((e) => IdCardRecord.fromJson(e)).toList(),
        );
      }

      // Fetch students (try-catch to continue even if it fails)
      try {
        final studentsRes = await http.get(
          Uri.parse('$apiBaseUrl/students/'),
          headers: {'Content-Type': 'application/json'},
        );

        if (studentsRes.statusCode == 200) {
          final studentsData = jsonDecode(studentsRes.body) as List<dynamic>;
          setState(
            () => students = studentsData
                .map((e) => StudentRecord.fromJson(e))
                .toList(),
          );
        }
      } catch (studErr) {
        debugPrint('Failed to fetch students: $studErr');
        // Continue even if students fetch fails
      }
    } catch (err) {
      debugPrint('ID cards fetch error: $err');
      setState(
        () => error = 'Unable to load ID cards. Please try again later.',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Map<String, StudentRecord> get studentMap {
    final map = <String, StudentRecord>{};
    for (final stu in students) {
      if (stu.email.isNotEmpty) {
        map[stu.email.toLowerCase()] = stu;
      }
    }
    return map;
  }

  bool get isStudent => userRole.toLowerCase() == 'student';

  List<IdCardRecord> get filteredCards {
    if (userEmail.isEmpty) return [];

    final emailLower = userEmail.toLowerCase();
    final userCards = idCards
        .where((card) => card.userEmail.toLowerCase() == emailLower)
        .toList();

    // For non-students (admin), only show the latest card
    if (!isStudent && userCards.length > 1) {
      userCards.sort(
        (a, b) =>
            DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
      );
      return [userCards.first];
    }

    return userCards;
  }

  Future<void> handleCreateCard() async {
    try {
      if (userEmail.isEmpty) {
        throw Exception('No user email found. Please log in again.');
      }

      await http.post(
        Uri.parse('$apiBaseUrl/id_cards/generate/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': userEmail}),
      );

      // Refresh the ID cards list after generation
      await fetchData();
      setState(() => showForm = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ID card generation started successfully!'),
          ),
        );
      }
    } catch (err) {
      debugPrint('ID card generation error: $err');

      String errorMessage =
          'Unable to generate ID card. Please contact your administrator or try again later.';

      // Handle different error types
      if (err.toString().contains('500')) {
        errorMessage =
            'Server error: ID card generation service is temporarily unavailable. Please try again later.';
      } else if (err.toString().contains('400')) {
        errorMessage =
            'Invalid request: Please check your information and try again.';
      } else if (err.toString().contains('401')) {
        errorMessage = 'Unauthorized: Please log in and try again.';
      } else if (err.toString().contains('403')) {
        errorMessage =
            'Access denied: You do not have permission to generate ID cards.';
      } else if (err.toString().contains('S3Error')) {
        errorMessage =
            'Storage error: ID card generation is temporarily unavailable due to file storage issues. Please contact your administrator.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ $errorMessage')));
      }
    }
  }

  Future<void> handleRegenerateCard(String email) async {
    try {
      await http.post(
        Uri.parse('$apiBaseUrl/id_cards/generate/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      // Refresh the list
      await fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ ID card regeneration started. Please refresh in a moment.',
            ),
          ),
        );
      }
    } catch (err) {
      debugPrint('Regeneration error: $err');

      String errorMessage = 'Failed to regenerate ID card. Please try again.';
      if (err.toString().contains('S3Error')) {
        errorMessage =
            'Storage error: ID card regeneration is temporarily unavailable.';
      } else if (err.toString().contains('500')) {
        errorMessage =
            'Server error: ID card regeneration service is temporarily unavailable.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ $errorMessage')));
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.badge,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Digital Identity',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'ID Card Wallet',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'View and download your verified ID cards. ${isStudent ? 'Students see their classmates\' cards for quick verification.' : 'Personal access.'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Secure Access',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isStudent
                                        ? 'Classmates Included'
                                        : 'Personal',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
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

                  // Error Display
                  if (error.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // No ID cards state
                  if (filteredCards.isEmpty && !showForm)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.purple[200]!,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 64,
                              color: Colors.purple[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No ID card found',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We couldn\'t find a digital ID card linked to your account. Generate one now automatically.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => showForm = true),
                              icon: const Icon(Icons.add),
                              label: const Text('Generate ID Card'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredCards.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 768
                            ? 3
                            : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        final emailLower = card.userEmail.toLowerCase();
                        final studentRecord = studentMap[emailLower];

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple, Colors.blue],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with ID Card icon
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID CARD',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                      Icon(
                                        Icons.badge,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 24,
                                      ),
                                    ],
                                  ),

                                  // User Name and Email
                                  Text(
                                    card.userName.isNotEmpty
                                        ? card.userName
                                        : card.userEmail,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.userEmail,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),

                                  const Spacer(),

                                  // Class and Section info
                                  if (studentRecord?.className != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Class ${studentRecord!.className}${studentRecord.section != null ? ' (${studentRecord.section})' : ''}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  // Created date
                                  Text(
                                    'Created: ${_formatDate(card.createdAt)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Action buttons
                                  if (card.idCardUrl != null ||
                                      card.pdfUrl != null)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => setState(
                                              () => previewUrl =
                                                  card.idCardUrl ?? card.pdfUrl,
                                            ),
                                            icon: const Icon(
                                              Icons.visibility,
                                              size: 16,
                                            ),
                                            label: const Text('View'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.purple,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _launchUrl(
                                              card.idCardUrl ?? card.pdfUrl!,
                                            ),
                                            icon: const Icon(
                                              Icons.download,
                                              size: 16,
                                            ),
                                            label: const Text('Download'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.purple,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.yellow.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            '⚠️ ID card is being generated. Please wait or try regenerating.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                handleRegenerateCard(
                                                  card.userEmail,
                                                ),
                                            icon: const Icon(
                                              Icons.refresh,
                                              size: 16,
                                            ),
                                            label: const Text('Regenerate'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Generate Form
                  if (showForm)
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(24),
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
                            'Generate Your ID Card',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the button below to automatically generate your digital ID card for the logged-in account.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.email, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Email',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        userEmail,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: handleCreateCard,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Generate ID Card'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    setState(() => showForm = false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Preview
                  if (previewUrl != null)
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(24),
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
                                'ID Card Preview',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => previewUrl = null),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This is a preview of your ID card. Use the Download button above if you want to save it.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: previewUrl!.endsWith('.pdf')
                                ? const Center(
                                    child: Text(
                                      'PDF Preview - Use download button to view',
                                    ),
                                  )
                                : Image.network(
                                    previewUrl!,
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text('Failed to load preview'),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
