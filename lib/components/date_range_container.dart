import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeContainer extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onCalendarPressed;

  const DateRangeContainer({
    required this.startDate,
    required this.endDate,
    required this.onCalendarPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.lightBlue), // Add border color
        borderRadius: BorderRadius.circular(8), // Rounded borders
      ),
      padding: EdgeInsets.symmetric(horizontal: 8), // Add padding
      child: Row(
        mainAxisSize: MainAxisSize.min, // Minimize the size of the Row
        children: [
          Text(
            '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
            style: TextStyle(color: Colors.lightBlue),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: Colors.lightBlue),
            onPressed: onCalendarPressed, // Calendar button callback
          ),
        ],
      ),
    );
  }
}
