import 'package:flutter/material.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({Key? key}) : super(key: key);

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
                _NumberedText(number: 1, text: 'Sync Your Phonebook Contacts'),
                SizedBox(height: 12),
                _NumberedText(
                  number: 2,
                  text:
                      'Get Contact to install Bharath Chat using your Referral Link',
                ),
                SizedBox(height: 12),
                _NumberedText(
                  number: 3,
                  text:
                      'Earn ₹7 PayTm Cash for each successful referral. Amount is credited when your friend attends 1 Live Sessions.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Sync Contacts button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Sync Contacts',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Share Link button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
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
