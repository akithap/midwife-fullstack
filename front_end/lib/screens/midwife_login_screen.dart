import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front_end/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class MidwifeLoginScreen extends StatefulWidget {
  @override
  _MidwifeLoginScreenState createState() => _MidwifeLoginScreenState();
}

class _MidwifeLoginScreenState extends State<MidwifeLoginScreen> {
  // We can pre-fill this to make testing faster
  final _usernameController = TextEditingController(text: "midwife1");
  final _passwordController = TextEditingController(text: "password123");
  bool _isLoading = false;

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    // Call the *midwifeLogin* function
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.midwifeLogin(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      // Check if the widget is still on screen
      setState(() {
        _isLoading = false;
      });
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginFailed),
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
        title: Text(AppLocalizations.of(context)!.midwifePortalLogin),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.username,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.password,
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => _login(context),
                    child: Text(AppLocalizations.of(context)!.loginAsMidwife),
                  ),
          ],
        ),
      ),
    );
  }
}
