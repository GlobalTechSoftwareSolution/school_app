import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDocument {
  final String email;
  final String? uploadedAt;
  final Map<String, dynamic> documents;

  StudentDocument({
    required this.email,
    this.uploadedAt,
    required this.documents,
  });

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      email: json['email'] ?? '',
      uploadedAt: json['uploaded_at'],
      documents: Map<String, dynamic>.from(json)
        ..removeWhere(
          (key, value) =>
              key == 'email' || key == 'uploaded_at' || value == null,
        ),
    );
  }
}

class FormattedDocument {
  final String key;
  final String name;
  final String url;
  final String type;
  final String? uploadedAt;

  FormattedDocument({
    required this.key,
    required this.name,
    required this.url,
    required this.type,
    this.uploadedAt,
  });
}

class StudentDocumentsPage extends StatefulWidget {
  const StudentDocumentsPage({super.key});

  @override
  State<StudentDocumentsPage> createState() => _StudentDocumentsPageState();
}

class _StudentDocumentsPageState extends State<StudentDocumentsPage> {
  StudentDocument? docs;
  bool loading = true;
  String error = "";
  PlatformFile? selectedFile;
  String selectedDocType = "";
  bool uploading = false;
  double uploadProgress = 0.0;
  FormattedDocument? selectedDoc;

  final String apiBase =
      'https://school.globaltechsoftwaresolutions.cloud/api/documents';

  final List<String> docOptions = [
    "tenth",
    "twelth",
    "degree",
    "masters",
    "marks_card",
    "certificates",
    "award",
    "resume",
    "id_proof",
    "transfer_certificate",
    "study_certificate",
    "conduct_certificate",
    "student_id_card",
    "admit_card",
    "fee_receipt",
    "achievement_crt",
    "bonafide_crt",
  ];

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  Future<String?> getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = prefs.getString('userInfo');
      final userData = prefs.getString('userData');
      final email = prefs.getString('user_email');

      if (userInfo != null) {
        final parsed = json.decode(userInfo);
        return parsed['email'] ?? email;
      }
      if (userData != null) {
        final parsed = json.decode(userData);
        return parsed['email'] ?? email;
      }
      return email;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') ?? prefs.getString('authToken');
  }

  Future<void> fetchDocuments() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      final email = await getStoredEmail();
      if (email == null) throw Exception("No logged-in user found.");

      final response = await http.get(Uri.parse('$apiBase/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final studentDoc = data.cast<Map<String, dynamic>>().firstWhere((d) {
          final docEmail = d['email'];
          return docEmail != null &&
              docEmail.toString().toLowerCase() == email.toLowerCase();
        }, orElse: () => <String, dynamic>{});

        if (studentDoc.isNotEmpty) {
          setState(() => docs = StudentDocument.fromJson(studentDoc));
        } else {
          setState(() => docs = null);
        }
      }
    } catch (e) {
      setState(() => error = "Failed to load documents. Try again later.");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => selectedFile = result.files.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error selecting file')));
    }
  }

  Future<void> handleUpload() async {
    final email = await getStoredEmail();
    final token = await getStoredToken();

    if (email == null || selectedDocType.isEmpty || selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select a document type and file.'),
        ),
      );
      return;
    }

    setState(() {
      uploading = true;
      uploadProgress = 0.0;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBase/upload/'),
      );
      request.headers['Authorization'] = token != null ? 'Bearer $token' : '';

      request.fields['email'] = email;
      request.fields['doc_type'] = selectedDocType;

      if (selectedFile!.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            selectedDocType,
            selectedFile!.bytes!,
            filename: selectedFile!.name,
            contentType: MediaType('application', 'octet-stream'),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            selectedDocType,
            selectedFile!.path!,
            filename: selectedFile!.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${selectedDocType.toUpperCase()} uploaded successfully!',
            ),
          ),
        );
        await fetchDocuments();
        setState(() {
          selectedFile = null;
          selectedDocType = "";
          uploadProgress = 0.0;
        });
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${errorData['error'] ?? "Upload failed. Try again."}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Upload failed. Try again.')));
    } finally {
      setState(() => uploading = false);
    }
  }

  List<FormattedDocument> get formattedDocs {
    if (docs == null) return [];

    return docs!.documents.entries
        .where(
          (entry) => entry.value != null && entry.value.toString().isNotEmpty,
        )
        .map(
          (entry) => FormattedDocument(
            key: entry.key,
            name: entry.key
                .replaceAll('_', ' ')
                .replaceAllMapped(
                  RegExp(r'\b\w'),
                  (match) => match.group(0)!.toUpperCase(),
                ),
            url: entry.value.toString(),
            type: entry.key,
            uploadedAt: docs!.uploadedAt,
          ),
        )
        .toList();
  }

  String getDocIcon(String docType) {
    const icons = {
      'tenth': '📘',
      'twelth': '📗',
      'degree': '🎓',
      'masters': '🎓',
      'marks_card': '📊',
      'certificates': '🏅',
      'award': '⭐',
      'resume': '📄',
      'id_proof': '🆔',
      'transfer_certificate': '📑',
      'study_certificate': '📖',
      'conduct_certificate': '📜',
      'student_id_card': '💳',
      'admit_card': '🎫',
      'fee_receipt': '🧾',
      'achievement_crt': '🏆',
      'bonafide_crt': '📋',
    };
    return icons[docType] ?? '📁';
  }

  Future<void> launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open document')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        color: Colors.grey[50],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your documents...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Center(
              child: Column(
                children: [
                  SizedBox(height: 24),
                  Text(
                    'Document Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Upload and manage your academic documents',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Upload Section
            Container(
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
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Document Type Dropdown
                  const Text(
                    'Document Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedDocType.isEmpty ? null : selectedDocType,
                        hint: const Text('Select Document Type'),
                        items: docOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(
                              option
                                  .replaceAll('_', ' ')
                                  .replaceAllMapped(
                                    RegExp(r'\b\w'),
                                    (match) => match.group(0)!.toUpperCase(),
                                  ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => selectedDocType = value ?? ''),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // File Picker
                  const Text(
                    'File',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedFile != null
                                ? Icons.file_present
                                : Icons.file_upload,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedFile != null
                                  ? selectedFile!.name
                                  : 'Click to select file (PDF, JPG, PNG, DOC, DOCX)',
                              style: TextStyle(
                                color: selectedFile != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress Bar
                  if (uploading) ...[
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Uploading...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (uploading ||
                              selectedFile == null ||
                              selectedDocType.isEmpty)
                          ? null
                          : handleUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: uploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('📤', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8),
                                Text(
                                  'Upload Document',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Documents Section
            if (error.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (formattedDocs.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Documents (${formattedDocs.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Last updated: ${docs?.uploadedAt != null ? DateTime.parse(docs!.uploadedAt!).toLocal().toString().split(' ')[0] : 'N/A'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: formattedDocs.length,
                itemBuilder: (context, index) {
                  final doc = formattedDocs[index];
                  return GestureDetector(
                    onTap: () => setState(() => selectedDoc = doc),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
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
                          // Document Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  getDocIcon(doc.type),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        doc.uploadedAt != null
                                            ? DateTime.parse(doc.uploadedAt!)
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[0]
                                            : 'Recently',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Document Actions
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: ElevatedButton.icon(
                                onPressed: () => launchURL(doc.url),
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('👁️ View Document'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Text(
                        '📁',
                        style: TextStyle(fontSize: 48, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Documents Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload your first document to start building your academic portfolio.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Document Detail Modal
            if (selectedDoc != null)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Modal Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  getDocIcon(selectedDoc!.type),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedDoc!.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        selectedDoc!.type.replaceAll('_', ' '),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => selectedDoc = null),
                                  icon: const Icon(Icons.close),
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),

                          // Modal Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Document Details
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Document Details',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Type:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            selectedDoc!.type.replaceAll(
                                              '_',
                                              ' ',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Uploaded:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            selectedDoc!.uploadedAt != null
                                                ? DateTime.parse(
                                                    selectedDoc!.uploadedAt!,
                                                  ).toLocal().toString().split(
                                                    ' ',
                                                  )[0]
                                                : 'Recently',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Actions
                                const Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        launchURL(selectedDoc!.url),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('View Document'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
