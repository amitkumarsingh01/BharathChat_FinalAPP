import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import 'main_screen.dart';
import '../auth/pending.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<dynamic> _shopItems = [];
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _checkUserActive();
    _loadShopItems();
    _loadUserData();
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

  void _loadUserData() async {
    try {
      final user = await ApiService.getCurrentUser();
      setState(() {
        _user = user;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _loadShopItems() async {
    try {
      final response = await http.get(
        Uri.parse('https://server.bharathchat.com/shop/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        setState(() {
          _shopItems = items;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load shop items');
      }
    } catch (e) {
      print('Error loading shop items: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load shop items. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _buyDiamonds(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Buy Diamonds',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Image.asset('assets/diamond.png', width: 50, height: 50),
                  const SizedBox(width: 12),
                  Text(
                    '${item['diamond_count']} Diamonds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Price: ₹${item['discounted_price']}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPurchase(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                elevation: 4,
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

void _processPurchase(Map<String, dynamic> item) async {
  try {
    final user = await ApiService.getCurrentUser();
    final userId = user['id'];
    final shopId = item['id'] ?? item['shop_id'];
    
    print('Input user: ' + user.toString());
    print('Input userId: ' + userId.toString());
    print('Input shopId: ' + shopId.toString());
    print('Input item: ' + item.toString());
    
    final response = await http.post(
      Uri.parse('https://server.bharathchat.com/initiate-shop-payment'),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'shop_id': shopId,
      }),
    );
    
    print('API response status: ${response.statusCode}');
    print('API response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final redirectUrl = data['redirect_url'];
      
      print('redirectUrl: $redirectUrl');
      
      if (redirectUrl != null) {
        print('Trying to launch: $redirectUrl');
        
        // Try different launch modes
        try {
          // Method 1: Try external application first
          final launched = await launchUrl(
            Uri.parse(redirectUrl),
            mode: LaunchMode.externalApplication,
          );
          
          if (!launched) {
            // Method 2: Try platform default
            final launched2 = await launchUrl(
              Uri.parse(redirectUrl),
              mode: LaunchMode.platformDefault,
            );
            
            if (!launched2) {
              // Method 3: Try in-app web view as fallback
              await launchUrl(
                Uri.parse(redirectUrl),
                mode: LaunchMode.inAppWebView,
              );
            }
          }
          
          print('Payment URL launched successfully');
          
        } catch (launchError) {
          print('Error launching URL: $launchError');
          
          // Fallback: Show a dialog with the URL for manual opening
          _showManualUrlDialog(redirectUrl);
        }
      } else {
        print('No redirect URL received in response');
        throw Exception('No redirect URL received');
      }
    } else {
      print('Failed to initiate payment, status: ${response.statusCode}');
      throw Exception('Failed to initiate payment');
    }
  } catch (e) {
    print('Error in _processPurchase: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Purchase failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Add this helper method to show manual URL dialog
void _showManualUrlDialog(String url) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Complete Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please copy and paste this URL in your browser to complete the payment:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SelectableText(
              url,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy URL to clipboard
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment URL copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Copy URL',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232526), Color(0xFF414345)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF23272F),
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: const Text(
            'Diamond Store',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
                : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // My Balance Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'My Balance: ${_user?['diamonds'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Image.asset(
                                'assets/diamond.png',
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.7),
                                Colors.deepOrange.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/diamond.png',
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Buy Diamonds to Send Gifts!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 18,
                                childAspectRatio:
                                    0.55, // Lowered for more height
                              ),
                          itemCount: _shopItems.length,
                          itemBuilder: (context, index) {
                            final item = _shopItems[index];
                            return GestureDetector(
                              onTap: () => _buyDiamonds(item),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[900]!,
                                      Colors.grey[850]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    8,
                                  ), // Reduced padding
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(
                                                0.4,
                                              ),
                                              blurRadius: 18,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/diamond.png',
                                          width: 50, // Slightly smaller
                                          height: 55,
                                        ),
                                      ),
                                      Text(
                                        '${item['diamond_count']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22, // Slightly smaller
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Diamonds',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16, // Slightly smaller
                                        ),
                                      ),
                                      if (item['total_price'] !=
                                          item['discounted_price'])
                                        Text(
                                          '₹${item['total_price']}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12, // Slightly smaller
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ), // Reduced
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ), // Reduced
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          '₹${item['discounted_price']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16, // Slightly smaller
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _buyDiamonds(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(0, 0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Image.asset(
                                          'assets/buynow.png',
                                          height:
                                              43, // Set to actual image height if known
                                          width:
                                              125, // Set to actual image width if known
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
