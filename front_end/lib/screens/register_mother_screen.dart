import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import '../services/api_service.dart';
import '../models/mother.dart';

class RegisterMotherScreen extends StatefulWidget {
  final Mother? motherToEdit;

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

  // Location State
  double? _latitude;
  double? _longitude;
  String? _locationStatus;

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

      // We assume Mother model DOES NOT yet have lat/lng in frontend model
      // so we start null or update Mother model later.
      // For now, we only support capturing NEW coordinates.
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationStatus = "Getting location...";
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationStatus = "Location services disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationStatus = "Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationStatus = "Location permanently denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus =
            "Pinned: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}";
      });
    } catch (e) {
      setState(() => _locationStatus = "Error getting location.");
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

    // Add Coordinates if captured
    if (_latitude != null && _longitude != null) {
      data['latitude'] = _latitude;
      data['longitude'] = _longitude;
    }

    bool success;
    if (_isEditing) {
      success = await _apiService.updateMother(widget.motherToEdit!.id, data);
    } else {
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
      Navigator.pop(context, true);
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
                enabled: !_isEditing,
                validator: (val) => val!.isEmpty ? 'NIC is required' : null,
              ),
              SizedBox(height: 16),

              // Address & Location Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Address'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.location_on, color: Colors.red),
                    onPressed: _getCurrentLocation,
                    tooltip: "Pin Current Location",
                  ),
                ],
              ),
              if (_locationStatus != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _locationStatus!,
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
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
