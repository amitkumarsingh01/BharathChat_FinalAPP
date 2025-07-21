import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'terms_conditions_screen.dart';
import '../../services/api_service.dart';

class CreatorInvitationScreen extends StatefulWidget {
  const CreatorInvitationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreatorInvitationScreenState createState() =>
      _CreatorInvitationScreenState();
}

class _CreatorInvitationScreenState extends State<CreatorInvitationScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _gender = 'Male';
  String _selectedDate = 'Date';
  String _selectedMonth = 'Month';
  String _selectedYear = 'Year';

  final List<String> genres = [
    'Art, Craft & DIY',
    'Chit Chat',
    'Fun & Comedy',
    'Beauty & Fashion',
    'Dance Performance',
    'Health and Fitness',
    'Live Music',
    'E-Gaming',
    'Live Cooking',
    'Education',
    'Movies, TV Shows & OTT',
    'Animals & Nature',
    'Travel / Adventure',
    'Automobile & Technology',
    'Motivation & Speech',
    'Astrology',
    'News',
    'Devotion',
    'Sports',
    'Events & Festivals',
  ];

  final Set<String> selectedGenres = {};

  bool acceptTerms = false;
  bool acceptAgreement = false;
  bool _isLoading = false;

  Future<void> _submitInvitation() async {
    if (_nameController.text.isEmpty ||
        _selectedDate == 'Date' ||
        _selectedMonth == 'Month' ||
        _selectedYear == 'Year' ||
        selectedGenres.isEmpty ||
        !acceptTerms ||
        !acceptAgreement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and accept terms.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://server.bharathchat.com/liveapproval');
    final body = {
      "user_id": ApiService.currentUserId,
      "name": _nameController.text,
      "moj_handle": ApiService.currentUserId?.toString() ?? '',
      "gender": _gender,
      "date_of_birth": {
        "day": int.parse(_selectedDate),
        "month": int.parse(_selectedMonth),
        "year": int.parse(_selectedYear),
      },
      "genres": selectedGenres.toList(),
      "accepted_terms_of_use": acceptTerms,
      "accepted_agency_agreement": acceptAgreement,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Received Invitation!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: \n${response.body}')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        title: Text(
          'Bharath Chat for Creators',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              // Name
              TextField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: _inputDecoration('Name'),
              ),
              SizedBox(height: 16),

              // Gender
              Text(
                'Gender',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Row(
                children: [
                  _genderOption('Male'),
                  SizedBox(width: 20),
                  _genderOption('Female'),
                ],
              ),
              SizedBox(height: 16),

              // Date of Birth
              Text(
                'Date of Birth',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Row(
                children: [
                  _dropdown(
                    _selectedDate,
                    ['Date'] + List.generate(31, (i) => '${i + 1}'),
                    (value) {
                      setState(() {
                        _selectedDate = value!;
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  _dropdown(
                    _selectedMonth,
                    ['Month'] + List.generate(12, (i) => '${i + 1}'),
                    (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  _dropdown(
                    _selectedYear,
                    ['Year'] + List.generate(50, (i) => '${1970 + i}'),
                    (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Genre
              Text(
                'Choose Genre',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    genres.map((genre) {
                      final isSelected = selectedGenres.contains(genre);
                      return ChoiceChip(
                        label: Text(genre),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                        selected: isSelected,
                        selectedColor: Colors.orange,
                        backgroundColor: Colors.grey[800],
                        onSelected: (_) {
                          setState(() {
                            if (isSelected) {
                              selectedGenres.remove(genre);
                            } else {
                              selectedGenres.add(genre);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),

              // Checkboxes
              Row(
                children: [
                  Checkbox(
                    value: acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        acceptTerms = value!;
                      });
                    },
                    activeColor: Colors.orange,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'I accept Bharath Chat',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const TermsConditionsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Terms of Use',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: acceptAgreement,
                    onChanged: (value) {
                      setState(() {
                        acceptAgreement = value!;
                      });
                    },
                    activeColor: Colors.orange,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'I accept the agreement to join Bharath Chat',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Text(
              //   'Invitation expires in 6 days',
              //   style: TextStyle(color: Colors.grey),
              // ),
              // SizedBox(height: 16),

              // Accept Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitInvitation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                        : Text('Send Invitation'),
              ),

              SizedBox(height: 12),

              // Cancel
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.orange)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderOption(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _gender,
          activeColor: Colors.orange,
          onChanged: (val) {
            setState(() {
              _gender = val!;
            });
          },
        ),
        Text(value, style: TextStyle(color: Colors.white)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: value,
          iconEnabledColor: Colors.orange,
          dropdownColor: Colors.black,
          style: TextStyle(color: Colors.white),
          isExpanded: true,
          underline: SizedBox(),
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
