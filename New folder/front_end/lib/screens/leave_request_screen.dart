import 'package:flutter/material.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  @override
  _LeaveRequestScreenState createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final ApiService _apiService = ApiService();
  List<LeaveRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _apiService.getLeaveRequests();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showAddRequestDialog() async {
    DateTimeRange? selectedRange;
    final TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Request Leave'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select Date Range:"),
                  TextButton(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (range != null) {
                        setDialogState(() => selectedRange = range);
                      }
                    },
                    child: Text(
                      selectedRange == null
                          ? "Pick Dates"
                          : "${selectedRange!.start.toString().split(' ')[0]} - ${selectedRange!.end.toString().split(' ')[0]}",
                    ),
                  ),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(labelText: 'Reason'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedRange == null || reasonController.text.isEmpty)
                      return;

                    final newReq = LeaveRequest(
                      id: 0,
                      midwifeId: 0,
                      startDate: selectedRange!.start,
                      endDate: selectedRange!.end,
                      reason: reasonController.text,
                      status: "Pending",
                    );

                    bool success = await _apiService.createLeaveRequest(newReq);
                    Navigator.pop(context);
                    if (success) {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Request Submitted")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Submission Failed")),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Leave Requests')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                Color statusColor = Colors.orange;
                if (req.status == 'Approved') statusColor = Colors.green;
                if (req.status == 'Rejected') statusColor = Colors.red;

                return Card(
                  child: ListTile(
                    title: Text(
                      "${req.startDate.toString().split(' ')[0]} to ${req.endDate.toString().split(' ')[0]}",
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Reason: ${req.reason}"),
                        if (req.mohComment != null)
                          Text(
                            "MOH Comment: ${req.mohComment}",
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        req.status,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: statusColor,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRequestDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
