import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeNotifications();
  }

  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = true;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    _savePreferences();
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
    _savePreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = (prefs.getString('themeMode') ?? 'light') == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'themeMode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }

  void _initializeNotifications() async {
    if (_notificationsEnabled) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
      home: MyHomePage(
        onToggleTheme: _toggleTheme,
        notificationsEnabled: _notificationsEnabled,
        onToggleNotifications: _toggleNotifications,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.onToggleTheme,
    required this.notificationsEnabled,
    required this.onToggleNotifications,
    required this.currentThemeMode,
  });

  final VoidCallback onToggleTheme;
  final bool notificationsEnabled;
  final VoidCallback onToggleNotifications;
  final ThemeMode currentThemeMode;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Map<String, dynamic>> _shoppingLists = [];
  final TextEditingController _searchController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  DateTime? _selectedDate;
  String _searchQuery = '';
  int? _dialogIndex; // Track which list's dialog is open

  Future<void> _loadShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('shoppingLists');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _shoppingLists.clear();
        _shoppingLists.addAll(
            jsonList.map((item) => Map<String, dynamic>.from(item)).toList());
      });
    }
  }

  Future<void> _saveShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_shoppingLists);
    await prefs.setString('shoppingLists', jsonString);
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadShoppingLists();
  }

  void _initializeNotifications() async {
    if (widget.notificationsEnabled) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    }
  }

  Future<void> _showNotification(int id, String title, String body) async {
    if (widget.notificationsEnabled) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
      );
    }
  }

  void _addShoppingList(String title) {
    if (title.isNotEmpty) {
      setState(() {
        _shoppingLists.add({
          'title': title,
          'items': [],
          'timestamp': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });
      });
      _saveShoppingLists();
      _showNotification(
          _shoppingLists.length, 'New shopping list added', 'List: $title');
    }
  }

  void _addItemToList(int listIndex, String title, String category,
      String details, String notes) {
    if (title.isNotEmpty) {
      setState(() {
        _shoppingLists[listIndex]['items'].add({
          'title': title,
          'category': category,
          'details': details,
          'notes': notes,
          'done': false,
          'timestamp': DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
        });
      });
      _saveShoppingLists();
      _showNotification(_shoppingLists[listIndex]['items'].length,
          'New item added', 'Item: $title');
    }
  }

  void _toggleItemDone(int listIndex, int itemIndex) {
    setState(() {
      _shoppingLists[listIndex]['items'][itemIndex]['done'] =
          !_shoppingLists[listIndex]['items'][itemIndex]['done'];
    });
    _saveShoppingLists();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      _showShoppingListDialog(listIndex);
    });
  }

  void _shareList(int listIndex) {
    final list = _shoppingLists[listIndex];
    final List<String> doneItems = list['items']
        .where((item) => item['done'] == true)
        .map<String>((item) => item['title'] as String)
        .toList();
    final List<String> notDoneItems = list['items']
        .where((item) => item['done'] == false)
        .map<String>((item) => item['title'] as String)
        .toList();

    final StringBuffer shareContent = StringBuffer();
    shareContent.writeln('Shopping List: ${list['title']}');
    shareContent.writeln('Date: ${list['timestamp']}');
    if (doneItems.isNotEmpty) {
      shareContent.writeln('\nDone:');
      for (final item in doneItems) {
        shareContent.writeln('- $item');
      }
    }
    if (notDoneItems.isNotEmpty) {
      shareContent.writeln('\nNot Done:');
      for (final item in notDoneItems) {
        shareContent.writeln('- $item');
      }
    }

    Share.share(shareContent.toString());
  }

  void _deleteShoppingList(int index) {
    setState(() {
      _shoppingLists.removeAt(index);
    });
    _saveShoppingLists();
  }

  void _deleteItemFromList(int listIndex, int itemIndex) {
    setState(() {
      _shoppingLists[listIndex]['items'].removeAt(itemIndex);
    });
    _saveShoppingLists();
  }

  void _reopenListDialog(int listIndex) {
    _dialogIndex = listIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showShoppingListDialog(listIndex);
    });
  }

  void _confirmDeleteList(int listIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this list?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _shoppingLists.removeAt(listIndex);
                });
                _saveShoppingLists();
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteItem(BuildContext context, int listIndex, int itemIndex,
      StateSetter setState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _deleteItemFromList(listIndex, itemIndex);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showShoppingListDialog(int listIndex) {
    _dialogIndex = listIndex;
    final list = _shoppingLists[listIndex];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async {
                _dialogIndex = null;
                return true;
              },
              child: AlertDialog(
                title: Text(
                  list['title'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < list['items'].length; i++)
                        Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) {
                            setState(() {
                              _deleteItemFromList(listIndex, i);
                            });
                          },
                          child: ListTile(
                            title: Text(
                              list['items'][i]['title'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    decoration: list['items'][i]['done']
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Details: ${list['items'][i]['details']}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Notes: ${list['items'][i]['notes']}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  list['items'][i]['timestamp'],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _confirmDeleteItem(
                                        context, listIndex, i, setState);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    list['items'][i]['done']
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: list['items'][i]['done']
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _toggleItemDone(listIndex, i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Add Item'),
                    onPressed: () async {
                      final newItem = await _showAddItemDialog();
                      if (newItem != null) {
                        Navigator.of(context).pop(); // Close the current dialog
                        _addItemToList(
                            listIndex,
                            newItem['title']!,
                            newItem['category']!,
                            newItem['details']!,
                            newItem['notes']!);
                        _showShoppingListDialog(listIndex); // Reopen the dialog
                      }
                    },
                  ),
                  TextButton(
                    child: Text('Share'),
                    onPressed: () {
                      _shareList(listIndex);
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Close'),
                    onPressed: () {
                      _dialogIndex = null;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>?> _showAddItemDialog() async {
    String title = '';
    String category = '';
    String details = '';
    String notes = '';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  labelText: 'Item Name',
                ),
                onChanged: (value) {
                  title = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Category',
                ),
                onChanged: (value) {
                  category = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Details',
                ),
                onChanged: (value) {
                  details = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes',
                ),
                onChanged: (value) {
                  notes = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                Navigator.of(context).pop({
                  'title': title,
                  'category': category,
                  'details': details,
                  'notes': notes,
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLists = _selectedDate == null
        ? _shoppingLists
        : _shoppingLists.where((list) {
            final listDate = DateTime.parse(list['timestamp']);
            return listDate.year == _selectedDate?.year &&
                listDate.month == _selectedDate?.month &&
                listDate.day == _selectedDate?.day;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Lists',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(widget.currentThemeMode == ThemeMode.dark
                ? Icons.wb_sunny
                : Icons.nights_stay),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: Icon(widget.notificationsEnabled
                ? Icons.notifications
                : Icons.notifications_off),
            onPressed: widget.onToggleNotifications,
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(
                  shoppingLists: _shoppingLists,
                  onListTap: _showShoppingListDialog,
                ),
              );
            },
          ),
        ],
      ),
      body: filteredLists.isEmpty
          ? Center(
              child: Text(
                "You don't have any shopping list yet, create one by clicking + icon below",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: filteredLists.length,
              itemBuilder: (context, index) {
                final list = filteredLists[index];
                return Dismissible(
                  key: UniqueKey(),
                  onDismissed: (direction) {
                    _deleteShoppingList(index);
                  },
                  background: Container(
                    color: Colors.red,
                    child: Center(
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      list['title'],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      list['timestamp'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _confirmDeleteList(
                            index); // Implement this method to show a confirmation dialog and delete the list
                      },
                    ),
                    onTap: () {
                      _showShoppingListDialog(index);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = await _showAddListDialog();
          if (title != null) {
            _addShoppingList(title);
          }
        },
        tooltip: 'Add Shopping List',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<String?> _showAddListDialog() async {
    String title = '';

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Shopping List'),
          content: TextField(
            decoration: InputDecoration(
              labelText: 'Title',
            ),
            onChanged: (value) {
              title = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                Navigator.of(context).pop(title);
              },
            ),
          ],
        );
      },
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> shoppingLists;
  final Function(int) onListTap;

  CustomSearchDelegate({required this.shoppingLists, required this.onListTap});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = shoppingLists
        .where(
            (list) => list['title'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No matching shopping lists found.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final list = results[index];
        return ListTile(
          title: Text(list['title']),
          onTap: () {
            onListTap(index);
            close(context, null);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = shoppingLists
        .where(
            (list) => list['title'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (suggestions.isEmpty) {
      return Center(
        child: Text(
          'No matching shopping lists found.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final list = suggestions[index];
        return ListTile(
          title: Text(list['title']),
          onTap: () {
            query = list['title'];
            showResults(context);
          },
        );
      },
    );
  }
}
