# Journal AI

Journal AI is a Flutter-based mobile application that allows users to create and manage daily journal entries with text and photos.

## Features

1. **Home Screen**: Displays a list of recent journal entries with titles, dates, and photo thumbnails.
2. **Calendar View**: Allows users to select specific dates to view or create entries.
3. **Journal Entry Screen**: Enables users to create, view, edit, and delete journal entries.
4. **Photo Integration**: Users can add one photo per journal entry.
5. **Offline Storage**: All data is stored locally on the device using SQLite.

## How to Use

1. **Creating a New Entry**:
   - Tap the '+' floating action button on the Home Screen.
   - Or select a date from the Calendar Screen.

2. **Viewing/Editing an Existing Entry**:
   - Tap on an entry from the Home Screen list.
   - Or select the date of an existing entry from the Calendar Screen.

3. **Adding a Photo to an Entry**:
   - While creating or editing an entry, tap the 'Add Photo' button.
   - Select a photo from your device's gallery.

4. **Deleting an Entry**:
   - Open an existing entry and tap the delete icon in the app bar.

5. **Navigating the App**:
   - Use the bottom navigation bar to switch between the Home Screen and Calendar View.

## Development

This app is built using Flutter and uses the following packages:
- sqflite: For local database storage
- table_calendar: For the calendar view
- image_picker: For selecting photos from the device's gallery

To run the app in development mode:

1. Ensure you have Flutter installed on your machine.
2. Clone this repository.
3. Run `flutter pub get` to install dependencies.
4. Connect a device or start an emulator.
5. Run `flutter run` to start the app.

## Future Improvements

- Implement data backup and sync functionality.
- Add support for multiple photos per entry.
- Implement search functionality for finding specific entries.
- Add tags or categories for better organization of entries.
- Implement a dark mode theme option.
