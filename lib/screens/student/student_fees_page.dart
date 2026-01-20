import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FeeStructure {
  final int id;
  final String amount;
  final String feeType;
  final String className;
  final String section;
  final String frequency;
  final String? academicYear;

  FeeStructure({
    required this.id,
    required this.amount,
    required this.feeType,
    required this.className,
    required this.section,
    required this.frequency,
    this.academicYear,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: json['id'] ?? 0,
      amount: json['amount'] ?? '0',
      feeType: json['fee_type'] ?? '',
      className: json['class_name'] ?? '',
      section: json['section'] ?? '',
      frequency: json['frequency'] ?? '',
      academicYear: json['academic_year'],
    );
  }
}

class FeeDetails {
  final int id;
  final String studentName;
  final String feeType;
  final String amountPaid;
  final String? totalAmount;
  final String paymentDate;
  final String paymentMethod;
  final String transactionId;
  final String status;
  final String remarks;
  final String student;
  final int feeStructure;
  final String? className;
  final String? section;
  final String? calculatedRemainingAmount;
  final String? structureAmount;

  FeeDetails({
    required this.id,
    required this.studentName,
    required this.feeType,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
    required this.remarks,
    required this.student,
    required this.feeStructure,
    this.totalAmount,
    this.className,
    this.section,
    this.calculatedRemainingAmount,
    this.structureAmount,
  });

  factory FeeDetails.fromJson(Map<String, dynamic> json) {
    return FeeDetails(
      id: json['id'] ?? 0,
      studentName: json['student_name'] ?? '',
      feeType: json['fee_type'] ?? '',
      amountPaid: json['amount_paid'] ?? '0',
      totalAmount: json['total_amount'],
      paymentDate: json['payment_date'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? '',
      remarks: json['remarks'] ?? '',
      student: json['student'] ?? '',
      feeStructure: json['fee_structure'] ?? 0,
      className: json['class_name'],
      section: json['section'],
      calculatedRemainingAmount: json['calculated_remaining_amount'],
      structureAmount: json['structure_amount'],
    );
  }
}

class PaymentFormData {
  int feeStructure;
  String amountPaid;
  String paymentDate;
  String paymentMethod;
  String transactionId;
  String status;
  String remarks;

  PaymentFormData({
    this.feeStructure = 0,
    this.amountPaid = '',
    this.paymentDate = '',
    this.paymentMethod = 'Online',
    this.transactionId = '',
    this.status = 'Paid',
    this.remarks = '',
  });
}

class StudentFeesPage extends StatefulWidget {
  const StudentFeesPage({super.key});

  @override
  State<StudentFeesPage> createState() => _StudentFeesPageState();
}

class _StudentFeesPageState extends State<StudentFeesPage> {
  List<FeeDetails> fees = [];
  List<FeeStructure> feeStructures = [];
  bool loading = true;
  Map<String, dynamic>? student;
  FeeDetails? selectedFee;
  bool showReceiptModal = false;
  bool showPaymentModal = false;
  bool submitting = false;

  final PaymentFormData paymentForm = PaymentFormData();

  final String apiBase = 'https://school.globaltechsoftwaresolutions.cloud/api';
  final String feesApi =
      'https://school.globaltechsoftwaresolutions.cloud/api/fee_payments/';
  final String feeStructureApi =
      'https://school.globaltechsoftwaresolutions.cloud/api/fee_structures/';

  @override
  void initState() {
    super.initState();
    paymentForm.paymentDate = DateTime.now().toLocal().toString().split(' ')[0];
    fetchAllData();
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

  Future<List<FeeStructure>> fetchFeeStructures(
    String studentClass,
    String studentSection,
  ) async {
    try {
      final response = await http.get(Uri.parse(feeStructureApi));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final allStructures = data
            .map((item) => FeeStructure.fromJson(item))
            .toList();

        return allStructures.where((fs) {
          final classMatch =
              fs.className.toLowerCase().trim() ==
              studentClass.toLowerCase().trim();
          final sectionMatch =
              studentSection.isEmpty ||
              fs.section.toLowerCase().trim() ==
                  studentSection.toLowerCase().trim();
          return classMatch && sectionMatch;
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> fetchAllData() async {
    setState(() => loading = true);

    try {
      final email = await getStoredEmail();
      if (email == null) {
        setState(() => loading = false);
        return;
      }

      // Fetch student details
      final studentResponse = await http.get(
        Uri.parse('$apiBase/students/?email=${Uri.encodeComponent(email)}'),
      );

      if (studentResponse.statusCode == 200) {
        final studentData = json.decode(studentResponse.body);
        final studentInfo = studentData is List ? studentData[0] : studentData;
        setState(() => student = studentInfo);

        if (studentInfo != null) {
          final structures = await fetchFeeStructures(
            studentInfo['class_name'] ?? '',
            studentInfo['section'] ?? '',
          );
          setState(() => feeStructures = structures);

          // Fetch fee payments
          final feesResponse = await http.get(Uri.parse(feesApi));
          if (feesResponse.statusCode == 200) {
            final feesData = json.decode(feesResponse.body) as List;
            final allFees = feesData
                .map((item) => FeeDetails.fromJson(item))
                .toList();

            final normalizedEmail = (studentInfo['email'] ?? '')
                .toLowerCase()
                .trim();
            final normalizedName =
                (studentInfo['fullname'] ?? studentInfo['name'] ?? '')
                    .toLowerCase()
                    .trim();

            final filteredFees = allFees.where((fee) {
              final feeEmail = (fee.student ?? '').toLowerCase().trim();
              final feeName = (fee.studentName ?? '').toLowerCase().trim();
              return feeEmail == normalizedEmail || feeName == normalizedName;
            }).toList();

            // Group fees by fee_structure and calculate remaining amounts
            final feesByStructure = <int, List<FeeDetails>>{};
            for (final fee in filteredFees) {
              feesByStructure.putIfAbsent(fee.feeStructure, () => []).add(fee);
            }

            final enhancedFees = <FeeDetails>[];
            for (final entry in feesByStructure.entries) {
              final structureId = entry.key;
              final feesForStructure = entry.value;

              final matchedStructure = structures.firstWhere(
                (fs) => fs.id == structureId,
                orElse: () => FeeStructure(
                  id: 0,
                  amount: '0',
                  feeType: '',
                  className: '',
                  section: '',
                  frequency: '',
                ),
              );

              if (matchedStructure.id != 0) {
                final totalAmount = double.parse(matchedStructure.amount);
                final totalPaid = feesForStructure.fold<double>(
                  0,
                  (sum, fee) => sum + double.parse(fee.amountPaid),
                );
                final remainingAmount = (totalAmount - totalPaid).clamp(
                  0,
                  double.infinity,
                );

                for (final fee in feesForStructure) {
                  enhancedFees.add(
                    FeeDetails(
                      id: fee.id,
                      studentName: fee.studentName,
                      feeType: fee.feeType,
                      amountPaid: fee.amountPaid,
                      totalAmount: totalAmount.toString(),
                      paymentDate: fee.paymentDate,
                      paymentMethod: fee.paymentMethod,
                      transactionId: fee.transactionId,
                      status: fee.status,
                      remarks: fee.remarks,
                      student: fee.student,
                      feeStructure: fee.feeStructure,
                      className: fee.className,
                      section: fee.section,
                      calculatedRemainingAmount: remainingAmount
                          .toStringAsFixed(2),
                      structureAmount: matchedStructure.amount,
                    ),
                  );
                }
              } else {
                enhancedFees.addAll(feesForStructure);
              }
            }

            setState(() => fees = enhancedFees);
          }
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> handlePaymentSubmit() async {
    if (student == null || student!['email'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Student email not found. Please refresh.'),
        ),
      );
      return;
    }

    if (paymentForm.feeStructure == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select a fee structure.')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      final payload = {
        'student': student!['email'],
        'fee_structure': paymentForm.feeStructure,
        'amount_paid': double.parse(paymentForm.amountPaid),
        'payment_date': paymentForm.paymentDate,
        'payment_method': paymentForm.paymentMethod,
        'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'status': 'Paid',
        'remarks': 'Paid via student portal',
      };

      final response = await http.post(
        Uri.parse(feesApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Payment submitted successfully!')),
        );
        setState(() {
          showPaymentModal = false;
          paymentForm.feeStructure = 0;
          paymentForm.amountPaid = '';
          paymentForm.paymentMethod = 'Online';
          paymentForm.transactionId = '';
          paymentForm.remarks = '';
        });
        await fetchAllData();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${errorData['payment_method'] ?? errorData['amount_paid'] ?? 'Payment failed. Try again.'}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Payment failed. Try again.')),
      );
    } finally {
      setState(() => submitting = false);
    }
  }

  double get totalPaid =>
      fees.fold<double>(0, (sum, fee) => sum + double.parse(fee.amountPaid));

  double get totalDue {
    final uniqueStructures = fees.map((fee) => fee.feeStructure).toSet();
    double totalRemaining = 0;

    for (final structureId in uniqueStructures) {
      final feeWithStructure = fees.firstWhere(
        (fee) => fee.feeStructure == structureId,
      );
      totalRemaining += double.parse(
        feeWithStructure.calculatedRemainingAmount ?? '0',
      );
    }

    return totalRemaining;
  }

  int get paidFees => fees.where((fee) => fee.status == 'Paid').length;
  int get pendingFees => fees.where((fee) => fee.status != 'Paid').length;

  void handleViewReceipt(FeeDetails fee) {
    setState(() {
      selectedFee = fee;
      showReceiptModal = true;
    });
  }

  Future<void> handleDownloadReceipt(FeeDetails fee) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SMART SCHOOL',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Fee Payment Receipt',
                      style: pw.TextStyle(fontSize: 18, color: PdfColors.grey),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),

              // Receipt Details
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Student Name:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(fee.studentName),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Fee Type:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(fee.feeType),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment Date:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(fee.paymentDate),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment Method:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(fee.paymentMethod),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Transaction ID:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(fee.transactionId),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),

              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Amount:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('INR ${fee.structureAmount}'),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Amount Paid:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                  pw.Text('INR ${fee.amountPaid}'),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Remaining Balance:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.Text('INR ${fee.calculatedRemainingAmount}'),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Status:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(fee.status),
                ],
              ),

              if (fee.remarks.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Remarks: ${fee.remarks}',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
              ],

              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated receipt.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Receipt_${fee.transactionId}.pdf',
    );
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
                'Loading fees information...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color.fromRGBO(248, 250, 252, 1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fees Management',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 600
                                  ? 28
                                  : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your fee payments and track payment history',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 600
                                  ? 16
                                  : 14,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (student == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '⚠️ Student data not yet loaded. Please refresh.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => showPaymentModal = true);
                      },
                      icon: const Icon(Icons.payment),
                      label: Text(
                        MediaQuery.of(context).size.width > 600
                            ? 'Pay Fees'
                            : 'Pay',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Summary Cards
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSummaryCard(
                  'Total Paid',
                  '₹${totalPaid.toStringAsFixed(2)}',
                  Colors.green,
                  '💰',
                ),
                _buildSummaryCard(
                  'Total Due',
                  '₹${totalDue.toStringAsFixed(2)}',
                  Colors.red,
                  '📋',
                ),
                _buildSummaryCard(
                  'Paid Fees',
                  paidFees.toString(),
                  Colors.blue,
                  '✅',
                ),
                _buildSummaryCard(
                  'Pending Fees',
                  pendingFees.toString(),
                  Colors.orange,
                  '⏳',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Fee History
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Fee History',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width > 600
                              ? 24
                              : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        '${fees.length} records',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (fees.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200
                      ? 4
                      : MediaQuery.of(context).size.width > 768
                      ? 3
                      : MediaQuery.of(context).size.width > 600
                      ? 2
                      : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: fees.length,
                itemBuilder: (context, index) => _buildFeeCard(fees[index]),
              )
            else
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
                        '📊',
                        style: TextStyle(fontSize: 48, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No fee records found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your fee history will appear here once payments are made',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Receipt Modal
            if (showReceiptModal && selectedFee != null) _buildReceiptModal(),

            // Payment Modal
            if (showPaymentModal) _buildPaymentModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    String icon,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(FeeDetails fee) {
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    fee.feeType.isNotEmpty ? fee.feeType[0].toUpperCase() : 'F',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: fee.status == 'Paid'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (fee.status == 'Paid' ? Colors.green : Colors.orange)
                        .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  fee.status == 'Paid' ? '✅ Paid' : '⏳ Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: fee.status == 'Paid'
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fee Type and Date
          Text(
            fee.feeType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            fee.paymentDate,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          // Amount Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${fee.structureAmount}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paid',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${fee.amountPaid}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${fee.calculatedRemainingAmount}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Method: ${fee.paymentMethod}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                'ID: ${fee.transactionId.length > 10 ? fee.transactionId.substring(0, 10) + '...' : fee.transactionId}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),

          const Spacer(),

          // View Receipt Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => handleViewReceipt(fee),
              icon: const Icon(Icons.receipt, size: 16),
              label: const Text('View Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildReceiptModal() {
    if (selectedFee == null) return const SizedBox();

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Payment Receipt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Details
                      _buildReceiptRow(
                        'Student Name',
                        selectedFee!.studentName,
                      ),
                      _buildReceiptRow('Fee Type', selectedFee!.feeType),
                      _buildReceiptRow(
                        'Total Amount',
                        '₹${selectedFee!.structureAmount}',
                      ),
                      _buildReceiptRow(
                        'Amount Paid',
                        '₹${selectedFee!.amountPaid}',
                        color: Colors.green,
                      ),
                      _buildReceiptRow(
                        'Remaining',
                        '₹${selectedFee!.calculatedRemainingAmount}',
                        color: Colors.red,
                      ),
                      _buildReceiptRow('Status', selectedFee!.status),

                      const Divider(height: 32),

                      // Payment Details
                      _buildReceiptRow(
                        'Payment Date',
                        selectedFee!.paymentDate,
                      ),
                      _buildReceiptRow(
                        'Payment Method',
                        selectedFee!.paymentMethod,
                      ),
                      _buildReceiptRow(
                        'Transaction ID',
                        selectedFee!.transactionId,
                      ),

                      if (selectedFee!.remarks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Remarks: ${selectedFee!.remarks}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => showReceiptModal = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => handleDownloadReceipt(selectedFee!),
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModal() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Pay Fees',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fee Structure Dropdown
                      const Text(
                        'Select Fee Structure',
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
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: paymentForm.feeStructure == 0
                                ? null
                                : paymentForm.feeStructure,
                            hint: const Text('Choose a fee type...'),
                            items: feeStructures.map((structure) {
                              return DropdownMenuItem<int>(
                                value: structure.id,
                                child: Text(
                                  '${structure.feeType} - ₹${structure.amount} (${structure.frequency})',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(
                              () => paymentForm.feeStructure = value ?? 0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Amount
                      const Text(
                        'Amount Paid (₹)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) => paymentForm.amountPaid = value,
                      ),

                      const SizedBox(height: 16),

                      // Payment Date
                      const Text(
                        'Payment Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(
                          text: paymentForm.paymentDate,
                        ),
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setState(
                                  () => paymentForm.paymentDate = date
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                                );
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment Method
                      const Text(
                        'Payment Method',
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
                            value: paymentForm.paymentMethod,
                            items: const [
                              DropdownMenuItem(
                                value: 'Cash',
                                child: Text('💵 Cash'),
                              ),
                              DropdownMenuItem(
                                value: 'Card',
                                child: Text('💳 Card'),
                              ),
                              DropdownMenuItem(
                                value: 'Bank Transfer',
                                child: Text('🏦 Bank Transfer'),
                              ),
                              DropdownMenuItem(
                                value: 'Online',
                                child: Text('🌐 Online'),
                              ),
                              DropdownMenuItem(
                                value: 'Cheque',
                                child: Text('📄 Cheque'),
                              ),
                            ],
                            onChanged: (value) => setState(
                              () =>
                                  paymentForm.paymentMethod = value ?? 'Online',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Remarks
                      const Text(
                        'Remarks (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any additional notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) => paymentForm.remarks = value,
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => showPaymentModal = false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : handlePaymentSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [Text('💳 Submit Payment')],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
