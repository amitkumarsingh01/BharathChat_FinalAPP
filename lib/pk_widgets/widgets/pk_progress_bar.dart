// import 'package:flutter/material.dart';
// import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
// import 'dart:async';

// class PKProgressBar extends StatefulWidget {
//   final String? leftHostId;
//   final String? rightHostId;
//   final String? leftHostName;
//   final String? rightHostName;
//   final int leftDiamonds;
//   final int rightDiamonds;
//   final int totalDiamonds;

//   const PKProgressBar({
//     Key? key,
//     this.leftHostId,
//     this.rightHostId,
//     this.leftHostName,
//     this.rightHostName,
//     required this.leftDiamonds,
//     required this.rightDiamonds,
//     required this.totalDiamonds,
//   }) : super(key: key);

//   @override
//   State<PKProgressBar> createState() => _PKProgressBarState();
// }

// class _PKProgressBarState extends State<PKProgressBar>
//     with TickerProviderStateMixin {
//   late AnimationController _progressController;
//   late Animation<double> _leftProgressAnimation;
//   late Animation<double> _rightProgressAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _progressController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     );

//     _leftProgressAnimation = Tween<double>(
//       begin: 0.0,
//       end:
//           widget.totalDiamonds > 0
//               ? widget.leftDiamonds / widget.totalDiamonds
//               : 0.0,
//     ).animate(
//       CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
//     );

//     _rightProgressAnimation = Tween<double>(
//       begin: 0.0,
//       end:
//           widget.totalDiamonds > 0
//               ? widget.rightDiamonds / widget.totalDiamonds
//               : 0.0,
//     ).animate(
//       CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
//     );

//     _progressController.forward();

//     // Start continuous animation for the center diamond
//     _startContinuousAnimation();
//   }

//   void _startContinuousAnimation() {
//     _progressController.repeat(reverse: true);
//   }

//   @override
//   void didUpdateWidget(PKProgressBar oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (oldWidget.leftDiamonds != widget.leftDiamonds ||
//         oldWidget.rightDiamonds != widget.rightDiamonds ||
//         oldWidget.totalDiamonds != widget.totalDiamonds) {
//       _updateProgressAnimations();
//     }
//   }

//   void _updateProgressAnimations() {
//     _leftProgressAnimation = Tween<double>(
//       begin: _leftProgressAnimation.value,
//       end:
//           widget.totalDiamonds > 0
//               ? widget.leftDiamonds / widget.totalDiamonds
//               : 0.0,
//     ).animate(
//       CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
//     );

//     _rightProgressAnimation = Tween<double>(
//       begin: _rightProgressAnimation.value,
//       end:
//           widget.totalDiamonds > 0
//               ? widget.rightDiamonds / widget.totalDiamonds
//               : 0.0,
//     ).animate(
//       CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
//     );

//     _progressController.reset();
//     _progressController.forward();
//   }

//   @override
//   void dispose() {
//     _progressController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         children: [
//           // Progress Bar
//           Container(
//             height: 40,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               color: Colors.black.withOpacity(0.6),
//               border: Border.all(
//                 color: Colors.purple.withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: Stack(
//               children: [
//                 // Background
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     color: Colors.transparent,
//                   ),
//                 ),
//                 // Left Progress (Blue) - Slides towards center based on dominance
//                 AnimatedBuilder(
//                   animation: _leftProgressAnimation,
//                   builder: (context, child) {
//                     final leftPercentage =
//                         widget.totalDiamonds > 0
//                             ? widget.leftDiamonds / widget.totalDiamonds
//                             : 0.0;
//                     final rightPercentage =
//                         widget.totalDiamonds > 0
//                             ? widget.rightDiamonds / widget.totalDiamonds
//                             : 0.0;

//                     // Calculate how much the left bar should extend towards center
//                     final leftBarWidth =
//                         MediaQuery.of(context).size.width *
//                         0.4 *
//                         leftPercentage;
//                     final maxLeftWidth =
//                         MediaQuery.of(context).size.width *
//                         0.45; // Can extend slightly past center

//                     return Positioned(
//                       left: 0,
//                       top: 0,
//                       bottom: 0,
//                       child: Container(
//                         width: leftBarWidth.clamp(0.0, maxLeftWidth),
//                         decoration: BoxDecoration(
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(20),
//                             bottomLeft: Radius.circular(20),
//                           ),
//                           gradient: LinearGradient(
//                             colors: [
//                               Colors.blue.withOpacity(0.8),
//                               Colors.lightBlue.withOpacity(0.9),
//                             ],
//                             begin: Alignment.centerLeft,
//                             end: Alignment.centerRight,
//                           ),
//                         ),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: const BorderRadius.only(
//                               topLeft: Radius.circular(20),
//                               bottomLeft: Radius.circular(20),
//                             ),
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.blue.withOpacity(0.3),
//                                 Colors.lightBlue.withOpacity(0.2),
//                               ],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 // Center Diamond with winning indicator
//                 Positioned(
//                   left: MediaQuery.of(context).size.width * 0.5 - 20,
//                   top: 2,
//                   child: AnimatedBuilder(
//                     animation: _progressController,
//                     builder: (context, child) {
//                       // Determine which host is winning
//                       Color diamondColor = Colors.purple;
//                       Color shadowColor = Colors.purple;
//                       double pulseIntensity = 1.0;

//                       if (widget.leftDiamonds > widget.rightDiamonds) {
//                         diamondColor = Colors.blue;
//                         shadowColor = Colors.blue;
//                         pulseIntensity = 1.5; // More intense for winning host
//                       } else if (widget.rightDiamonds > widget.leftDiamonds) {
//                         diamondColor = Colors.pink;
//                         shadowColor = Colors.pink;
//                         pulseIntensity = 1.5; // More intense for winning host
//                       }

//                       return Container(
//                         width: 40,
//                         height: 36,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8),
//                           gradient: LinearGradient(
//                             colors: [
//                               diamondColor.withOpacity(0.9),
//                               diamondColor.withOpacity(0.8),
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: shadowColor.withOpacity(0.6),
//                               blurRadius:
//                                   (8 + (_progressController.value * 4)) *
//                                   pulseIntensity,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Image.asset(
//                           'assets/diamond.png',
//                           width: 24,
//                           height: 24,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 // Right Progress (Pink) - Slides towards center based on dominance
//                 AnimatedBuilder(
//                   animation: _rightProgressAnimation,
//                   builder: (context, child) {
//                     final leftPercentage =
//                         widget.totalDiamonds > 0
//                             ? widget.leftDiamonds / widget.totalDiamonds
//                             : 0.0;
//                     final rightPercentage =
//                         widget.totalDiamonds > 0
//                             ? widget.rightDiamonds / widget.totalDiamonds
//                             : 0.0;

//                     // Calculate how much the right bar should extend towards center
//                     final rightBarWidth =
//                         MediaQuery.of(context).size.width *
//                         0.4 *
//                         rightPercentage;
//                     final maxRightWidth =
//                         MediaQuery.of(context).size.width *
//                         0.45; // Can extend slightly past center

//                     return Positioned(
//                       right: 0,
//                       top: 0,
//                       bottom: 0,
//                       child: Container(
//                         width: rightBarWidth.clamp(0.0, maxRightWidth),
//                         decoration: BoxDecoration(
//                           borderRadius: const BorderRadius.only(
//                             topRight: Radius.circular(20),
//                             bottomRight: Radius.circular(20),
//                           ),
//                           gradient: LinearGradient(
//                             colors: [
//                               Colors.pink.withOpacity(0.8),
//                               Colors.purple.withOpacity(0.9),
//                             ],
//                             begin: Alignment.centerRight,
//                             end: Alignment.centerLeft,
//                           ),
//                         ),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: const BorderRadius.only(
//                               topRight: Radius.circular(20),
//                               bottomRight: Radius.circular(20),
//                             ),
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.pink.withOpacity(0.3),
//                                 Colors.purple.withOpacity(0.2),
//                               ],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 // Left Sword Icon
//                 Positioned(
//                   left: 8,
//                   top: 8,
//                   child: Container(
//                     width: 24,
//                     height: 24,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.blue.withOpacity(0.8),
//                       border: Border.all(color: Colors.white, width: 2),
//                     ),
//                     child: const Icon(
//                       Icons.flash_on,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                   ),
//                 ),
//                 // Right Sword Icon
//                 Positioned(
//                   right: 8,
//                   top: 8,
//                   child: Container(
//                     width: 24,
//                     height: 24,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.pink.withOpacity(0.8),
//                       border: Border.all(color: Colors.white, width: 2),
//                     ),
//                     child: const Icon(
//                       Icons.flash_on,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           // VS Badge or Winner Announcement
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               gradient: LinearGradient(
//                 colors:
//                     widget.leftDiamonds > widget.rightDiamonds * 1.5
//                         ? [
//                           Colors.blue.withOpacity(0.8),
//                           Colors.lightBlue.withOpacity(0.9),
//                         ]
//                         : widget.rightDiamonds > widget.leftDiamonds * 1.5
//                         ? [
//                           Colors.pink.withOpacity(0.8),
//                           Colors.purple.withOpacity(0.9),
//                         ]
//                         : [
//                           Colors.orange.withOpacity(0.8),
//                           Colors.deepOrange.withOpacity(0.9),
//                         ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color:
//                       widget.leftDiamonds > widget.rightDiamonds * 1.5
//                           ? Colors.blue.withOpacity(0.3)
//                           : widget.rightDiamonds > widget.leftDiamonds * 1.5
//                           ? Colors.pink.withOpacity(0.3)
//                           : Colors.orange.withOpacity(0.3),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Text(
//               widget.leftDiamonds > widget.rightDiamonds * 1.5
//                   ? 'HOST 1 LEADING!'
//                   : widget.rightDiamonds > widget.leftDiamonds * 1.5
//                   ? 'HOST 2 LEADING!'
//                   : 'VS',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           // Host Scores
//           Row(
//             children: [
//               // Left Host Score
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     color: Colors.blue.withOpacity(0.1),
//                     border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                   ),
//                   child: Column(
//                     children: [
//                       // Rings/Medals
//                       // Row(
//                       //   mainAxisAlignment: MainAxisAlignment.center,
//                       //   children: [
//                       //     _buildMedal(3, Colors.red),
//                       //     const SizedBox(width: 4),
//                       //     _buildMedal(2, Colors.grey),
//                       //     const SizedBox(width: 4),
//                       //     _buildMedal(1, Colors.amber),
//                       //   ],
//                       // ),
//                       // const SizedBox(height: 8),
//                       // Diamond Count
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             'assets/diamond.png',
//                             width: 16,
//                             height: 16,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${widget.leftDiamonds}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (widget.leftHostName != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           widget.leftHostName!,
//                           style: TextStyle(
//                             color: Colors.blue.withOpacity(0.8),
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // Right Host Score
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     color: Colors.pink.withOpacity(0.1),
//                     border: Border.all(color: Colors.pink.withOpacity(0.3)),
//                   ),
//                   child: Column(
//                     children: [
//                       // Rings/Medals (reversed order)
//                       // Row(
//                       //   mainAxisAlignment: MainAxisAlignment.center,
//                       //   children: [
//                       //     _buildMedal(1, Colors.amber),
//                       //     const SizedBox(width: 4),
//                       //     _buildMedal(2, Colors.grey),
//                       //     const SizedBox(width: 4),
//                       //     _buildMedal(3, Colors.red),
//                       //   ],
//                       // ),
//                       // const SizedBox(height: 8),
//                       // Diamond Count
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             'assets/diamond.png',
//                             width: 16,
//                             height: 16,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${widget.rightDiamonds}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (widget.rightHostName != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           widget.rightHostName!,
//                           style: TextStyle(
//                             color: Colors.pink.withOpacity(0.8),
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMedal(int position, Color color) {
//     return Container(
//       width: 20,
//       height: 20,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: color,
//         border: Border.all(color: Colors.white, width: 1),
//       ),
//       child: Center(
//         child: Text(
//           '$position',
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 10,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
