import 'package:flutter/material.dart';
import 'package:study_flow/models/habit.dart';
import 'package:study_flow/services/database_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> habits = [];
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _habitDescriptionController = TextEditingController();
  TimeOfDay? _selectedTime;
  Set<int> _selectedDays = {};
  bool _isLoading = true;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final fetchedHabits = await _databaseService.fetchHabits();
    if (!mounted) return;

    setState(() {
      habits = fetchedHabits;
      _isLoading = false;
    });
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _resetForm() {
    _habitNameController.clear();
    _habitDescriptionController.clear();
    _selectedTime = null;
    _selectedDays.clear();
  }

  Future<void> _saveHabit() async {
    if (_habitNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final newHabit = Habit(
      name: _habitNameController.text,
      time: _selectedTime,
      repeatType: 'specific_days',
      selectedDays: _selectedDays.toList(),
      description: _habitDescriptionController.text,
    );

    try {
      newHabit.id = await _databaseService.saveHabit(newHabit);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save habit: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      habits.add(newHabit);
    });

    _resetForm();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Habit "${newHabit.name}" added successfully!')),
    );
  }

  void _showAddHabitDialog() {
    _resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Habit',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: _habitNameController,
                        decoration: const InputDecoration(
                          labelText: 'Habit Name',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Morning Exercise',
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: _habitDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Time',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8.0),
                      ListTile(
                        title: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : 'Time: ${_selectedTime!.format(context)}',
                        ),
                        trailing: const Icon(Icons.access_time),
                        tileColor: const Color.fromARGB(255, 53, 51, 51),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: _pickTime,
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Repeat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        children: List.generate(7, (index) {
                          return FilterChip(
                            label: Text(_dayNames[index]),
                            selected: _selectedDays.contains(index),
                            onSelected: (selected) {
                              setModalState(() {
                                _toggleDay(index);
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _saveHabit,
                            child: const Text('Save Habit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editHabit(int index) {
    final habit = habits[index];
    _habitNameController.text = habit.name;
    _habitDescriptionController.text = habit.description ?? '';
    _selectedTime = habit.time;
    _selectedDays = habit.selectedDays.isNotEmpty ? habit.selectedDays.toSet() : {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Habit',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: _habitNameController,
                        decoration: const InputDecoration(
                          labelText: 'Habit Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: _habitDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Time',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8.0),
                      ListTile(
                        title: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : 'Time: ${_selectedTime!.format(context)}',
                        ),
                        trailing: const Icon(Icons.access_time),
                        tileColor: const Color.fromARGB(255, 53, 51, 51),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: _pickTime,
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Repeat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        children: List.generate(7, (dayIndex) {
                          return FilterChip(
                            label: Text(_dayNames[dayIndex]),
                            selected: _selectedDays.contains(dayIndex),
                            onSelected: (selected) {
                              setModalState(() {
                                _toggleDay(dayIndex);
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              habit.name = _habitNameController.text;
                              habit.description = _habitDescriptionController.text;
                              habit.time = _selectedTime;
                              habit.repeatType = 'specific_days';
                              habit.selectedDays = _selectedDays.toList();

                              try {
                                await _databaseService.updateHabit(habit);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update habit: $e')),
                                );
                                return;
                              }

                              if (!context.mounted) return;
                              setState(() {});
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Habit "${habit.name}" updated!')),
                              );
                            },
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteHabit(int index) async {
    final habit = habits[index];
    final habitName = habit.name;

    try {
      await _databaseService.deleteHabit(habit);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete habit: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      habits.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Habit "$habitName" deleted')),
    );
  }

  String _getRepeatText(Habit habit) {
    if (habit.selectedDays.length == 7) {
      return 'Every day';
    } else {
      final days = habit.selectedDays
          .map((day) => _dayNames[day])
          .join(', ');
      return days.isEmpty ? 'No days selected' : days;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No habits yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddHabitDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Habit'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(habit.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Time: ${habit.time?.format(context) ?? 'Not set'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Repeat: ${_getRepeatText(habit)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (habit.description != null && habit.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              habit.description!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () => _editHabit(index),
                        ),
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () => _deleteHabit(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        tooltip: 'Add Habit',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _habitNameController.dispose();
    _habitDescriptionController.dispose();
    super.dispose();
  }
}
