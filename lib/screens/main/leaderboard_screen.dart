import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:finalchat/services/api_service.dart';
import 'package:finalchat/screens/main/main_screen.dart';
import '../auth/pending.dart';

class DiamondHistory {
  final int id;
  final int userId;
  final String datetime;
  final int amount;
  final String status;

  DiamondHistory({
    required this.id,
    required this.userId,
    required this.datetime,
    required this.amount,
    required this.status,
  });

  factory DiamondHistory.fromJson(Map<String, dynamic> json) {
    return DiamondHistory(
      id: json['id'],
      userId: json['user_id'],
      datetime: json['datetime'],
      amount: json['amount'],
      status: json['status'],
    );
  }
}

class User {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String phoneNumber;
  final String? profilePic;
  final int diamonds;
  final bool isOnline;
  final int creditedDiamonds;
  final int debitedDiamonds;

  User({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    required this.phoneNumber,
    this.profilePic,
    required this.diamonds,
    required this.isOnline,
    this.creditedDiamonds = 0,
    this.debitedDiamonds = 0,
  });

  factory User.fromJson(Map<String, dynamic> userJson, Map<String, dynamic> summary) {
    return User(
      id: userJson['id'],
      firstName: userJson['first_name'],
      lastName: userJson['last_name'],
      username: userJson['username'],
      phoneNumber: userJson['phone_number'],
      profilePic: userJson['profile_pic'],
      diamonds: userJson['diamonds'] ?? 0,
      isOnline: userJson['is_online'] ?? false,
      creditedDiamonds: summary['total_credited'] ?? 0,
      debitedDiamonds: summary['total_debited'] ?? 0,
    );
  }

  ImageProvider? getProfileImage() {
    if (profilePic != null && profilePic!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(profilePic!));
      } catch (e) {
        print('Error decoding profile image: $e');
        return null;
      }
    }
    return null;
  }

  String getDisplayName() {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    } else if (username != null && username!.isNotEmpty) {
      return username!;
    }
    return 'User${id}';
  }

  String getFormattedDiamonds() {
    if (diamonds >= 1000) {
      double k = diamonds / 1000.0;
      return '${k.toStringAsFixed(1)}K';
    }
    return diamonds.toString();
  }

  String getFormattedCreditedDiamonds() {
    if (creditedDiamonds >= 1000) {
      double k = creditedDiamonds / 1000.0;
      return '${k.toStringAsFixed(1)}K';
    }
    return creditedDiamonds.toString();
  }

  String getFormattedDebitedDiamonds() {
    if (debitedDiamonds >= 1000) {
      double k = debitedDiamonds / 1000.0;
      return '${k.toStringAsFixed(1)}K';
    }
    return debitedDiamonds.toString();
  }
}

enum FilterType { total, credited, debited }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

enum PeriodType { daily, weekly, monthly }

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> users = [];
  List<User> filteredUsers = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUserData;
  bool isCurrentUserLoading = true;
  FilterType selectedFilter = FilterType.total;
  PeriodType selectedPeriod = PeriodType.daily;

  @override
  void initState() {
    super.initState();
    _checkUserActive();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchLeaderboard();
    _fetchCurrentUser();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      selectedPeriod = PeriodType.values[_tabController.index];
      isLoading = true;
    });
    _fetchLeaderboard();
  }

  void _checkUserActive() async {
    final isActive = await ApiService.isCurrentUserActive();
    if (!isActive && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PendingScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await ApiService.getCurrentUser();
      setState(() {
        currentUserData = user;
        isCurrentUserLoading = false;
      });
    } catch (e) {
      setState(() {
        isCurrentUserLoading = false;
      });
    }
  }

  String _periodToString(PeriodType period) {
    switch (period) {
      case PeriodType.daily:
        return 'daily';
      case PeriodType.weekly:
        return 'weekly';
      case PeriodType.monthly:
        return 'monthly';
    }
  }

  Future<void> _fetchLeaderboard() async {
    final periodStr = _periodToString(selectedPeriod);
    try {
      final response = await http.get(
        Uri.parse('https://server.bharathchat.com/user-diamond-history?period=$periodStr'),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<User> loadedUsers = [];
        for (var entry in data['users']) {
          final userJson = entry['user'];
          final summary = entry['summary'];
          loadedUsers.add(User.fromJson(userJson, summary));
        }
        setState(() {
          users = loadedUsers;
          _applyFilter();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      switch (selectedFilter) {
        case FilterType.total:
          filteredUsers = List.from(users);
          filteredUsers.sort((a, b) => b.diamonds.compareTo(a.diamonds));
          break;
        case FilterType.credited:
          filteredUsers = List.from(users);
          filteredUsers.sort((a, b) => b.creditedDiamonds.compareTo(a.creditedDiamonds));
          break;
        case FilterType.debited:
          filteredUsers = List.from(users);
          filteredUsers.sort((a, b) => b.debitedDiamonds.compareTo(a.debitedDiamonds));
          break;
      }
    });
  }

  String _getFilterValue(User user) {
    switch (selectedFilter) {
      case FilterType.total:
        return user.getFormattedDiamonds();
      case FilterType.credited:
        return user.getFormattedCreditedDiamonds();
      case FilterType.debited:
        return user.getFormattedDebitedDiamonds();
    }
  }

  String _getCurrentUserFilterValue() {
    if (currentUserData == null) return '0';
    final currentUser = users.firstWhere(
      (u) => u.id == currentUserData!['id'],
      orElse: () => User(
        id: currentUserData!['id'],
        firstName: currentUserData!['first_name'],
        lastName: currentUserData!['last_name'],
        username: currentUserData!['username'],
        phoneNumber: currentUserData!['phone_number'],
        profilePic: currentUserData!['profile_pic'],
        diamonds: currentUserData!['diamonds'] ?? 0,
        isOnline: currentUserData!['is_online'] ?? false,
      ),
    );
    return _getFilterValue(currentUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          ),
        ),
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add any action icons here if needed
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Filter buttons
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton(
                        'Total',
                        FilterType.total,
                        selectedFilter == FilterType.total,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        'Credited',
                        FilterType.credited,
                        selectedFilter == FilterType.credited,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        'Debited',
                        FilterType.debited,
                        selectedFilter == FilterType.debited,
                      ),
                    ),
                  ],
                ),
              ),
              // Time period tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.orange,
                  indicatorWeight: 3,
                  labelColor: Colors.orange,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelColor: Colors.white54,
                  isScrollable: false,
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : Column(
                children: [
                  SizedBox(height: 15),
                  if (filteredUsers.length >= 3) _buildPodium(filteredUsers.sublist(0, 3)),
                  Expanded(
                    child: _buildLeaderboardList(
                      filteredUsers.length > 3 ? filteredUsers.sublist(3) : [],
                    ),
                  ),
                  if (currentUserData != null) _buildBottomBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.access_time, color: Colors.grey, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Leaderboard updates every 15 min',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildFilterButton(String text, FilterType filterType, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filterType;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<User> top3) {
    return Container(
      // No fixed height
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background decoration
          Container(
            height: 60, // Reduced from 120 to 60
            margin: const EdgeInsets.only(top: 40), // Reduced top margin
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.yellow[600]!.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.center,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Users
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              _buildPodiumUser(
                top3[1],
                2,
                40,
                Colors.grey[400]!,
                false,
              ), // height reduced
              const SizedBox(width: 12),
              // 1st place
              _buildPodiumUser(
                top3[0],
                1,
                60,
                const Color(0xFFFFC107),
                true,
              ), // height reduced
              const SizedBox(width: 12),
              // 3rd place
              _buildPodiumUser(
                top3[2],
                3,
                40,
                Colors.orange[400]!,
                false,
              ), // height reduced
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(
    User user,
    int rank,
    double podiumHeight,
    Color color,
    bool isFirst,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown for first place
        if (isFirst)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Image.asset(
              'assets/crown.png', // You'll need to add crown asset
              width: 30,
              height: 25,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.emoji_events,
                  color: Colors.yellow,
                  size: 30,
                );
              },
            ),
          ),
        // User avatar with decorative frame
        Container(
          width: isFirst ? 80 : 70,
          height: isFirst ? 80 : 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isFirst ? 37 : 32,
            backgroundColor: Colors.grey[800],
            backgroundImage: user.getProfileImage(),
            child:
                user.getProfileImage() == null
                    ? Text(
                      user.getDisplayName().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isFirst ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
        ),
        const SizedBox(height: 8),
        // User name
        Text(
          user.getDisplayName(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Diamond count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, color: Colors.purple, size: 16),
              const SizedBox(width: 4),
              Text(
                _getFilterValue(user),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Podium base
        Container(
          height: podiumHeight,
          width: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Follow button
        // ElevatedButton(
        //   onPressed: () {},
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: color,
        //     foregroundColor: Colors.black,
        //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        //     minimumSize: const Size(70, 28),
        //     elevation: 0,
        //   ),
        //   child: const Text(
        //     '+ Follow',
        //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildLeaderboardList(List<User> usersBelow) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: usersBelow.length,
      itemBuilder: (context, index) {
        final user = usersBelow[index];
        final rank = index + 4;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[700],
                backgroundImage: user.getProfileImage(),
                child:
                    user.getProfileImage() == null
                        ? Text(
                          user.getDisplayName().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  user.getDisplayName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getFilterValue(user),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.diamond, color: Colors.purple, size: 18),
                ],
              ),
              const SizedBox(width: 16),
              // ElevatedButton(
              //   onPressed: () {},
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.grey[800],
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //     minimumSize: const Size(80, 32),
              //     elevation: 0,
              //   ),
              //   child: const Text(
              //     '+ Follow',
              //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    if (isCurrentUserLoading || currentUserData == null) {
      return const SizedBox.shrink();
    }
    ImageProvider? profileImage;
    if (currentUserData!['profile_pic'] != null &&
        currentUserData!['profile_pic'].toString().isNotEmpty) {
      try {
        profileImage = MemoryImage(
          base64Decode(currentUserData!['profile_pic']),
        );
      } catch (e) {
        profileImage = null;
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[700],
            backgroundImage: profileImage,
            child:
                profileImage == null
                    ? Text(
                      (currentUserData!['first_name'] ?? 'U')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          const Text(
            'You',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getCurrentUserFilterValue(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.diamond, color: Colors.purple, size: 18),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFffa030),
                  Color(0xFFfe9b00),
                  Color(0xFFf67d00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gift Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
