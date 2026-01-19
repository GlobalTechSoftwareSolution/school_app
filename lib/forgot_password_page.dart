import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  String email = '';
  String message = '';
  bool isLoading = false;

  Future<void> handleSubmit() async {
    if (email.isEmpty) {
      setState(() => message = 'Please enter your email address');
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      print('🔄 Making password reset request for email: $email');

      final res = await http.post(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/password_reset/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('📡 Response status: ${res.statusCode}');
      print('📡 Response body: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        print('✅ Success response: $data');

        // Handle different success messages
        final responseMessage =
            data['message'] ??
            data['detail'] ??
            'Password reset link sent successfully!';
        setState(() => message = responseMessage);
      } else if (res.statusCode == 404) {
        print('❌ Email not found');
        setState(
          () =>
              message = 'Email address not found. Please check and try again.',
        );
      } else if (res.statusCode == 400) {
        final data = jsonDecode(res.body);
        print('❌ Bad request: $data');
        final errorMessage =
            data['email']?.join(', ') ??
            data['error'] ??
            data['message'] ??
            'Invalid email address';
        setState(() => message = errorMessage);
      } else if (res.statusCode >= 500) {
        print('❌ Server error');
        setState(() => message = 'Server error. Please try again later.');
      } else {
        final data = jsonDecode(res.body);
        print('❌ Other error: $data');
        final errorMessage =
            data['error'] ??
            data['message'] ??
            'An error occurred. Please try again.';
        setState(() => message = errorMessage);
      }
    } catch (error) {
      print('🚨 Network error: $error');
      setState(
        () => message =
            'Network error. Please check your connection and try again.',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Helper methods for message styling
  Color _getMessageColor(String message) {
    // Check for success indicators first
    if (message.contains('successfully') ||
        message.contains('sent') ||
        message.contains('Success') ||
        message.contains('reset link sent')) {
      return Colors.green[50]!;
    }

    // Check for error indicators
    if (message.contains('not found') ||
        message.contains('No user found') ||
        message.contains('Invalid') ||
        message.contains('error') ||
        message.contains('Error') ||
        message.contains('Network') ||
        message.contains('Server') ||
        message.contains('check and try again')) {
      return Colors.orange[50]!;
    }

    // Default to green for unknown messages
    return Colors.green[50]!;
  }

  Color _getMessageBorderColor(String message) {
    // Check for success indicators first
    if (message.contains('successfully') ||
        message.contains('sent') ||
        message.contains('Success') ||
        message.contains('reset link sent')) {
      return Colors.green[200]!;
    }

    // Check for error indicators
    if (message.contains('not found') ||
        message.contains('No user found') ||
        message.contains('Invalid') ||
        message.contains('error') ||
        message.contains('Error') ||
        message.contains('Network') ||
        message.contains('Server') ||
        message.contains('check and try again')) {
      return Colors.orange[200]!;
    }

    // Default to green for unknown messages
    return Colors.green[200]!;
  }

  IconData _getMessageIcon(String message) {
    // Check for success indicators first
    if (message.contains('successfully') ||
        message.contains('sent') ||
        message.contains('Success') ||
        message.contains('reset link sent')) {
      return Icons.check_circle;
    }

    // Check for error indicators
    if (message.contains('not found') ||
        message.contains('No user found') ||
        message.contains('Invalid') ||
        message.contains('error') ||
        message.contains('Error') ||
        message.contains('Network') ||
        message.contains('Server') ||
        message.contains('check and try again')) {
      return Icons.warning;
    }

    // Default to success icon for unknown messages
    return Icons.check_circle;
  }

  Color _getMessageTextColor(String message) {
    // Check for success indicators first
    if (message.contains('successfully') ||
        message.contains('sent') ||
        message.contains('Success') ||
        message.contains('reset link sent')) {
      return Colors.green[800]!;
    }

    // Check for error indicators
    if (message.contains('not found') ||
        message.contains('No user found') ||
        message.contains('Invalid') ||
        message.contains('error') ||
        message.contains('Error') ||
        message.contains('Network') ||
        message.contains('Server') ||
        message.contains('check and try again')) {
      return Colors.orange[800]!;
    }

    // Default to green for unknown messages
    return Colors.green[800]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1552664730-d307ca884978?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header with Lock Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Enter your email to receive a reset link',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Email Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'example@gmail.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) => email = value,
                            onFieldSubmitted: (_) => handleSubmit(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      // Message Display
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getMessageColor(message),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getMessageBorderColor(message),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getMessageIcon(message),
                                color: _getMessageTextColor(message),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    color: _getMessageTextColor(message),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Back to Login
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Back to login',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
