import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/auth_controller.dart';
import '../Controller/schedule_controller.dart';
import '../model/schedule_model.dart';
import '../screens/schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final email = context.read<AuthController>().currentUser?.email;
      if (email != null) {
        context.read<ScheduleController>().loadEntries(email);
      }
    });
  }

  void _onDayTapped(DateTime day) {
    setState(() => _selectedDay = day);
    _showAddScheduleSheet(day);
  }

  void _showAddScheduleSheet(DateTime day) {
    final titleController = TextEditingController();
    String? startTime; // ✅ plain String, not TimeOfDay
    String? endTime; // ✅ plain String, not TimeOfDay

    final email = context.read<AuthController>().currentUser?.email ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Schedule — ${day.day}/${day.month}/${day.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(startTime ?? 'Start Time'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              final formatted =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              setSheetState(() => startTime = formatted);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_filled),
                          label: Text(endTime ?? 'End Time'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              final formatted =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              setSheetState(() => endTime = formatted);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Error message
                  Consumer<ScheduleController>(
                    builder: (context, ctrl, _) {
                      if (ctrl.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            ctrl.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Save button
                  Consumer<ScheduleController>(
                    builder: (context, ctrl, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: ctrl.isLoading
                              ? null
                              : () async {
                                  if (titleController.text.trim().isEmpty ||
                                      startTime == null ||
                                      endTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in all fields',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final entry = ScheduleEntry(
                                    title: titleController.text.trim(),
                                    userEmail: email,
                                    date: day,
                                    startTime: startTime!,
                                    endTime: endTime!,
                                  );

                                  await ctrl.addEntry(entry);

                                  if (ctrl.errorMessage == null &&
                                      context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          child: ctrl.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Schedule',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      );
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();
    final dayEntries = _selectedDay != null
        ? controller.entriesForDay(_selectedDay!)
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(fontFamily: 'Poppins')),
      ),
      body: controller.isLoading && controller.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Calendar(
                  focusedDay: _focusedDay,
                  selectedStartDate: _selectedDay,
                  selectedEndDate: null,
                  onDaySelected: _onDayTapped,
                ),
                const Divider(),
                if (_selectedDay != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Schedule for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (dayEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No schedule for this day.\nTap a day to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: dayEntries.length,
                        itemBuilder: (context, index) {
                          final entry = dayEntries[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.event,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            title: Text(
                              entry.title,
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            subtitle: Text(
                              '${entry.startTime} - ${entry.endTime}',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                              onPressed: () => entry.id != null
                                  ? controller.deleteEntry(entry.id!)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
