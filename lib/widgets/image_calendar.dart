import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/database_helper.dart';
import '../screens/journal_entry_screen.dart';

class ImageCalendar extends StatefulWidget {
  const ImageCalendar({Key? key}) : super(key: key);

  @override
  _ImageCalendarState createState() => _ImageCalendarState();
}

class _ImageCalendarState extends State<ImageCalendar> {
  late DateTime _focusedDay;
  late Map<DateTime, String> _events;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _events = {};
    _loadEvents();
  }

  void _loadEvents() async {
    final entries = await DatabaseHelper.instance.getEntriesWithImagesForMonth(
      _focusedDay.year,
      _focusedDay.month,
    );

    setState(() {
      _events = {
        for (var entry in entries)
          DateTime.parse(entry['date'] as String): _getFirstImagePath(entry['photo_paths'] as String)
      };
    });
  }

  String _getFirstImagePath(String photoPaths) {
    final List<dynamic> paths = json.decode(photoPaths);
    return paths.isNotEmpty ? paths.first as String : '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildCalendarGrid()),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
              _loadEvents();
            });
          },
        ),
        Text(
          DateFormat.yMMMM().format(_focusedDay),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              _loadEvents();
            });
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final dayOffset = firstDayOfMonth.weekday - 1;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final int day = index - dayOffset + 1;
        if (day < 1 || day > daysInMonth) {
          return Container();
        }

        final date = DateTime(_focusedDay.year, _focusedDay.month, day);
        final hasImage = _events.containsKey(date) && _events[date]!.isNotEmpty;

        return GestureDetector(
          onTap: () => _onDayTapped(date),
          child: Container(
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_events[date]!),
                      fit: BoxFit.cover,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.black.withOpacity(0.3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: hasImage ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDayTapped(DateTime selectedDate) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(selectedDate: selectedDate),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }
}
