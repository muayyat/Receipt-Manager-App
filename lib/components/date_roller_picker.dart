import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/rounded_button.dart';

class CalendarFilterWidget extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime, DateTime) onApply;

  const CalendarFilterWidget({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
  });

  @override
  CalendarFilterWidgetState createState() => CalendarFilterWidgetState();
}

class CalendarFilterWidgetState extends State<CalendarFilterWidget> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  void _updateRange(int days) {
    setState(() {
      if (_endDate != null) {
        _startDate = _endDate!.subtract(Duration(days: days));
      } else if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: days));
      }
    });
  }

  Future<void> _showRollingDatePicker(
      BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    DateTime maximumDate = DateTime.now();

    // Ensure initialDate does not exceed maximumDate
    if (initialDate.isAfter(maximumDate)) {
      initialDate = maximumDate;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: isStartDate
                      ? DateTime(2000)
                      : (_startDate ?? DateTime(2000)),
                  maximumDate:
                      isStartDate ? _endDate ?? maximumDate : maximumDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      if (isStartDate) {
                        _startDate = newDate;
                      } else {
                        _endDate = newDate;
                      }
                    });
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Select Date Range',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('Wk'),
                selected: false,
                onSelected: (_) => _updateRange(7),
              ),
              ChoiceChip(
                label: Text('30D'),
                selected: false,
                onSelected: (_) => _updateRange(30),
              ),
              ChoiceChip(
                label: Text('90D'),
                selected: false,
                onSelected: (_) => _updateRange(90),
              ),
              ChoiceChip(
                label: Text('Year'),
                selected: false,
                onSelected: (_) => _updateRange(365),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Date'),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showRollingDatePicker(context, true),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _startDate != null
                            ? DateFormat.yMMMd().format(_startDate!)
                            : 'Select',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End Date'),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showRollingDatePicker(context, false),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat.yMMMd().format(_endDate!)
                            : 'Select',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: RoundedButton(
                  color: Colors.lightBlueAccent,
                  title: 'Filter',
                  onPressed: () {
                    if (_startDate != null && _endDate != null) {
                      widget.onApply(_startDate!, _endDate!);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RoundedButton(
                  color: Colors.grey,
                  title: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
