import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final ApiService apiService = ApiService();
  final bool useRealApi = true;
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green[50],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Registration Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Welcome to Kilimolink\nPlease login to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );

    // Navigate to login screen after a short delay
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    });
  }

  void _signup() async {
    // Reset error messages
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
    });

    // Validate name
    if (_nameController.text.isEmpty) {
      setState(() {
        _nameError = 'Please enter your full name';
      });
      return;
    }

    // Validate email
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email';
      });
      return;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      return;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Please enter a password';
      });
      return;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters long';
      });
      return;
    }

    // Validate phone number if provided
    if (_phoneNumberController.text.isNotEmpty && 
        !RegExp(r'^\+?[\d\s-]+$').hasMatch(_phoneNumberController.text)) {
      setState(() {
        _phoneError = 'Please enter a valid phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = useRealApi
          ? await apiService.signupFromApi(
              _nameController.text,
              _phoneNumberController.text,
              _emailController.text,
              _passwordController.text,
            )
          : await apiService.signup(
              _nameController.text,
              _phoneNumberController.text,
              _emailController.text,
              _passwordController.text,
            );
      
      if (success) {
        _showSuccessDialog();
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('name')) {
        setState(() {
          _nameError = errorMessage;
        });
      } else if (errorMessage.toLowerCase().contains('phone')) {
        setState(() {
          _phoneError = errorMessage;
        });
      } else if (errorMessage.toLowerCase().contains('email')) {
        setState(() {
          _emailError = errorMessage;
        });
      } else if (errorMessage.toLowerCase().contains('password')) {
        setState(() {
          _passwordError = errorMessage;
        });
      } else {
        setState(() {
          _emailError = errorMessage;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SIGN UP'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'create an account',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'full name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorText: _nameError,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'phone number (optional)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorText: _phoneError,
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'email *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorText: _emailError,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'password * (min 6 characters)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorText: _passwordError,
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'sign up',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('already have an account? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}