import 'package:flutter/material.dart';
import '../services/api_service.dart';

import '../models/mother.dart';

class RegisterMotherScreen extends StatefulWidget {
  final Mother? motherToEdit; // using Mother model

  RegisterMotherScreen({this.motherToEdit});

  @override
  _RegisterMotherScreenState createState() => _RegisterMotherScreenState();
}

class _RegisterMotherScreenState extends State<RegisterMotherScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.motherToEdit != null) {
      _isEditing = true;
      _nameController.text = widget.motherToEdit!.fullName;
      _nicController.text = widget.motherToEdit!.nic;
      _addressController.text = widget.motherToEdit!.address;
      _contactController.text = widget.motherToEdit!.contactNumber;
      // Password is NOT loaded for security
    }
  }

  Future<void> _saveMother() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> data = {
      'full_name': _nameController.text,
      'address': _addressController.text,
      'contact_number': _contactController.text,
    };

    bool success;
    if (_isEditing) {
      // Update existing
      // Note: We don't send NIC or Password on update
      success = await _apiService.updateMother(widget.motherToEdit!.id, data);
    } else {
      // Create new
      data['nic'] = _nicController.text;
      data['password'] = _passwordController.text;
      success = await _apiService.createMother(data);
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Mother updated!' : 'Mother registered!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return "true" to signal refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed. Please check inputs.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Mother Details' : 'Register New Mother'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (val) => val!.isEmpty ? 'Name is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nicController,
                decoration: InputDecoration(labelText: 'NIC Number'),
                enabled: !_isEditing, // NIC cannot be changed if editing
                validator: (val) => val!.isEmpty ? 'NIC is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
              ),
              if (!_isEditing) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Temporary Password'),
                  obscureText: true,
                  validator: (val) =>
                      val!.isEmpty ? 'Password is required' : null,
                ),
              ],
              SizedBox(height: 32),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveMother,
                      child: Text(
                        _isEditing ? 'Update Details' : 'Register Mother',
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
