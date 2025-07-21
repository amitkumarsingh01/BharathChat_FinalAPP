import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InviteScreen extends StatefulWidget {
  const InviteScreen({Key? key}) : super(key: key);

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  String? _shareUrl;
  bool _loading = false;

  Future<void> _fetchShareUrlAndShare() async {
    setState(() {
      _loading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://server.bharathchat.com/single-url'),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['url'] as String?;
        if (url != null) {
          setState(() {
            _shareUrl = url;
          });
          Share.share(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get share URL.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch URL: \\${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \\${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invite',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Smiley icons with sparkles (placeholder)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.emoji_emotions,
                    color: Colors.white,
                    size: 64,
                  ),
                  Positioned(
                    top: 8,
                    right: 0,
                    child: Icon(Icons.star, color: Colors.amber[300], size: 16),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    child: Icon(Icons.star, color: Colors.amber[300], size: 12),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                  Positioned(
                    top: 8,
                    left: 0,
                    child: Icon(Icons.star, color: Colors.amber[300], size: 16),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 0,
                    child: Icon(Icons.star, color: Colors.amber[300], size: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Numbered instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _NumberedText(number: 1, text: 'Invite Friends to Bharath Chat!'),
                SizedBox(height: 12),
                _NumberedText(
                  number: 2,
                  text:
                      'Share your unique referral link with your friends and family.',
                ),
                SizedBox(height: 12),
                _NumberedText(
                  number: 3,
                  text:
                      'When someone clicks your link, they’ll be redirected to the Play Store to download the Bharath Chat app.',
                ),
                SizedBox(height: 12),
                _NumberedText(
                  number: 4,
                  text:
                      'It’s quick, easy, and a great way to grow our community!',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        
          const SizedBox(height: 16),
          // Share Link button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _loading ? null : _fetchShareUrlAndShare,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Share Link',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedText extends StatelessWidget {
  final int number;
  final String text;
  const _NumberedText({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
