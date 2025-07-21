import 'package:flutter/material.dart';
import 'dart:ui';

class PKRequestingID extends StatefulWidget {
  final ValueNotifier<String> requestIDNotifier;

  const PKRequestingID({Key? key, required this.requestIDNotifier})
    : super(key: key);

  @override
  State<PKRequestingID> createState() => _PKRequestingIDState();
}

class _PKRequestingIDState extends State<PKRequestingID> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.requestIDNotifier,
      builder: (context, requestID, _) {
        if (requestID.isEmpty) {
          return Container();
        }
        return Container(
          margin: EdgeInsets.symmetric(vertical: 22),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            border: Border.all(color: Color(0xFFffa030), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFffa030).withOpacity(0.10),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Color(0xFFffa030),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Request ID: $requestID',
                  style: const TextStyle(
                    color: Color(0xFFffa030),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
