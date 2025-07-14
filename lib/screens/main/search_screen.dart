import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final users = [
      {
        'name': 'Elvish Yadav',
        'followers': '1.7M Followers',
        'subtitle': '',
        'avatar': null,
        'verified': true,
        'live': false,
      },
      {
        'name': '🍓!_~ƒџůÏť¥ 🧸🍓',
        'followers': '48.6K Followers',
        'subtitle': "dad's_kutty😘🤗",
        'avatar': null,
        'verified': true,
        'live': true,
      },
      {
        'name': 'ALEENA wani',
        'followers': '1.3K Followers',
        'subtitle': '',
        'avatar': null,
        'verified': false,
        'live': false,
      },
      {
        'name': 'tazu sultan',
        'followers': '36.3K Followers',
        'subtitle': '',
        'avatar': null,
        'verified': false,
        'live': true,
      },
      {
        'name': 'pallabi ghosh',
        'followers': '66.1K Followers',
        'subtitle': 'pallabi 479907   Instagram',
        'avatar': null,
        'verified': false,
        'live': false,
      },
      {
        'name': 'Siya❤️145',
        'followers': '4.2K Followers',
        'subtitle': 'Mumbai',
        'avatar': null,
        'verified': false,
        'live': false,
      },
      {
        'name': 'pratima kundu',
        'followers': '67.6K Followers',
        'subtitle': '😌😊 এলো সবাই একটু ফুল করি ...',
        'avatar': null,
        'verified': true,
        'live': false,
      },
    ];
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
          'Search',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF23272F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search "Name"',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder:
                  (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[800],
                            backgroundImage:
                                user['avatar'] as ImageProvider<Object>?,
                            child:
                                user['avatar'] == null
                                    ? Text(
                                      (user['name'] as String)[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    )
                                    : null,
                          ),
                          if (user['live'] == true)
                            Positioned(
                              bottom: -2,
                              left: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                if (user['verified'] == true)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              user['followers'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (user['subtitle'] != null &&
                                (user['subtitle'] as String).isNotEmpty)
                              Text(
                                user['subtitle'] as String,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 0,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '+ Follow',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
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
