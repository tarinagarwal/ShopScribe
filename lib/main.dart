import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

// State management with Riverpod
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) => NotificationsNotifier());
final shoppingListsProvider = StateNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>((ref) => ShoppingListsNotifier());

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', state == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('themeMode');
    if (themeMode != null) {
      state = themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
  }
}

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true);

  void toggleNotifications() {
    state = !state;
    _savePreferences();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', state);
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notificationsEnabled') ?? true;
  }
}

class ShoppingList {
  final String id;
  final String title;
  final List<ShoppingItem> items;
  final String timestamp;

  ShoppingList({required this.id, required this.title, required this.items, required this.timestamp});

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      title: json['title'],
      items: (json['items'] as List).map((item) => ShoppingItem.fromJson(item)).toList(),
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'timestamp': timestamp,
    };
  }
}

class ShoppingItem {
  final String id;
  final String title;
  final String category;
  final String details;
  final String notes;
  bool done;
  final String timestamp;

  ShoppingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.details,
    required this.notes,
    required this.done,
    required this.timestamp,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      details: json['details'],
      notes: json['notes'],
      done: json['done'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'details': details,
      'notes': notes,
      'done': done,
      'timestamp': timestamp,
    };
  }
}

class ShoppingListsNotifier extends StateNotifier<List<ShoppingList>> {
  ShoppingListsNotifier() : super([]);

  void addList(String title) {
    final newList = ShoppingList(
      id: Uuid().v4(),
      title: title,
      items: [],
      timestamp: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    state = [...state, newList];
    _saveShoppingLists();
  }

  void deleteList(String id) {
    state = state.where((list) => list.id != id).toList();
    _saveShoppingLists();
  }

  void addItem(String listId, String title, String category, String details, String notes) {
    state = state.map((list) {
      if (list.id == listId) {
        final newItem = ShoppingItem(
          id: Uuid().v4(),
          title: title,
          category: category,
          details: details,
          notes: notes,
          done: false,
          timestamp: DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
        );
        return ShoppingList(
          id: list.id,
          title: list.title,
          items: [...list.items, newItem],
          timestamp: list.timestamp,
        );
      }
      return list;
    }).toList();
    _saveShoppingLists();
  }

  void toggleItemDone(String listId, String itemId) {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = list.items.map((item) {
          if (item.id == itemId) {
            return ShoppingItem(
              id: item.id,
              title: item.title,
              category: item.category,
              details: item.details,
              notes: item.notes,
              done: !item.done,
              timestamp: item.timestamp,
            );
          }
          return item;
        }).toList();
        return ShoppingList(
          id: list.id,
          title: list.title,
          items: updatedItems,
          timestamp: list.timestamp,
        );
      }
      return list;
    }).toList();
    _saveShoppingLists();
  }

  void deleteItem(String listId, String itemId) {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = list.items.where((item) => item.id != itemId).toList();
        return ShoppingList(
          id: list.id,
          title: list.title,
          items: updatedItems,
          timestamp: list.timestamp,
        );
      }
      return list;
    }).toList();
    _saveShoppingLists();
  }

  Future<void> _saveShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(state.map((list) => list.toJson()).toList());
    await prefs.setString('shoppingLists', jsonString);
  }

  Future<void> loadShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('shoppingLists');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      state = jsonList.map((item) => ShoppingList.fromJson(item)).toList();
    }
  }
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Shopping List',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[400]),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> with TickerProviderStateMixin {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  DateTime? _selectedDate;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadData();
  }

  Future<void> _loadData() async {
    await ref.read(themeProvider.notifier).loadPreferences();
    await ref.read(notificationsProvider.notifier).loadPreferences();
    await ref.read(shoppingListsProvider.notifier).loadShoppingLists();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(int id, String title, String body) async {
    if (ref.read(notificationsProvider)) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(id, title, body, platformChannelSpecifics);
    }
  }

  void _shareList(ShoppingList list) {
    final StringBuffer shareContent = StringBuffer();
    shareContent.writeln('Shopping List: ${list.title}');
    shareContent.writeln('Date: ${list.timestamp}');
    
    final doneItems = list.items.where((item) => item.done).map((item) => item.title).toList();
    final notDoneItems = list.items.where((item) => !item.done).map((item) => item.title).toList();

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

  void _confirmDeleteList(String listId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this list?'),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(shoppingListsProvider.notifier).deleteList(listId);
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

  void _showShoppingListDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            list.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: list.items.length,
              itemBuilder: (context, index) {
                final item = list.items[index];
                return Dismissible(
                  key: Key(item.id),
                  onDismissed: (direction) {
                    ref.read(shoppingListsProvider.notifier).deleteItem(list.id, item.id);
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
                  child: Card(
                    child: ExpansionTile(
                      leading: Icon(_getCategoryIcon(item.category)),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          decoration: item.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(item.category),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Details: ${item.details}'),
                              Text('Notes: ${item.notes}'),
                              Text('Added: ${item.timestamp}'),
                            ],
                          ),
                        ),
                      ],
                      trailing: Checkbox(
                        value: item.done,
                        onChanged: (bool? value) {
                          ref.read(shoppingListsProvider.notifier).toggleItemDone(list.id, item.id);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Add Item'),
              onPressed: () async {
                final newItem = await _showAddItemDialog();
                if (newItem != null) {
                  ref.read(shoppingListsProvider.notifier).addItem(
                    list.id,
                    newItem['title']!,
                    newItem['category']!,
                    newItem['details']!,
                    newItem['notes']!,
                  );
                  Navigator.of(context).pop();
                  _showShoppingListDialog(list);
                }
              },
            ),
            TextButton(
              child: Text('Share'),
              onPressed: () {
                _shareList(list);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'drinks':
        return Icons.local_drink;
      case 'household':
        return Icons.home;
      case 'personal care':
        return Icons.face;
      default:
        return Icons.shopping_basket;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final filteredLists = _selectedDate == null
        ? shoppingLists
        : shoppingLists.where((list) {
            final listDate = DateTime.parse(list.timestamp);
            return listDate.year == _selectedDate?.year &&
                listDate.month == _selectedDate?.month &&
                listDate.day == _selectedDate?.day;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.purple],
            ),
          ),
        ),
        title: Text(
          'Shopping Lists',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(ref.watch(themeProvider) == ThemeMode.dark ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: Icon(ref.watch(notificationsProvider) ? Icons.notifications : Icons.notifications_off),
            onPressed: () => ref.read(notificationsProvider.notifier).toggleNotifications(),
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
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildShoppingListView(filteredLists),
          _buildSettingsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildShoppingListView(List<ShoppingList> lists) {
    return lists.isEmpty
        ? Center(
            child: Text(
              "You don't have any shopping list yet, create one by clicking + icon below",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          )
        : ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return AnimatedBuilder(
                animation: AnimationController(
                  duration: Duration(milliseconds: 300),
                  vsync: this,
                ),
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: AnimationController(
                        duration: Duration(milliseconds: 300),
                        vsync: this,
                      )..forward(),
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  );
                },
                child: Dismissible(
                  key: Key(list.id),
                  onDismissed: (direction) {
                    ref.read(shoppingListsProvider.notifier).deleteList(list.id);
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
                  child: Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(list.title[0].toUpperCase()),
                      ),
                      title: Text(
                        list.title,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        list.timestamp,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _confirmDeleteList(list.id);
                        },
                      ),
                      onTap: () {
                        _showShoppingListDialog(list);
                      },
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSettingsView() {
    return ListView(
      children: [
        ListTile(
          title: Text('Dark Mode'),
          trailing: Switch(
            value: ref.watch(themeProvider) == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ),
        ListTile(
          title: Text('Notifications'),
          trailing: Switch(
            value: ref.watch(notificationsProvider),
            onChanged: (value) {
              ref.read(notificationsProvider.notifier).toggleNotifications();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      backgroundColor: Colors.blue,
      visible: true,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
          onTap: () async {
            final title = await _showAddListDialog();
            if (title != null) {
              ref.read(shoppingListsProvider.notifier).addList(title);
            }
          },
          label: 'Add List',
          labelStyle: TextStyle(fontWeight: FontWeight.w500),
          labelBackgroundColor: Colors.blue,
        ),
        SpeedDialChild(
          child: Icon(Icons.search),
          backgroundColor: Colors.blue,
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(
                shoppingLists: ref.read(shoppingListsProvider),
                onListTap: _showShoppingListDialog,
              ),
            );
          },
          label: 'Search',
          labelStyle: TextStyle(fontWeight: FontWeight.w500),
          labelBackgroundColor: Colors.blue,
        ),
      ],
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
}

class CustomSearchDelegate extends SearchDelegate {
  final List<ShoppingList> shoppingLists;
  final Function(ShoppingList) onListTap;

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
        .where((list) => list.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = shoppingLists
        .where((list) => list.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _buildSearchResults(suggestions);
  }

  Widget _buildSearchResults(List<ShoppingList> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final list = results[index];
        return ListTile(
          title: Text(list.title),
          subtitle: Text('${list.items.length} items'),
          onTap: () {
            onListTap(list);
            close(context, null);
          },
        );
      },
    );
  }
}