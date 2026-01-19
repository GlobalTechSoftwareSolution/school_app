import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int currentStep = 1;
  String email = '';
  String password = '';
  String confirmPassword = '';
  String role = 'Student';
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool loading = false;

  final List<String> roles = [
    'Student',
    'Teacher',
    'Admin',
    'Management',
    'Principal',
    'Parent',
  ];

  void showDialogMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void nextStep() {
    if (currentStep == 1) {
      if (email.isEmpty || !email.contains('@')) {
        showDialogMessage(
          'Invalid Email',
          'Please enter a valid email address',
        );
        return;
      }
      if (password.isEmpty || password.length < 6) {
        showDialogMessage(
          'Invalid Password',
          'Password must be at least 6 characters long',
        );
        return;
      }
      if (password != confirmPassword) {
        showDialogMessage('Password Mismatch', 'Passwords do not match');
        return;
      }
    }
    if (currentStep < 2) {
      setState(() => currentStep++);
    }
  }

  void prevStep() {
    if (currentStep > 1) {
      setState(() => currentStep--);
    }
  }

  Future<void> signup() async {
    if (password != confirmPassword) {
      showDialogMessage('Passwords do not match!', '');
      return;
    }

    if (password.length < 6) {
      showDialogMessage('Password must be at least 6 characters long', '');
      return;
    }

    setState(() => loading = true);

    try {
      final payload = {
        'email': email,
        'password': password,
        'password2': confirmPassword,
        'role': role,
      };

      final res = await http.post(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/signup/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        showDialogMessage(
          'Registration successful!',
          'Please check your email for verification.',
        );
        // Navigate back to login
        Navigator.of(context).pop();
      } else {
        // Handle different error cases
        if (data['email'] != null) {
          showDialogMessage('Email error', data['email'][0]);
        } else if (data['password'] != null) {
          showDialogMessage('Password error', data['password'][0]);
        } else if (data['non_field_errors'] != null) {
          showDialogMessage('Error', data['non_field_errors'][0]);
        } else {
          showDialogMessage('Registration failed. Please try again.', '');
        }
      }
    } catch (error) {
      print('Registration error: $error');
      showDialogMessage(
        'An error occurred during registration. Please try again.',
        '',
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'EduPortal',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Welcome back to your learning adventure!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) {
                      int stepNumber = index + 1;
                      bool isActive = stepNumber == currentStep;
                      bool isCompleted = stepNumber < currentStep;

                      return Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? Colors.green
                                  : isActive
                                  ? Colors.blue
                                  : Colors.grey[300],
                            ),
                            child: Center(
                              child: Text(
                                stepNumber.toString(),
                                style: TextStyle(
                                  color: isCompleted || isActive
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (index < 1)
                            Container(
                              width: 60,
                              height: 2,
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.grey[300],
                            ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Step Titles
                  Text(
                    currentStep == 1 ? 'Account Information' : 'Complete Setup',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentStep == 1) ...[
                          // Step 1: Basic Info
                          const Text(
                            'Create Your Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) => email = value,
                          ),

                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Create Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => showPassword = !showPassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            obscureText: !showPassword,
                            onChanged: (value) => password = value,
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => showConfirmPassword =
                                      !showConfirmPassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            obscureText: !showConfirmPassword,
                            onChanged: (value) => confirmPassword = value,
                          ),
                        ] else ...[
                          // Step 2: Role Selection
                          const Text(
                            'Select Your Role',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          DropdownButtonFormField<String>(
                            value: role,
                            decoration: InputDecoration(
                              labelText: 'Choose Your Role',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: roles.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() => role = newValue!);
                            },
                          ),

                          const SizedBox(height: 20),

                          // Role Description
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$role Account',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  role == 'Student'
                                      ? 'Get access to courses, assignments, and learning materials.'
                                      : role == 'Teacher'
                                      ? 'Create courses, manage students, and track progress.'
                                      : 'Manage the platform, users, and system settings.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),

                        // Navigation Buttons
                        Row(
                          children: [
                            if (currentStep > 1)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: prevStep,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            if (currentStep > 1) const SizedBox(width: 16),

                            Expanded(
                              child: ElevatedButton(
                                onPressed: currentStep == 2
                                    ? (loading ? null : signup)
                                    : nextStep,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: currentStep == 2
                                      ? Colors.green
                                      : Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: loading
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
                                    : Text(
                                        currentStep == 2
                                            ? 'Create Account'
                                            : 'Continue',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Login Link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: Colors.grey),
                                children: [
                                  TextSpan(
                                    text: 'Sign in here',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
    );
  }
}
