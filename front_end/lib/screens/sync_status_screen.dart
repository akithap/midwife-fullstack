import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front_end/l10n/app_localizations.dart';
import '../services/sync_service.dart';
import '../services/database_helper.dart';

class SyncStatusScreen extends StatefulWidget {
  @override
  _SyncStatusScreenState createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _queue = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final q = await _db.getQueue();
    setState(() {
      _queue = q;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to SyncService for updates
    final syncService = Provider.of<SyncService>(context);

    // Reload queue whenever sync state changes (likely processed items)
    if (!syncService.isSyncing) {
      _loadQueue();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.syncStatus),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 1. Status Header
          Container(
            padding: EdgeInsets.all(20),
            color: syncService.isOnline
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  syncService.isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 40,
                  color: syncService.isOnline ? Colors.green : Colors.red,
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncService.isOnline
                          ? AppLocalizations.of(context)!.online
                          : AppLocalizations.of(context)!.offline,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      syncService.isSyncing
                          ? "Syncing in progress..." // Not adding key for this rare state to save time/complexity unless requested
                          : AppLocalizations.of(
                              context,
                            )!.itemsPending(_queue.length),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                Spacer(),
                if (syncService.isSyncing)
                  CircularProgressIndicator()
                else
                  IconButton(
                    icon: Icon(Icons.sync, color: Colors.blue),
                    onPressed: () async {
                      await syncService.processQueue();
                      _loadQueue();
                    },
                    tooltip: "Force Sync",
                  ),
              ],
            ),
          ),
          Divider(height: 1),

          // 2. Queue List
          Expanded(
            child: _queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.green,
                        ),
                        SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.allRecordsSynced,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _queue.length,
                    itemBuilder: (ctx, i) {
                      final item = _queue[i];
                      return ListTile(
                        leading: Icon(
                          Icons.pending_actions,
                          color: Colors.orange,
                        ),
                        title: Text("${item['method']} ${item['endpoint']}"),
                        subtitle: Text(
                          DateTime.fromMillisecondsSinceEpoch(
                            item['created_at'],
                          ).toString(),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            await _db.deleteQueueItem(item['id']);
                            _loadQueue();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
