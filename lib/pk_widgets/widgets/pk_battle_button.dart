import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PKBattleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final void Function(String)? onInvite;
  const PKBattleButton({Key? key, this.onPressed, this.onInvite})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFffa030), Color(0xFFfe9b00), Color(0xFFf67d00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ElevatedButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PKBattleModal(onInvite: onInvite),
          );
          if (onPressed != null) onPressed!();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'PK Battle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class PKBattleModal extends StatefulWidget {
  final void Function(String)? onInvite;
  const PKBattleModal({Key? key, this.onInvite}) : super(key: key);

  @override
  State<PKBattleModal> createState() => _PKBattleModalState();
}

class _PKBattleModalState extends State<PKBattleModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;
  String? _userError;
  final List<Map<String, String>> _pkRequests = [
    {'name': 'Amit', 'followers': '2.1K'},
    {'name': 'Priya', 'followers': '1.2K'},
  ];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loadingUsers = true;
      _userError = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://server.bharathchat.com/user/minimal'),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _users = data.map((u) => u as Map<String, dynamic>).toList();
          _loadingUsers = false;
        });
      } else {
        setState(() {
          _userError = 'Failed to load users';
          _loadingUsers = false;
        });
      }
    } catch (e) {
      setState(() {
        _userError = 'Error: $e';
        _loadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name =
          (user['username'] ?? user['username'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, String>> get _filteredPKRequests {
    if (_searchQuery.isEmpty) return _pkRequests;
    return _pkRequests
        .where((req) => req['name']!.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'PK Battle',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicatorColor: Color(0xFFffa030),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: [Tab(text: 'Invite')],
          ),
          const SizedBox(height: 8),
          Container(height: 2, color: Colors.grey[800]),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Invite Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _loadingUsers
                              ? const Center(child: CircularProgressIndicator())
                              : _userError != null
                              ? Center(
                                child: Text(
                                  _userError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                              : _filteredUsers.isEmpty
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.mail_outline,
                                    color: Colors.white38,
                                    size: 64,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No Requests received',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              )
                              : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _filteredUsers.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  final displayName =
                                      (user['first_name'] ??
                                              user['username'] ??
                                              'User')
                                          .toString();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.grey[700],
                                          child: Text(
                                            displayName[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (user['username'] != null)
                                                Text(
                                                  '@${user['username']}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[700]!,
                                            ),
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              if (widget.onInvite != null) {
                                                // Pass username instead of displayName
                                                final username =
                                                    user['username']
                                                        ?.toString() ??
                                                    '';
                                                widget.onInvite!(username);
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            child: const Text(
                                              'Invite',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Invite Hosts to start PK battle',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
