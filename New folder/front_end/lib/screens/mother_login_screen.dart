import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MotherLoginScreen extends StatefulWidget {
  @override
  _MotherLoginScreenState createState() => _MotherLoginScreenState();
}

class _MotherLoginScreenState extends State<MotherLoginScreen> {
  // Pre-fill with the test mother you created
  final _nicController = TextEditingController(text: "123456789V");
  final _passwordController = TextEditingController(
    text: "mother_password_123",
  );
  bool _isLoading = false;

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    // Call the *motherLogin* function
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.motherLogin(
      _nicController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Pop the login screen off the stack if successful
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mother Portal Login'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // This UI matches your mockup
            TextField(
              controller: _nicController,
              decoration: InputDecoration(
                labelText: 'NIC Number',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                    ),
                    onPressed: () => _login(context),
                    child: Text('Login as Mother'),
                  ),
          ],
        ),
      ),
    );
  }
}
