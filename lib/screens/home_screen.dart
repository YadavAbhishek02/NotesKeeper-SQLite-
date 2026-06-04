import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> filteredNotes = [];
  bool isSearching = false;
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await DatabaseHelper.instance.getNotes();
      setState(() {
        notes = data;
        filteredNotes = notes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load notes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void filterNotes(String query) {
    setState(() {
      filteredNotes = notes.where((note) {
        return note['title']
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                onChanged: filterNotes,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: false,
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                autofocus: true,
              )
            : const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredNotes = notes;
                }
              });
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : filteredNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No notes found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          note['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            note['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteNote(note['id']);
                            fetchNotes();
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditNoteScreen(
                                note: note,
                              ),
                            ),
                          ).then((_) {
                            fetchNotes();
                          });
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditNoteScreen(),
            ),
          ).then((_) {
            fetchNotes();
          });
        },
        icon: Icon(Icons.add),
        label: Text('New Note'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
