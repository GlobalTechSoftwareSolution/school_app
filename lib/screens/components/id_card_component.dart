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
  final String fullname;
  final String? className;
  final String? section;
  final int? classId;

  StudentRecord({
    required this.email,
    required this.fullname,
    this.className,
    this.section,
    this.classId,
  });

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      email: json['email'] ?? '',
      fullname: json['fullname'] ?? '',
      className: json['class_name'],
      section: json['section'],
      classId: json['class_id'],
    );
  }
}

class IdCardForm extends StatefulWidget {
  final Future<void> Function() onSubmit;
  final VoidCallback onCancel;
  final String defaultEmail;

  const IdCardForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    required this.defaultEmail,
  });

  @override
  State<IdCardForm> createState() => _IdCardFormState();
}

class _IdCardFormState extends State<IdCardForm> {
  bool submitting = false;
  String error = '';

  Future<void> handleSubmit() async {
    setState(() {
      submitting = true;
      error = '';
    });

    try {
      await widget.onSubmit();
    } catch (err) {
      String errorMessage =
          'Unable to generate ID card. The backend service may be experiencing issues. Please contact your administrator or try again later.';

      if (err is http.ClientException) {
        // Handle HTTP errors
        errorMessage =
            'Network error: Please check your connection and try again.';
      } else if (err.toString().contains('S3Error')) {
        errorMessage =
            'Storage error: ID card generation is temporarily unavailable due to file storage issues. Please contact your administrator.';
      } else if (err.toString().contains('500')) {
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
      }

      setState(() => error = errorMessage);
    } finally {
      setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Generate Your ID Card',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click the button below to automatically generate your digital ID card for the logged-in account.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: widget.defaultEmail,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: submitting ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      submitting ? 'Generating...' : 'Generate ID Card',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: submitting ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AllIdCards extends StatefulWidget {
  const AllIdCards({super.key});

  @override
  State<AllIdCards> createState() => _AllIdCardsState();
}

class _AllIdCardsState extends State<AllIdCards> {
  List<IdCardRecord> idCards = [];
  List<StudentRecord> students = [];
  bool loading = true;
  String error = '';
  bool showForm = false;
  String? previewUrl;
  final ScrollController _scrollController = ScrollController();

  String userEmail = '';
  String userRole = 'Student';

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';
      final role = prefs.getString('user_role') ?? 'Student';

      setState(() {
        userEmail = email;
        userRole = role;
      });
    } catch (e) {
      setState(() {
        userEmail = '';
        userRole = 'Student';
      });
    }
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        loading = true;
        error = '';
      });

      const apiBase = 'https://school.globaltechsoftwaresolutions.cloud/api';

      final cardsRes = await http
          .get(
            Uri.parse('$apiBase/id_cards/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      final cardsData = json.decode(cardsRes.body) as List;
      idCards = cardsData.map((c) => IdCardRecord.fromJson(c)).toList();

      // Fetch students
      try {
        final studentsRes = await http
            .get(
              Uri.parse('$apiBase/students/'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));

        final studentsData = json.decode(studentsRes.body) as List;
        setState(
          () => students = studentsData
              .map((s) => StudentRecord.fromJson(s))
              .toList(),
        );
      } catch (studErr) {
        // Continue even if students fetch fails
      }
    } catch (err) {
      setState(
        () => error = 'Unable to load ID cards. Please try again later.',
      );
    } finally {
      setState(() => loading = false);
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
    return idCards
        .where((card) => card.userEmail.toLowerCase() == emailLower)
        .toList();
  }

  Future<void> handleCreateCard() async {
    if (userEmail.isEmpty) {
      throw Exception('No user email found. Please log in again.');
    }

    const apiBase = 'https://school.globaltechsoftwaresolutions.cloud/api';
    await http
        .post(
          Uri.parse('$apiBase/id_cards/generate/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': userEmail}),
        )
        .timeout(const Duration(seconds: 30));

    await fetchData();
    setState(() => showForm = false);
  }

  Future<void> downloadCard(String url, String filename) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the file')));
    }
  }

  Future<void> regenerateCard(int cardId, String email) async {
    try {
      const apiBase = 'https://school.globaltechsoftwaresolutions.cloud/api';
      await http
          .post(
            Uri.parse('$apiBase/id_cards/generate/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      await fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ID card regeneration started. Please refresh in a moment.',
          ),
        ),
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to regenerate ID card. Please try again.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.blue[50]!],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Digital Identity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ID Card Wallet',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'View and download your verified ID cards. ${isStudent ? 'Students see their classmates\' cards for quick verification.' : 'Personal'}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield,
                                size: 14,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Secure Access',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                isStudent ? 'Classmates Included' : 'Personal',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
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
            ),

            const SizedBox(height: 24),

            if (error.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 24),
            ],

            if (loading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (filteredCards.isEmpty && !showForm) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 64,
                        color: Colors.purple[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No ID card found',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We couldn\'t find a digital ID card linked to your account. Generate one now automatically.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => showForm = true),
                        icon: const Icon(Icons.add),
                        label: const Text('Generate ID Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 768
                      ? 3
                      : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredCards.length,
                itemBuilder: (context, index) {
                  final card = filteredCards[index];
                  final emailLower = card.userEmail.toLowerCase();
                  final studentRecord = studentMap[emailLower];

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.purple[600]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ID CARD',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        card.userName.isNotEmpty
                                            ? card.userName
                                            : card.userEmail,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        card.userEmail,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.credit_card,
                                  size: 32,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),

                          // Details
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (studentRecord?.className != null) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Class',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          studentRecord!.className!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (studentRecord?.section != null) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Section',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          studentRecord!.section!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Created',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        DateTime.parse(
                                          card.createdAt,
                                        ).toLocal().toString().split(' ')[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (card.idCardUrl != null ||
                                      card.pdfUrl != null) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        SizedBox(
                                          width:
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width >
                                                  600
                                              ? (MediaQuery.of(
                                                              context,
                                                            ).size.width -
                                                            80) /
                                                        2 -
                                                    4
                                              : double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(
                                                () => previewUrl =
                                                    card.idCardUrl ??
                                                    card.pdfUrl,
                                              );
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    _scrollController.animateTo(
                                                      _scrollController
                                                          .position
                                                          .maxScrollExtent,
                                                      duration: const Duration(
                                                        milliseconds: 500,
                                                      ),
                                                      curve: Curves.easeInOut,
                                                    );
                                                  });
                                            },
                                            icon: const Icon(
                                              Icons.visibility,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'View',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.purple,
                                              side: const BorderSide(
                                                color: Colors.purple,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width >
                                                  600
                                              ? (MediaQuery.of(
                                                              context,
                                                            ).size.width -
                                                            80) /
                                                        2 -
                                                    4
                                              : double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => downloadCard(
                                              card.idCardUrl ?? card.pdfUrl!,
                                              'id_card.pdf',
                                            ),
                                            icon: const Icon(
                                              Icons.download,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Download',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.purple,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow[50],
                                        border: Border.all(
                                          color: Colors.yellow[200]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning,
                                            color: Colors.orange[600],
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'ID card is being generated. Please wait or try regenerating.',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => regenerateCard(
                                          card.id,
                                          card.userEmail,
                                        ),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Regenerate ID Card'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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

            if (showForm) ...[
              const SizedBox(height: 24),
              Center(
                child: IdCardForm(
                  defaultEmail: userEmail,
                  onSubmit: handleCreateCard,
                  onCancel: () => setState(() => showForm = false),
                ),
              ),
            ],

            if (previewUrl != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ID Card Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This is a preview of your ID card. Use the Download ID Card button above if you want to save it.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 400,
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'PDF Preview not available in mobile view.\nPlease use download button.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
