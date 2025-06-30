import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'login_screen.dart';

class VerifyResetScreen extends StatefulWidget {
  final String email;

  const VerifyResetScreen({Key? key, required this.email}) : super(key: key);

  @override
  _VerifyResetScreenState createState() => _VerifyResetScreenState();
}

class _VerifyResetScreenState extends State<VerifyResetScreen> {
  final ApiService apiService = ApiService();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _otpError;
  String? _passwordError;
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  'Password Reset Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'You can now login with your new password',
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

  void _verifyAndReset() async {
    // Reset error messages
    setState(() {
      _otpError = null;
      _passwordError = null;
    });

    // Get OTP from controllers
    String otp = _otpControllers.map((c) => c.text).join();

    // Validate OTP
    if (otp.length != 6) {
      setState(() {
        _otpError = 'Please enter the complete OTP';
      });
      return;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Please enter a new password';
      });
      return;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters long';
      });
      return;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.verifyAndResetPassword({
        'email': widget.email,
        'otp': otp,
        'new_password': _passwordController.text,
      });
      _showSuccessDialog();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('otp')) {
        setState(() {
          _otpError = errorMessage;
        });
      } else {
        setState(() {
          _passwordError = errorMessage;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(
              color: _otpError != null ? Colors.red : Colors.grey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify & Reset'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter OTP Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter the OTP code sent to ${widget.email}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),
            _buildOTPFields(),
            if (_otpError != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  _otpError!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(height: 32),
            Text(
              'New Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter new password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                errorText: _passwordError,
              ),
            ),
            SizedBox(height: 32),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifyAndReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Reset Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
} 