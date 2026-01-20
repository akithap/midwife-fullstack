import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_mother_screen.dart';
import '../models/mother.dart';
import 'mother_care_screen.dart';
import 'dart:async'; // Import needed for 'Timer'
import 'chat_screen.dart';
import '../enums/user_role.dart';

class MotherListScreen extends StatefulWidget {
  @override
  _MotherListScreenState createState() => _MotherListScreenState();
}

class _MotherListScreenState extends State<MotherListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Mother>> _mothersFuture;
  Timer? _debounce; // Timer to wait before searching

  @override
  void initState() {
    super.initState();
    _loadMothers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMothers({String? query}) {
    setState(() {
      _mothersFuture = _apiService.getMothers(query: query);
    });
  }

  // NEW: Search as you type function
  void _onSearchChanged(String query) {
    // Cancel the previous timer (if the user is still typing)
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Wait for 500ms of silence, then run the search
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadMothers(query: query);
    });
  }

  void _navigateToRegister({Mother? mother}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterMotherScreen(motherToEdit: mother),
      ),
    );

    if (result == true) {
      _loadMothers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Mothers'),
        // backgroundColor: Colors.teal, // Handled by theme
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name or NIC...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadMothers(); // Reset list
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // FIX: Use onChanged instead of onSubmitted
              onChanged: _onSearchChanged,
            ),
          ),

          // --- List of Mothers ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadMothers(),
              child: FutureBuilder<List<Mother>>(
                future: _mothersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No mothers found.'));
                  }

                  final mothers = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.only(bottom: 80), // Prevent FAB overlap
                    itemCount: mothers.length,
                    itemBuilder: (context, index) {
                      final mother = mothers[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            // Dynamic color with opacity
                            backgroundColor: theme.primaryColor.withOpacity(
                              0.2,
                            ),
                            child: Text(
                              mother.fullName.isNotEmpty
                                  ? mother.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            mother.fullName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            children: [
                              Text(mother.nic),
                              SizedBox(width: 8),
                              // Status Chip
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: mother.status == 'Pregnant'
                                      ? Colors.pinkAccent.withOpacity(
                                          0.2,
                                        ) // Softer for dark mode
                                      : mother.status == 'Postnatal'
                                      ? Colors.green.withOpacity(0.2)
                                      : theme.disabledColor.withOpacity(
                                          0.2,
                                        ), // Default grey adjusted
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  mother.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    // Ensure text is readable on the background
                                    color: mother.status == 'Pregnant'
                                        ? Colors.pinkAccent
                                        : mother.status == 'Postnatal'
                                        ? Colors.green
                                        : theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                              // RISK CHIP (Only if Pregnant or pertinent)
                              if (mother.status == 'Pregnant') ...[
                                SizedBox(width: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mother.riskLevel == 'High'
                                        ? Colors.red
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    mother.riskLevel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: 'Chat',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        otherUserId: mother.id,
                                        otherUserName: mother.fullName,
                                        myRole: UserRole.midwife,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.grey),
                                tooltip: 'Edit',
                                onPressed: () =>
                                    _navigateToRegister(mother: mother),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MotherCareScreen(mother: mother),
                              ),
                            ).then(
                              (_) => _loadMothers(),
                            ); // Refresh list on return (status might change)
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRegister(),
        backgroundColor: theme.primaryColor, // Use theme primary
        child: Icon(Icons.person_add),
        tooltip: 'Register New Mother',
      ),
    );
  }
}
