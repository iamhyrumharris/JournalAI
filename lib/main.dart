import 'package:flutter/material.dart';
import 'screens/journal_entry_screen.dart';
import 'package:journal_ai/widgets/image_calendar.dart';
import '../utils/database_helper.dart';
import 'dart:convert';

void main() {
  runApp(const JournalifeApp());
}

class JournalifeApp extends StatelessWidget {
  const JournalifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journalife',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        hintColor: Colors.amberAccent,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18.0),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ImageCalendar(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journalife'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final dbEntries = await DatabaseHelper.instance.getEntries();
    setState(() {
      entries = dbEntries.map((entry) => {
        'id': entry['id'],
        'title': entry['title'],
        'body': entry['body'],
        'date': entry['date'],
      }).toList();
    });
  }

  Future<void> _navigateAndAddEntry(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(selectedDate: DateTime.now()),
      ),
    );

    if (result != null) {
      _loadEntries(); // Refresh entries from database
    }
  }

  Future<void> _navigateAndEditEntry(BuildContext context, Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(
          selectedDate: DateTime.parse(entry['date']),
        ),
      ),
    );

    if (result == true) {
      _loadEntries(); // Refresh entries after edit
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _navigateAndAddEntry(context),
          child: const Text('Add Entry'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(entry['title'] ?? 'No Title'),
                  subtitle: Text('${entry['body']}\n${entry['date']}'),
                  onTap: () => _navigateAndEditEntry(context, entry), // Make the card clickable
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
