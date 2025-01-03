import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../utils/database_helper.dart';

class JournalEntryScreen extends StatefulWidget {
  final DateTime selectedDate;

  const JournalEntryScreen({super.key, required this.selectedDate});

  @override
  _JournalEntryScreenState createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  int? _entryId;
  List<String> _photoPaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _loadEntry();
  }

  void _loadEntry() async {
    final entries = await DatabaseHelper.instance.getEntries();
    final existingEntry = entries.firstWhere(
      (entry) => entry['date'] == widget.selectedDate.toIso8601String().split('T')[0],
      orElse: () => {},
    );

    if (existingEntry.isNotEmpty) {
      setState(() {
        _entryId = existingEntry['id'] as int;
        _titleController.text = existingEntry['title'] as String;
        _bodyController.text = existingEntry['body'] as String;
        _photoPaths = List<String>.from(json.decode(existingEntry['photo_paths'] ?? '[]'));
      });
    }
  }

  Future<void> _saveEntry() async {
    final entry = {
      'title': _titleController.text,
      'body': _bodyController.text,
      'date': widget.selectedDate.toIso8601String().split('T')[0],
      'photo_paths': json.encode(_photoPaths),
    };

    if (_entryId != null) {
      await DatabaseHelper.instance.updateEntry(_entryId!, entry);
    } else {
      await DatabaseHelper.instance.createEntry(entry);
    }

    Navigator.pop(context, true);
  }

  Future<void> _deleteEntry() async {
    if (_entryId != null) {
      await DatabaseHelper.instance.deleteEntry(_entryId!);
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickImage() async {
    try {
      print("Attempting to pick image...");
      
      // Check and request permissions
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Permission to access photos was denied')),
            );
            return;
          }
        }
      }

      String? imagePath;
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        print("Using image_picker for mobile or web");
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        imagePath = image?.path;
      } else {
        print("Using file_picker for desktop");
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        imagePath = result?.files.single.path;
      }

      if (imagePath != null) {
        print("Image picked: $imagePath");
        final tempDir = Directory.systemTemp;
        final fileName = path.basename(imagePath);
        final savedImage = await File(imagePath).copy('${tempDir.path}/$fileName');
        
        setState(() {
          _photoPaths.add(savedImage.path);
        });
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Widget _buildImageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photos:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _photoPaths.length + 1,
            itemBuilder: (context, index) {
              if (index == _photoPaths.length) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
                  ),
                );
              }
              return GestureDetector(
                onTap: () {
                  // TODO: Implement full-screen image view
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_photoPaths[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entry - ${widget.selectedDate.toString().split(' ')[0]}'),
        actions: [
          if (_entryId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEntry,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Body',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildImageList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveEntry,
        child: const Icon(Icons.save),
      ),
    );
  }
}