import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  String role = 'Student';
  bool showPassword = false;
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

  Future<void> login() async {
    if (email.isEmpty || password.isEmpty) {
      showDialogMessage("Invalid Input", "Please fill in all fields");
      return;
    }

    setState(() => loading = true);

    try {
      // STEP 1: Login and get user data from login endpoint
      final formattedRole =
          role.substring(0, 1).toUpperCase() + role.substring(1).toLowerCase();

      final loginRes = await http.post(
        Uri.parse(
          'https://school.globaltechsoftwaresolutions.cloud/api/login/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': formattedRole, // Capitalize role for backend compatibility
        }),
      );

      if (loginRes.statusCode < 200 || loginRes.statusCode >= 300) {
        setState(() => loading = false);
        if (loginRes.statusCode == 401) {
          showDialogMessage(
            "Invalid Credentials",
            "Invalid email or password.",
          );
        } else if (loginRes.statusCode == 400) {
          showDialogMessage(
            "Invalid Input",
            "Please check your email, password or role.",
          );
        } else {
          showDialogMessage("Login Failed", "Login failed. Please try again.");
        }
        return;
      }

      final responseData = jsonDecode(loginRes.body);

      // Extract user data from response
      final userData = responseData['user'] ?? {};

      // Build user info object
      final userInfo = {
        'email': userData['email'] ?? email,
        'role': userData['role'] ?? formattedRole,
        'is_active': userData['is_active'] ?? true,
        'is_approved': userData['is_approved'] ?? true,
      };

      await handleSuccessfulLogin(userInfo);
    } catch (error, stackTrace) {
      setState(() => loading = false);

      // More specific error message
      String errorMessage =
          "Please check your internet connection and try again.";
      if (error.toString().contains('Failed host lookup') ||
          error.toString().contains('SocketException')) {
        errorMessage =
            "Cannot connect to server. Please check:\n"
            "1. Your internet connection\n"
            "2. Try restarting the emulator\n"
            "3. Or test on a real device";
      }

      showDialogMessage("Network Error", errorMessage);
    }
  }

  Future<void> handleSuccessfulLogin(Map<String, dynamic> userData) async {
    // Validate that user has the expected role or is approved
    if (userData['role'] == null) {
      userData['role'] = role;
    }

    // Check if user is approved/has access
    if (userData['is_active'] == false) {
      showDialogMessage(
        "Account Inactive",
        "Your account is inactive. Please contact administrator.",
      );
      setState(() => loading = false);
      return;
    }

    if (userData['is_approved'] == false) {
      showDialogMessage(
        "Approval Pending",
        "Your account is pending approval. Please contact administrator.",
      );
      setState(() => loading = false);
      return;
    }

    // Check if role matches (case-insensitive)
    if (userData['role'].toString().toLowerCase() != role.toLowerCase()) {
      showDialogMessage(
        "Role Mismatch",
        "Your account is registered as ${userData['role']}. Please select the correct role.",
      );
      setState(() => loading = false);
      return;
    }

    // Store user info
    final userInfo = {
      'email': userData['email'],
      'role': userData['role'],
      'is_active': userData['is_active'],
      'is_approved': userData['is_approved'],
      'name':
          (userData['name'] ??
          userData['fullname'] ??
          userData['first_name'] ??
          (userData['email'] != null
              ? userData['email'].toString().split('@')[0]
              : email.split('@')[0])), // better name extraction
    };

    // Save user session to persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', userInfo['email'] ?? email);
    await prefs.setString('user_role', userInfo['role'] ?? role);
    await prefs.setString(
      'user_name',
      userInfo['name'] ?? (email.split('@')[0]),
    );
    await prefs.setBool('user_active', userInfo['is_active'] ?? true);
    await prefs.setBool('user_approved', userInfo['is_approved'] ?? true);
    await prefs.setBool('is_logged_in', true);

    setState(() => loading = false);

    // Redirect based on verified role
    final userRole = (userInfo['role'] ?? '').toString().toLowerCase();

    // Navigate to dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          userRole: userRole,
          userEmail: userInfo['email'] ?? email,
          userName: userInfo['name'] ?? (email.split('@')[0]),
        ),
      ),
    );
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
                  const SizedBox(height: 40),

                  // Logo Section
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Welcome Text
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Login Form
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
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Continue your educational journey',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Role Selector
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: InputDecoration(
                            labelText: 'Select Role',
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

                        const SizedBox(height: 16),

                        // Email Field
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
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

                        // Password Field
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => showPassword = !showPassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: !showPassword,
                          onChanged: (value) => password = value,
                          onFieldSubmitted: (_) => login(),
                        ),

                        const SizedBox(height: 8),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot your password?',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: loading
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
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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
