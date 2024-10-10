import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final Color color;
  final String title;
  final Function onPressed;
  final double width; // Add a width parameter

  RoundedButton({
    required this.color,
    required this.title,
    required this.onPressed,
    this.width = 200.0, // Default width is 200.0
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: color,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: () => onPressed(),
          minWidth: width, // Apply the custom width
          height: 42.0,
          child: Text(
            title,
            style: TextStyle(color: Colors.white), // Ensure text is visible
          ),
        ),
      ),
    );
  }
}
