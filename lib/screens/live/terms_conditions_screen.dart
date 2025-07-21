import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181F2A),
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _section(
              '1. Acceptance of Terms',
              'By accessing and using BharathChat’s video calling services, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            _section(
              '2. Use License',
              'Permission is granted to temporarily download one copy of BharathChat for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not modify or copy the materials.',
            ),
            _section(
              '3. Disclaimer',
              'The materials on BharathChat are provided on an ‘as is’ basis. BharathChat makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including without limitation, implied warranties or conditions of merchantability.',
            ),
            _section(
              '4. Limitations',
              'In no event shall BharathChat or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on BharathChat’s platform.',
            ),
            _section(
              '5. Accuracy of Materials',
              'The materials appearing on BharathChat could include technical, typographical, or photographic errors. BharathChat does not warrant that any of the materials on its platform are accurate, complete, or current.',
            ),
            _section(
              '6. Governing Law',
              'These Terms are governed by and construed in accordance with the laws of the Republic of India. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts located in Bengaluru, Karnataka.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF232B39),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
